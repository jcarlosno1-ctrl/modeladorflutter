# Reglas del Proyecto – Modelador Low-Code

## Rol de la IA
Actúa como COPILOTO. Cambios mínimos y atómicos. Explica archivo → cambio → motivo.
No propongas refactors fuera del ticket. No reescribas archivos completos si solo cambia una función.

## Stack
- Flutter (Web + Android/iOS), Material 3, Riverpod, GoRouter, Supabase.
- Serialización: freezed + json_serializable.
- Tests: flutter_test, mocktail, integration_test.

## Convenciones
- Archivos: `snake_case.dart`. Clases: `PascalCase`. Variables/métodos: `camelCase`.
- Widgets con `const` cuando sea posible.
- Prohibido `setState` en widgets grandes. Estado vía Riverpod.
- Prohibida lógica de negocio en widgets. Va en `domain/` o `application/`.
- Nada de colores hardcodeados. Usar `Theme.of(context).colorScheme`.

## Arquitectura
- Clean Architecture por feature: `data/`, `domain/`, `presentation/`.
- Toda dependencia externa (Supabase, HTTP, storage) accedida vía interfaz en `domain/`.
- Errores vía `Result<T, Failure>` (patrón Either, sin excepciones en dominio).

## Seguridad (OWASP)
- RLS obligatorio en toda tabla nueva en Supabase.
- `.env` en `.gitignore`. Nunca commitear `service_role`.
- Cliente solo usa `anon key`.
- Inputs del usuario: validar y sanitizar antes de persistir.
- Datos dinámicos de usuarios → schema dedicado `tenant_app`, nunca `public`.

## Tests (TDD)
Antes de código funcional:
1. Criterios de aceptación en Gherkin.
2. Test unit/widget que falle (RED).
3. Implementación mínima (GREEN).
4. Refactor.
Cobertura mínima en `domain/` y `application/`: 80%.

## Responsividad
- Breakpoints: móvil `<600`, tablet `600–1024`, desktop `>1024`.
- Web: paneles laterales fijos (Herramientas izq., Propiedades der.).
- Móvil: `Drawer` (izq.), `EndDrawer`/`BottomSheet` (der.).