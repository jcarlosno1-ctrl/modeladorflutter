# ADR 0003 — Catálogo cerrado de widgets Flutter

- **Estado:** aceptada
- **Fecha:** 2026-11-07
- **Contexto:** diseño del lienzo del modelador.

## Contexto

El lienzo guarda un árbol JSON en `tenant_app.project_screens.canvas`. Ese JSON
lo puede escribir cualquier cliente autenticado, así que **no es confiable**.
Se evaluó un motor libre (CustomPainter o un paquete de diagramación) frente a
un catálogo cerrado de widgets Flutter reales.

## Decisión

Catálogo cerrado de componentes definidos **en Dart**, con:

- Propiedades tipadas (`PropertySpec`) y valor por defecto validado.
- Un `builder` por componente que construye un **widget Flutter real**.
- Renderizador que solo dibuja tipos presentes en el catálogo, coacciona
  propiedades y acota profundidad (40) y hijos por contenedor (50).

El formato persistido es `{version: 1, root: {...}}` y el usuario **nunca**
escribe código: solo elige componentes y valores permitidos.

## Consecuencias

- ✅ Imposible inyectar widgets, callbacks o propiedades arbitrarias desde el JSON.
- ✅ El preview es el mismo widget que correría en producción.
- ✅ Validación previa (`validateCanvas`) permite mostrar incidencias en el editor.
- ⚠️ Flutter tiene 200+ widgets: el catálogo crece por definiciones explícitas
  (semilla actual: 12). Agregar uno = definición + builder + test.
- ⚠️ Componentes con estado propio (Video, Map, Slider) requieren decidir qué
  propiedades exponer antes de agregarlos.

## Extensión

1. Agregar `WidgetDefinition` en `standard_catalog.dart`.
2. Declarar propiedades con `PropertySpec` (texto, número, booleano, opción).
3. Definir el builder usando solo `Props` y `Theme.of(context).colorScheme`.
4. Agregar el default al test de catálogo (se valida solo).
