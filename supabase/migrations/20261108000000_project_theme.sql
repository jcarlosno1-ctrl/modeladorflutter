-- Tema visual por proyecto: colores y tipografías elegidos una sola vez.
alter table tenant_app.projects
  add column if not exists theme jsonb not null default '{}'::jsonb;

comment on column tenant_app.projects.theme is
  'Tema visual del proyecto (colores primary/secondary/tertiary, tipografías y AppBar).';
