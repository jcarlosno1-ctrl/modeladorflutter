# Comparativa de propiedades: básicos

Comparación entre nuestro catálogo (`lib/features/editor/catalog/standard_catalog.dart`)
y el de `C:\Dev\witgetflutter\flutter_estudio` (`lib/models/widget_catalog.dart`).

Método: se volcaron todas las fichas de ambos catálogos (tipo, etiqueta, categoría,
clave, etiqueta, editor, default, grupo, rango, nº de opciones).

## Panorama

| Métrica | Nosotros | Flutter Studio |
|---|---|---|
| Widgets | 62 | 73 |
| Propiedades declaradas | 180 | 704 |
| Promedio por widget | 2,9 | 9,6 |

El 704 incluye **propiedades generadas** que la referencia inyecta a muchos widgets:

- grupo **Icono: 144 props** (sombra/desplazamiento/relleno del icono, repetidas en
  cada widget con icono),
- grupo **Acciones: 44 props** (`onAction`, `onActionMessage` en todo widget
  interactivo).

Sin esa repetición quedan ~516 propiedades “reales”: seguimos estando ~2,9× por
debajo, pero la diferencia útil es menor de lo que sugiere el total.

## Modelo: diferencias de fondo

| Tema | Nosotros | Referencia | Lectura |
|---|---|---|---|
| Color | token del tema + hex | entero ARGB | Nuestro enfoque es mejor: respeta el tema y el modo claro/oscuro. **No copiar ARGB.** |
| Eventos | por widget (`onTap`, `onFocus`…), solo algunos | inyectados a todos los interactivos (`onAction`) | Conviene centralizar: un bloque Eventos común. |
| Icono decorado | no | 7 props de sombra por widget | Ruido y coste de render; **no copiar en bloque**. |
| Requisito de padre | no | `parentRequirement` (Expanded dentro de Fila/Columna) | Mejora de arquitectura, no de propiedades; evaluar aparte. |
| Accesibilidad | casi nula | `semanticLabel` en textos/iconos | Adoptar de forma selectiva. |
| Grupos/hints | sí, más compactos | sí, más exhaustivos | Mantener nuestros grupos y tomar hints útiles. |

## Básicos, widget por widget

| Widget | Props nuestras | Props ref. | Faltantes clave en las nuestras | Veredicto |
|---|---|---|---|---|
| Texto | 5 | 16 | `fontWeight`, `letterSpacing`, `wordSpacing`, `lineHeight`, `fontStyle`, `decoration`, `maxLines`, `overflow`, `softWrap`, `fontFamily`, `textDirection`, `semanticLabel` | **Enriquecer** (la mayor brecha de los básicos) |
| Imagen | 1 | 13 | `url`, `width`, `fit`, `borderRadius`, `alignment`, `opacity`, `tintColor`, `filterQuality` | **Enriquecer** (hoy es un placeholder) |
| Separador | 1 | 5 | `height`, `color`, `indent`, `endIndent` | **Adoptar** (barato) |
| Icono | 5 | 14 | `shadow*`, `fill`, `semanticLabel` | **Parcial**: solo `semanticLabel`; sombras no |
| Avatar | 5 | 9 | `alignment`, `imageUrl`, `borderWidth`, `borderColor` | **Adoptar** borde y URL de imagen |
| Tooltip | 1 | 8 | `waitDuration`, `showDuration`, `preferBelow`, `verticalOffset`, `padding` | **Adoptar** duraciones y posición |
| Texto seleccionable | 3 | 8 | `fontWeight`, `color`, `maxLines`, `cursorColor`, `showCursor` | **Adoptar** peso, color y maxLines |
| Progreso | 2 | 8 | `linear`, `indeterminate`, `color`, `backgroundColor`, `strokeWidth`, `borderRadius` | **Enriquecer** (hoy solo value/estilo) |
| Chip | 7 | 22 | `iconColor`, `iconSize`, `sideWidth`, `sideColor`, `shadowColor`, sombras | **Parcial**: borde y color/tamaño de icono |
| Fila de lista | 4 | 27 | `leadingIconColor`, `trailingIcon`, `selected`, `dense`, `tileColor`, `contentPadding`, `shapeRadius`, `enabled` | **Enriquecer** (es de los más usados) |
| Tarjeta | 1 | 12 | `color`, `shadowColor`, `borderRadius`, `margin`, `padding`, `borderWidth`, `borderColor`, `clipBehavior` | **Adoptar** radio, margen, borde, color |
| Botón | 5 | 28 (×4 variantes) | `backgroundColor`, `foregroundColor`, `borderRadius`, `padding`, `elevation`, `fontSize`, `icon`, `fullWidth` | **Enriquecer** el botón único (no crear 4 widgets) |
| Campo de texto | 6 | 35 | `helperText`, `errorText`, `keyboardType`, `maxLines`, `prefixIcon`, `suffixIcon`, `filled`, `fillColor`, `borderRadius`, `readOnly`, `textAlign`, `textCapitalization` | **Enriquecer** fuerte (formularios) |
| Botón de icono | 6 | 26 | `backgroundColor`, `borderRadius`, `selected`, `padding`, `disabledColor`, `alignment` | **Parcial**: fondo, radio, selected |
| FAB | 1 | 24 | `extendedLabel`, `mini`, `shape`, `elevation`, `alignment`, `tooltip`, colores | **Enriquecer** (es de los más visibles) |

