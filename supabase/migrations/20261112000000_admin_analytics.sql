-- =============================================================================
-- 2026-11-12 · Roles, planes, uso y estadísticas para administración
-- -----------------------------------------------------------------------------
-- Objetivo
--   - Roles separados del perfil (user/admin) que el cliente no puede editar.
--   - Planes con límite de proyectos por usuario.
--   - Sesiones de uso (heartbeat) para calcular horas.
--   - Funciones de agregación: el admin ve números, nunca datos personales.
--
-- Seguridad
--   * RLS forzado en todas las tablas nuevas.
--   * El rol admin NO recibe SELECT sobre profiles/projects/usage_sessions.
--   * Solo puede ejecutar funciones SECURITY DEFINER que devuelven agregados.
--   * El límite de proyectos se aplica con un trigger, no en el cliente.
--
-- Asignar un administrador (ejecutar como postgres, una sola vez):
--   insert into tenant_app.user_roles (user_id, role)
--   values ('<uuid-del-usuario>', 'admin')
--   on conflict (user_id) do update set role = 'admin';
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Roles (tabla aislada: sin políticas para clientes)
-- -----------------------------------------------------------------------------
do $$
begin
  create type tenant_app.user_role as enum ('user', 'admin');
exception
  when duplicate_object then null;
end;
$$;

create table if not exists tenant_app.user_roles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role tenant_app.user_role not null default 'user',
  created_at timestamptz not null default now()
);

alter table tenant_app.user_roles enable row level security;
alter table tenant_app.user_roles force row level security;
revoke all on tenant_app.user_roles from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 2. Planes y límite por usuario
-- -----------------------------------------------------------------------------
create table if not exists tenant_app.plans (
  id text primary key,
  name text not null,
  max_projects integer not null check (max_projects > 0)
);

insert into tenant_app.plans (id, name, max_projects)
values
  ('free', 'Gratis', 5),
  ('pro', 'Pro', 20),
  ('business', 'Business', 100)
on conflict (id) do nothing;

alter table tenant_app.plans enable row level security;
alter table tenant_app.plans force row level security;

drop policy if exists plans_select_all on tenant_app.plans;
create policy plans_select_all on tenant_app.plans
  for select to authenticated using (true);

revoke all on tenant_app.plans from public, anon, authenticated;
grant select on tenant_app.plans to authenticated;

alter table tenant_app.profiles
  add column if not exists plan_id text not null default 'free'
  references tenant_app.plans (id);

-- El cliente autenticado no puede cambiarse el plan.
create or replace function tenant_app.protect_plan_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.plan_id is distinct from old.plan_id
     and auth.uid() is not null
     and coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'El plan solo lo puede cambiar un administrador.';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_plan on tenant_app.profiles;
create trigger profiles_protect_plan
  before update on tenant_app.profiles
  for each row execute function tenant_app.protect_plan_change();

revoke all on function tenant_app.protect_plan_change() from public, anon, authenticated;

-- Límite real de proyectos por usuario (trigger BEFORE INSERT).
create or replace function tenant_app.enforce_project_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  limite integer;
  actual integer;
begin
  if auth.uid() is null or coalesce(auth.role(), '') = 'service_role' then
    return new;
  end if;

  select pl.max_projects into limite
  from tenant_app.profiles pr
  join tenant_app.plans pl on pl.id = pr.plan_id
  where pr.id = auth.uid();

  select count(*) into actual
  from tenant_app.projects
  where owner_id = auth.uid();

  if actual >= coalesce(limite, 5) then
    raise exception 'Límite de proyectos alcanzado para tu plan.'
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

drop trigger if exists projects_limit on tenant_app.projects;
create trigger projects_limit
  before insert on tenant_app.projects
  for each row execute function tenant_app.enforce_project_limit();

revoke all on function tenant_app.enforce_project_limit() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 3. Sesiones de uso (heartbeat)
-- -----------------------------------------------------------------------------
create table if not exists tenant_app.usage_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  started_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  platform text check (platform is null or char_length(platform) <= 40)
);

create index if not exists usage_sessions_user_seen_idx
  on tenant_app.usage_sessions (user_id, last_seen_at desc);

alter table tenant_app.usage_sessions enable row level security;
alter table tenant_app.usage_sessions force row level security;

drop policy if exists usage_select_own on tenant_app.usage_sessions;
create policy usage_select_own on tenant_app.usage_sessions
  for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists usage_insert_own on tenant_app.usage_sessions;
create policy usage_insert_own on tenant_app.usage_sessions
  for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists usage_update_own on tenant_app.usage_sessions;
create policy usage_update_own on tenant_app.usage_sessions
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on tenant_app.usage_sessions from public, anon, authenticated;
grant select, insert, update on tenant_app.usage_sessions to authenticated;

