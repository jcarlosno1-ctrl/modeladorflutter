-- =============================================================================
-- 2026-11-06 · Esquema multi-tenant aislado del modelador visual
-- -----------------------------------------------------------------------------
-- Objetivo
--   Crear el esquema `tenant_app` con `profiles`, `projects` y `project_screens`,
--   todas con Row Level Security activada Y forzada.
--
-- Decisión de diseño
--   Los datos de usuario viven en `tenant_app`, nunca en `public` (regla del
--   proyecto). `public` queda reservado para lo que Supabase necesita y para
--   extensiones; así cualquier `select *` accidental desde el cliente no toca
--   datos de negocio.
--
-- OWASP Top 10 que cubre esta migración
--   A01 Broken Access Control  → RLS + políticas `auth.uid()` + FORCE RLS.
--   A03 Injection              → el cliente solo habla PostgREST (consultas
--                                parametrizadas) y `canvas` se valida como objeto.
--   A05 Security Misconfiguration → `anon` no recibe grants sobre el esquema;
--                                el esquema no se expone salvo que se configure.
--   A07 Identification/Auth    → las contraseñas las gestiona Supabase Auth
--                                (bcrypt), nunca esta aplicación.
--
-- Cómo aplicar
--   Supabase Cloud : Dashboard → SQL Editor → pegar y ejecutar (rol `postgres`).
--   Supabase CLI   : `supabase db push` (este archivo ya está en supabase/migrations).
--
-- Después de aplicar, en Project Settings → API → Exposed schemas:
--   agregar `tenant_app`. Sin eso, PostgREST devuelve 404/406 en cada tabla.
-- =============================================================================

create schema if not exists tenant_app;

comment on schema tenant_app is
  'Datos de usuario del modelador. Aislado por RLS; no exponer a anon.';

-- -----------------------------------------------------------------------------
-- 1. profiles — espejo 1:1 de auth.users
-- -----------------------------------------------------------------------------
create table tenant_app.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default ''
               check (char_length(display_name) <= 80),
  avatar_url   text
               check (avatar_url is null or char_length(avatar_url) <= 2048),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table tenant_app.profiles is
  'Perfil público del usuario. Se crea automáticamente al registrarse (trigger).';

-- -----------------------------------------------------------------------------
-- 2. projects — un proyecto por usuario, base del canvas
-- -----------------------------------------------------------------------------
create table tenant_app.projects (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references tenant_app.profiles (id) on delete cascade,
  name        text not null
              check (char_length(btrim(name)) between 1 and 120),
  description text
              check (description is null or char_length(description) <= 500),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table tenant_app.projects is 'Proyectos del modelador, aislados por owner_id.';

create index projects_owner_id_idx on tenant_app.projects (owner_id);

-- -----------------------------------------------------------------------------
-- 3. project_screens — pantallas/artboards dentro de un proyecto
-- -----------------------------------------------------------------------------
create table tenant_app.project_screens (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references tenant_app.projects (id) on delete cascade,
  name       text not null
             check (char_length(btrim(name)) between 1 and 80),
  position   integer not null default 0 check (position >= 0),
  -- `canvas` debe ser un objeto JSON y no superar 1 MiB: un array o un blob
  -- enorme rompería el editor y serviría como vector de agotamiento de memoria.
  canvas     jsonb not null default '{}'::jsonb
             check (
               jsonb_typeof(canvas) = 'object'
               and octet_length(canvas::text) <= 1048576
             ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- El orden debe ser único por proyecto, pero "deferrable" permite reordenar
  -- varias filas dentro de la misma transacción sin chocar con el índice.
  constraint project_screens_project_position_key
    unique (project_id, position) deferrable initially deferred
);

comment on table tenant_app.project_screens is
  'Pantallas de un proyecto. `canvas` guarda el árbol de componentes (JSON).';

create index project_screens_project_id_idx on tenant_app.project_screens (project_id);

-- -----------------------------------------------------------------------------
-- 4. updated_at automático (una sola función para las tres tablas)
-- -----------------------------------------------------------------------------
create function tenant_app.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

comment on function tenant_app.set_updated_at() is
  'Sobrescribe updated_at en cada UPDATE. Ignora lo que envíe el cliente.';

create trigger profiles_set_updated_at
  before update on tenant_app.profiles
  for each row execute function tenant_app.set_updated_at();

create trigger projects_set_updated_at
  before update on tenant_app.projects
  for each row execute function tenant_app.set_updated_at();

create trigger project_screens_set_updated_at
  before update on tenant_app.project_screens
  for each row execute function tenant_app.set_updated_at();

-- -----------------------------------------------------------------------------
-- 5. Alta automática del perfil al registrarse
--    SECURITY DEFINER + search_path vacío para que el trigger pueda insertar
--    pese a RLS, sin quedar expuesto a secuestro de search_path.
-- -----------------------------------------------------------------------------
create function tenant_app.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into tenant_app.profiles (id, display_name)
  values (
    new.id,
    -- `left(..., 80)`: un nombre larguísimo no debe hacer fallar el signup
    -- por violar el CHECK de 80 caracteres.
    left(
      coalesce(
        nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
        split_part(coalesce(new.email, 'usuario'), '@', 1)
      ),
      80
    )
  )
  on conflict (id) do nothing;  -- idempotente: un re-registro no rompe nada

  return new;
end;
$$;

comment on function tenant_app.handle_new_user() is
  'Crea el perfil en tenant_app.profiles cuando nace un usuario en auth.users.';

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function tenant_app.handle_new_user();

-- El trigger no debe poder invocarse como RPC desde el cliente.
revoke all on function tenant_app.handle_new_user() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 6. Row Level Security: política "solo lo mío", sin excepciones
-- -----------------------------------------------------------------------------
alter table tenant_app.profiles        enable row level security;
alter table tenant_app.projects        enable row level security;
alter table tenant_app.project_screens enable row level security;

-- FORCE: aplica RLS incluso al dueño de la tabla. `postgres` sigue pudiendo
-- administrar porque es superusuario, pero un rol owner no bypassea por error.
alter table tenant_app.profiles        force row level security;
alter table tenant_app.projects        force row level security;
alter table tenant_app.project_screens force row level security;

-- profiles: solo el propio. No hay INSERT (lo hace el trigger) ni DELETE
-- (lo arrastra el ON DELETE CASCADE de auth.users).
create policy profiles_select_own on tenant_app.profiles
  for select to authenticated
  using (id = (select auth.uid()));

create policy profiles_update_own on tenant_app.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));  -- impide "mudar" el perfil a otro id

