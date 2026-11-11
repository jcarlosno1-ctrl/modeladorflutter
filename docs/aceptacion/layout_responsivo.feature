# language: es
# Contrato de aceptación del shell responsivo del modelador.
# Un escenario = un test en test/main_layout_test.dart.
Característica: Layout responsivo del modelador
  Como usuario del modelador visual
  Quiero que los paneles de herramientas y de propiedades se adapten al ancho disponible
  Para poder diseñar prototipos tanto en escritorio como en móvil

  Antecedentes:
    Dado que estoy en la pantalla del modelador

  Escenario: Escritorio muestra ambos paneles fijos
    Cuando el ancho de la ventana es de 1400 px
    Entonces veo el panel de herramientas a la izquierda
    Y veo el panel de propiedades a la derecha
    Y el lienzo central queda entre ambos paneles

  Esquema del escenario: Tablet mantiene herramientas fijas y propiedades colapsadas
    Cuando el ancho de la ventana es de <ancho> px
    Entonces veo el panel de herramientas a la izquierda
    Y el panel de propiedades no está visible
    Y toco la acción de propiedades
    Entonces se abre el panel de propiedades como EndDrawer

    Ejemplos:
      | ancho |
      | 600   |
      | 768   |
      | 1024  |

  Esquema del escenario: Móvil colapsa ambos paneles en cajones
    Cuando el ancho de la ventana es de <ancho> px
    Entonces no veo el panel de herramientas
    Y no veo el panel de propiedades
    Cuando abro el cajón izquierdo
    Entonces veo el panel de herramientas
    Cuando cierro el cajón izquierdo
    Y abro el cajón derecho
    Entonces veo el panel de propiedades

    Ejemplos:
      | ancho |
      | 320   |
      | 400   |
      | 599   |

  Escenario: Los umbrales no cambian al redimensionar
    Dado que la ventana mide 1024 px de ancho
    Entonces sigo en el modo tablet
    Cuando la ventana pasa a 1025 px de ancho
    Entonces paso al modo escritorio con ambos paneles fijos