## Qué adoptar y qué no

### Sí adoptar (mejora clara)

1. **Texto tipográfico completo**: peso, interlineado, espaciado, maxLines,
   overflow, cursiva/subrayado, familia y accesibilidad.
2. **Imagen real**: URL con `Image.network`, `fit`, radio, opacidad y fallback.
3. **Tarjeta y separador**: radio, borde, margen, color; altura e indentación.
4. **Botón y FAB**: colores, radio, padding, elevación, icono, ancho completo,
   FAB extendido y mini.
5. **Campo de texto de formulario**: helper/error, teclado, maxLines, prefijos,
   relleno, borde, solo lectura.
6. **Fila de lista**: icono leading con color, trailing, seleccionada, densa,
   radio de forma, color de fondo.
7. **Tooltip** con duraciones y posición; **progreso** con colores/grosor/indeterminado.

### Parcial (sí, pero acotado)

- **Eventos**: mejor un mecanismo **central** (un bloque “Eventos” que se añade a
  todo widget interactivo) que copiar `onAction` en cada ficha.
- **Icono**: `semanticLabel` y poco más; las 7 props de sombra por widget no
  aportan al modelador y complican el panel.
- **Chip / botón de icono**: borde, color de icono, fondo y `selected`; el resto
  de sombras no.

### No copiar

- Colores ARGB crudos (rompen el tema y el selector actual).
- Sombras de icono repetidas en todos los widgets.
- Duplicar botones en 4 widgets: nuestra propiedad **Estilo** ya cubre
  Filled/Outlined/Text; sumar `elevated` no aporta y ensucia la paleta.
- `fontFamily` con una lista fija sin fuentes cargadas: mejor dejarlo para cuando
  exista gestión de fuentes.

## Plan propuesto (P1, básicos)

1. **Texto**: `fontWeight`, `maxLines`, `overflow`, `lineHeight`, `letterSpacing`,
   `fontStyle`, `decoration`, `semanticLabel`.
2. **Imagen**: `url`, `width`, `fit`, `borderRadius`, `opacity`.
3. **Separador**: `height`, `color`, `indent`, `endIndent`.
4. **Tarjeta**: `color`, `borderRadius`, `margin`, `padding`, `borderWidth`.
5. **Botón**: `backgroundColor`, `foregroundColor`, `borderRadius`, `padding`,
   `fontSize`, `icon`, `fullWidth`.
6. **Campo de texto**: `helperText`, `keyboardType`, `maxLines`, `prefixIcon`,
   `suffixIcon`, `filled`, `fillColor`, `borderRadius`, `readOnly`.
7. **Fila de lista**: `leadingIconColor`, `trailingIcon`, `selected`, `dense`,
   `shapeRadius`, `tileColor`.

Cada punto incluye preview, codegen y tests. P2: tooltip, progreso, avatar,
texto seleccionable, FAB extendido, accesibilidad y eventos centralizados.