-- -----------------------------------------------------------------------------
-- 4. Auditoría de accesos al panel
-- -----------------------------------------------------------------------------
create table if not exists tenant_app.admin_audit_log (
  id bigint generated always as identity primary key,
  admin_id uuid references auth.users (id) on delete set null,
  action text not null,
  params jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table tenant_app.admin_audit_log enable row level security;
alter table tenant_app.admin_audit_log force row level security;
revoke all on tenant_app.admin_audit_log from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 5. ¿El usuario actual es admin?
-- -----------------------------------------------------------------------------
create or replace function tenant_app.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from tenant_app.user_roles
    where user_id = auth.uid() and role = 'admin'
  );
$$;

revoke all on function tenant_app.is_admin() from public, anon;
grant execute on function tenant_app.is_admin() to authenticated;

-- -----------------------------------------------------------------------------
-- 6. Estadísticas agregadas (sin datos personales)
-- -----------------------------------------------------------------------------
create or replace function tenant_app.admin_stats(
  from_date timestamptz default now() - interval '30 days',
  to_date timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if not tenant_app.is_admin() then
    raise exception 'No autorizado.';
  end if;

  select jsonb_build_object(
    'total_users', (select count(*) from auth.users),
    'new_users', (
      select count(*) from auth.users
      where created_at between from_date and to_date
    ),
    'total_projects', (select count(*) from tenant_app.projects),
    'avg_projects_per_user', (
      select coalesce(
        round(count(*)::numeric / nullif(count(distinct owner_id), 0), 2),
        0
      )
      from tenant_app.projects
    ),
    'usage_hours', (
      select coalesce(
        round(sum(extract(epoch from (last_seen_at - started_at))) / 3600, 1),
        0
      )
      from tenant_app.usage_sessions
      where last_seen_at between from_date and to_date
    ),
    'active_users', (
      select count(distinct user_id)
      from tenant_app.usage_sessions
      where last_seen_at between from_date and to_date
    ),
    'total_sessions', (
      select count(*)
      from tenant_app.usage_sessions
      where started_at between from_date and to_date
    )
  ) into result;

  insert into tenant_app.admin_audit_log (admin_id, action, params)
  values (
    auth.uid(),
    'admin_stats',
    jsonb_build_object('from', from_date, 'to', to_date)
  );

  return result;
end;
$$;

revoke all on function tenant_app.admin_stats(timestamptz, timestamptz)
  from public, anon;
grant execute on function tenant_app.admin_stats(timestamptz, timestamptz)
  to authenticated;

-- Distribución por plan: usuarios, proyectos y horas, sin identidades.
create or replace function tenant_app.admin_usage_by_plan(
  from_date timestamptz default now() - interval '30 days',
  to_date timestamptz default now()
)
returns table (
  plan_id text,
  plan_name text,
  users bigint,
  projects bigint,
  usage_hours numeric
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not tenant_app.is_admin() then
    raise exception 'No autorizado.';
  end if;

  return query
  select
    pl.id,
    pl.name,
    count(distinct pr.id),
    (
      select count(*)
      from tenant_app.projects p
      join tenant_app.profiles pr2 on pr2.id = p.owner_id
      where pr2.plan_id = pl.id
    ),
    coalesce((
      select round(
        sum(extract(epoch from (us.last_seen_at - us.started_at))) / 3600,
        1
      )
      from tenant_app.usage_sessions us
      join tenant_app.profiles pr3 on pr3.id = us.user_id
      where pr3.plan_id = pl.id
        and us.last_seen_at between from_date and to_date
    ), 0)
  from tenant_app.plans pl
  left join tenant_app.profiles pr on pr.plan_id = pl.id
  group by pl.id, pl.name
  order by pl.id;
end;
$$;

revoke all on function tenant_app.admin_usage_by_plan(timestamptz, timestamptz)
  from public, anon;
grant execute on function tenant_app.admin_usage_by_plan(timestamptz, timestamptz)
  to authenticated;

-- Límites del usuario actual (para mostrar "3 de 5 proyectos").
create or replace function tenant_app.my_limits()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'plan_id', pr.plan_id,
    'max_projects', pl.max_projects,
    'used_projects', (
      select count(*) from tenant_app.projects p where p.owner_id = auth.uid()
    )
  )
  from tenant_app.profiles pr
  join tenant_app.plans pl on pl.id = pr.plan_id
  where pr.id = auth.uid();
$$;

revoke all on function tenant_app.my_limits() from public, anon;
grant execute on function tenant_app.my_limits() to authenticated;

-- -----------------------------------------------------------------------------
-- 7. Privilegios por defecto del esquema: nada sensible para clientes
-- -----------------------------------------------------------------------------
revoke all on tenant_app.user_roles, tenant_app.admin_audit_log
  from public, anon, authenticated;
revoke all on tenant_app.usage_sessions from public, anon, authenticated;
grant select, insert, update on tenant_app.usage_sessions to authenticated;