-- projects: dueño = usuario autenticado. El WITH CHECK del UPDATE impide
-- transferir el proyecto cambiando owner_id.
create policy projects_select_own on tenant_app.projects
  for select to authenticated
  using (owner_id = (select auth.uid()));

create policy projects_insert_own on tenant_app.projects
  for insert to authenticated
  with check (owner_id = (select auth.uid()));

create policy projects_update_own on tenant_app.projects
  for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy projects_delete_own on tenant_app.projects
  for delete to authenticated
  using (owner_id = (select auth.uid()));

-- project_screens: se permite si (y solo si) el proyecto padre es del usuario.
create policy project_screens_select_own on tenant_app.project_screens
  for select to authenticated
  using (
    exists (
      select 1
      from tenant_app.projects p
      where p.id = project_screens.project_id
        and p.owner_id = (select auth.uid())
    )
  );

create policy project_screens_insert_own on tenant_app.project_screens
  for insert to authenticated
  with check (
    exists (
      select 1
      from tenant_app.projects p
      where p.id = project_screens.project_id
        and p.owner_id = (select auth.uid())
    )
  );

create policy project_screens_update_own on tenant_app.project_screens
  for update to authenticated
  using (
    exists (
      select 1
      from tenant_app.projects p
      where p.id = project_screens.project_id
        and p.owner_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from tenant_app.projects p
      where p.id = project_screens.project_id
        and p.owner_id = (select auth.uid())
    )
  );

create policy project_screens_delete_own on tenant_app.project_screens
  for delete to authenticated
  using (
    exists (
      select 1
      from tenant_app.projects p
      where p.id = project_screens.project_id
        and p.owner_id = (select auth.uid())
    )
  );

-- -----------------------------------------------------------------------------
-- 7. Privilegios: lo mínimo para que PostgREST funcione, nada para anon
-- -----------------------------------------------------------------------------
revoke all on schema tenant_app from public, anon;

grant usage on schema tenant_app to authenticated;
grant select, insert, update, delete on all tables in schema tenant_app to authenticated;

-- Las tablas que se creen a futuro en este esquema heredan el mismo criterio.
alter default privileges in schema tenant_app revoke all on tables from public, anon;
alter default privileges in schema tenant_app
  grant select, insert, update, delete on tables to authenticated;
