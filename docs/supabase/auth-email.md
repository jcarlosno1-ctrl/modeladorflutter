# Correo de autenticación con SMTP propio (`noreply@anssoluciones.com`)

Supabase **no** usa tu buzón por defecto. Para enviar confirmaciones y resets a
usuarios reales hay que configurar SMTP propio; el servicio integrado está
pensado solo para pruebas (≈2 correos/hora y únicamente direcciones del equipo).

## Estado del dominio (verificado por DNS)

| Registro | Valor actual | Estado |
|---|---|---|
| MX | `mx1/mx2.hostinger.com` | ✅ Hostinger |
| SPF | `v=spf1 include:_spf.mail.hostinger.com ~all` | ✅ correcto |
| DMARC | `v=DMARC1; p=none` | ⚠️ sin `rua` (sin reportes) |
| DKIM | sin registro en selectores `default`, `dkim`, `mail`, `hostingermail*` | ❌ **falta** |

Sin DKIM, Gmail y Outlook pueden marcar como spam aunque SPF pase.

## 1. Configurar SMTP en Supabase

*Project Settings → Authentication → SMTP Settings* → **Enable custom SMTP**:

| Campo | Valor |
|---|---|
| Host | `smtp.hostinger.com` |
| Port | `465` (SSL) — alternativa `587` (STARTTLS) |
| Username | `noreply@anssoluciones.com` |
| Password | la del buzón (solo aquí; nunca en `.env` ni en git) |
| Sender email | `noreply@anssoluciones.com` |
| Sender name | `Modelador` |

> Si el buzón tiene 2FA o "contraseña de aplicación", usar esa.

## 2. DNS en Hostinger (hPanel)

1. **Activar DKIM** para el dominio (Emails → DNS → DKIM) y publicar el registro
   TXT que genere. Verificar con `nslookup -type=TXT <selector>._domainkey.anssoluciones.com`.
2. **DMARC**: cuando DKIM y SPF alineen, pasar a
   `v=DMARC1; p=quarantine; rua=mailto:dmarc@anssoluciones.com; adkim=s; aspf=s`.
3. No tocar el SPF salvo que se agregue otro proveedor de envío.

## 3. URLs de retorno

- *Authentication → URL Configuration* → **Site URL**: `https://app.tudominio.com`
  (en desarrollo `http://localhost:3000`).
- **Redirect URLs**: agregar `http://localhost:3000` y la de producción.
- La app envía `AUTH_REDIRECT_URL` como `emailRedirectTo` (registro) y
  `redirectTo` (reset), ver [supabase_auth_repository.dart](../../lib/features/auth/data/supabase_auth_repository.dart).

## 3.1 Plantillas con `token_hash` (recomendado)

El enlace por defecto (`{{ .ConfirmationURL }}`) se **consume con solo abrirlo**:
si un antivirus o el proveedor de correo lo escanea antes que el usuario, el
token queda usado y la app recibe `otp_expired`.

Solución: en *Authentication → Email Templates* usar el hash y dejar que la app
lo verifique:

**Confirm signup**
```html
<a href="{{ .SiteURL }}?token_hash={{ .TokenHash }}&type=signup">Confirmar correo</a>
```

**Reset password**
```html
<a href="{{ .SiteURL }}?token_hash={{ .TokenHash }}&type=recovery">Restablecer contraseña</a>
```

La app lee esos parámetros al arrancar con
[`AuthLinkHandler`](../../lib/features/auth/data/auth_link_handler.dart), llama
`verifyOtp` y solo ahí se consume el token.

- En desarrollo hay que correr con puerto fijo: `flutter run -d chrome --web-port=3000`.

## 4. Límites

*Authentication → Rate Limits*: ajustar correos por hora (p. ej. 30), intentos de
login y registros. Hostinger también tiene cuota diaria de envío por buzón.

## 5. Prueba

1. Registrarse con un correo real desde la app.
2. Revisar la bandeja y los encabezados: `SPF: pass`, `DKIM: pass`.
3. Probar "¿Olvidaste tu contraseña?" y abrir el enlace.

## Seguridad

- La contraseña SMTP vive **solo** en el dashboard de Supabase (cifrada en
  reposo). No va en `.env`, ni en el cliente, ni en git.
- Buzón dedicado `noreply@`: monitorear rebotes; no responder desde él.
- Rotar la contraseña si se sospecha filtración.
- Si más adelante se envían correos transaccionales de producto (no auth),
  evaluar un proveedor con API (Resend/SendGrid) en vez de SMTP de hosting.
