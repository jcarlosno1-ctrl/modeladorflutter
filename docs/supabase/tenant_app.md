# Esquema `tenant_app` (Supabase)

Datos de usuario del modelador: `profiles`, `projects`, `project_screens`.
Todo con RLS activada y **forzada**. `anon` no tiene permisos; el cliente
autenticado solo ve sus filas.

## Aplicar la migración

**Opción A — Dashboard (la más rápida hoy)**
1. Supabase → *SQL Editor* → *New query*.
2. Pegar el contenido de [`supabase/migrations/20261106000000_init_tenant_app.sql`](../../supabase/migrations/20261106000000_init_tenant_app.sql) y ejecutar.
3. *Project Settings → API → Exposed schemas* → agregar `tenant_app`.

**Opción B — CLI (v3)**
```bash
supabase login                          # abre el navegador; token fuera del repo
supabase link --project-ref <ref>       # guarda el ref en supabase/.temp (ignorado)
supabase db push --remote --dry-run     # revisa qué migraciones aplicaría
supabase db push --remote               # pide la password de la BD
```

En la v3 `db push` apunta al stack **local** por defecto: sin `--remote` no toca
la nube. La password se escribe en tu terminal (o `SUPABASE_DB_PASSWORD`), nunca
en un archivo del proyecto.

> No uses `supabase config push` para exponer el esquema: subiría también
> `site_url = http://127.0.0.1:3000`, puertos y ajustes locales del `config.toml`.
> Para `tenant_app` basta el toggle del Dashboard (paso 3).

### CLI en esta máquina

- Instalada **v3.0.0** (binario oficial) en
  `%LOCALAPPDATA%\Programs\supabase\supabase.exe`.
- Ya está en el `PATH` de usuario: abre una terminal nueva para que `supabase` resuelva.
- `supabase/config.toml` generado por `supabase init`, con `tenant_app` en
  `[api] schemas` (así la API local lo expone igual que la nube).
- **Pendiente:** `supabase start` / `db reset` (stack local) requieren Docker
  Desktop o Podman, que no están instalados. Sin Docker, la CLI sirve para
  `init`, `login`, `link`, `db push`, `migration new` y `gen types`.
- **Pendiente:** `login` y `link` necesitan un proyecto Supabase creado.

Sin el paso 3 del Dashboard, PostgREST no conoce el esquema y las consultas fallan con
`PGRST106 / schema must be one of the exposed schemas`.

## Modelo

| Tabla | Clave | Aislamiento |
|---|---|---|
| `profiles` | `id → auth.users.id` | `id = auth.uid()` |
| `projects` | `id`, `owner_id` | `owner_id = auth.uid()` |
| `project_screens` | `id`, `project_id` | existe el proyecto padre propio |

- `profiles` se crea sola con el trigger `on_auth_user_created`; el cliente no
  necesita (ni puede) insertarla.
- `project_screens.position` es único por proyecto y `deferrable`, para poder
  reordenar dentro de una transacción.
- `project_screens.canvas` es JSONB, objeto y ≤ 1 MiB.

## Seguridad aplicada

| Riesgo (OWASP) | Mitigación en este esquema |
|---|---|
| A01 Broken Access Control | RLS + `FORCE RLS`; políticas por `auth.uid()`; `WITH CHECK` impide cambiar `owner_id` |
| A03 Injection | Todo acceso vía PostgREST parametrizado; `canvas` validado como objeto con tope de tamaño |
| A05 Security Misconfiguration | `anon` sin grants; esquema fuera de la API salvo exposición explícita |
| A07 Auth failures | Contraseñas y sesiones en Supabase Auth; el cliente solo lleva `anon key` |

### Riesgos que quedan abiertos (y cómo cerrarlos)

1. **`service_role` jamás en el cliente.** Si se usa en un job del servidor,
   recordar que *bypassea RLS*: cualquier fuga equivale a acceso total.
2. **Sesión en web.** `flutter_secure_storage` no existe tal cual en web; usar
   la persistencia propia de `supabase_flutter` (localStorage) y aceptar que
   XSS la expone → mantener CSP estricta en el hosting.
3. **Rate limiting / fuerza bruta.** Configurar en Supabase Auth (límite de
   intentos) y captcha si se publica el registro.

## Cliente

Al instalar `supabase_flutter`, el cliente debe apuntar al esquema
`tenant_app` (opción de esquema del cliente PostgREST). Se verificará con la
versión concreta que instalemos; no se asume API antes de tener el paquete.
