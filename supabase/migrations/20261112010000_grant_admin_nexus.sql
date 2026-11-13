-- =============================================================================
-- 2026-11-12 · Asignar rol admin a adminnexus@anssoluciones.com
-- -----------------------------------------------------------------------------
-- Idempotente: se puede ejecutar varias veces.
-- Si el usuario todavía no existe en auth.users, no falla: solo avisa.
--
-- Aplicar en Supabase → SQL Editor o `supabase db push`.
-- =============================================================================

do $$
declare
  target_id uuid;
begin
  select id
    into target_id
    from auth.users
   where lower(email) = lower('adminnexus@anssoluciones.com')
   limit 1;

  if target_id is null then
    raise notice
      'No existe adminnexus@anssoluciones.com. Registralo y volvé a ejecutar.';
    return;
  end if;

  insert into tenant_app.user_roles (user_id, role)
  values (target_id, 'admin')
  on conflict (user_id) do update set role = 'admin';

  raise notice 'Rol admin asignado a adminnexus@anssoluciones.com (%).',
    target_id;
end;
$$;

-- Verificación:
-- select u.email, r.role
--   from auth.users u
--   join tenant_app.user_roles r on r.user_id = u.id
--  where lower(u.email) = lower('adminnexus@anssoluciones.com');

-- Opcional: dejar un único administrador.
-- update tenant_app.user_roles r
--    set role = 'user'
--  where r.role = 'admin'
--    and r.user_id <> (
--      select id from auth.users
--       where lower(email) = lower('adminnexus@anssoluciones.com')
--       limit 1
--    );
