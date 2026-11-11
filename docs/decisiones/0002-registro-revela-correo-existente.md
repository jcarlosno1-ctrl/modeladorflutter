# ADR 0002 — El registro revela si un correo ya está registrado

- **Estado:** aceptada
- **Fecha:** 2026-11-07
- **Contexto:** autenticación con Supabase Auth, "Confirm email" activo.

## Contexto

Supabase, por defecto, responde *éxito señuelo* cuando se registra un correo
existente: devuelve un usuario con `identities: []` y **no envía** correo, para
no revelar qué direcciones están registradas (anti-enumeración).

La UI mostraba "Revisa tu correo", lo que confundía al usuario legítimo: no
recibía nada y no sabía por qué.

## Decisión

Detectar la respuesta señuelo (`identities` vacío) y mostrar:

> "Ese correo ya está registrado. Inicia sesión o recupera tu contraseña."

Es decir, se **opta por la claridad de UX** y se acepta el costo de seguridad.

## Consecuencias

- ❌ Un script puede enumerar correos registrados probando el formulario.
- ✅ El usuario que se equivoca de correo recibe una explicación accionable.
- ✅ No se crean cuentas duplicadas ni se envían correos engañosos.

## Mitigaciones obligatorias mientras siga vigente

1. **Rate limit de signups** en *Authentication → Rate Limits* (p. ej. 30/hora).
2. **CAPTCHA** (hCaptcha o Cloudflare Turnstile) en *Attack Protection* antes de
   publicar en producción.
3. Revisar *Auth → Logs* si aparecen picos de registros fallidos.
4. El flujo de recuperación de contraseña **sí** mantiene el mensaje neutral
   ("si el correo está registrado…") para no ampliar la superficie.

## Revisión

Si se detecta abuso (enumeración masiva), revertir a mensaje genérico: el
cambio es local a `SupabaseAuthRepository.signUp` y a la pantalla de registro.
