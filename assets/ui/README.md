# Interfaz de Mictlan

Recursos y estilos del rediseño de interfaz, **aparcado por ahora**. El menú y la pausa
activos conservan su diseño original; solo el HUD del nivel reutiliza
`fuentes/PixelifySans.ttf` para el contador de jades.

## Fuentes

| Archivo | Uso | Licencia |
| --- | --- | --- |
| `fuentes/PixelifySans.ttf` | Texto general, etiquetas, botones y HUD | OFL, ver `OFL-PixelifySans.txt` |
| `fuentes/PressStart2P.ttf` | Títulos (`MICTLAN`, `PAUSA`) | OFL, ver `OFL-PressStart2P.txt` |

Las dos fuentes se importan con **antialiasing desactivado**, **hinting desactivado** y
**subpíxeles desactivados** para conservar el aspecto pixel art. Esas opciones están
guardadas en los archivos `.import`; si se reimportan las fuentes, hay que mantenerlas.

## Tema

`tema_mictlan.tres` centraliza los estilos de la interfaz:

- Fuente y tamaño por defecto.
- Botones verdes (`Button`) y rojos (`BotonRojo`) con estados normal, hover, pressed,
  focus y disabled.
- Panel morado con borde dorado (`PanelContainer`).
- Panel translúcido para los controles (`PanelControles`).
- Teclas de atajo (`Tecla`) para el panel de controles.
- Separador dorado (`HSeparator`).

Paleta:

| Uso | Color |
| --- | --- |
| Fondo morado | `#241238` |
| Panel morado | `#2e1848` |
| Borde morado | `#6b3d8c` |
| Dorado | `#f7c948` |
| Crema | `#f5e6c8` |
| Verde | `#0f6b5c` |
| Rojo | `#962a2e` |

Para aplicar el tema a una escena nueva, asigna `tema_mictlan.tres` al nodo raíz de tipo
`Control`; los hijos heredan el tema. En una escena con raíz `CanvasLayer`, asígnalo al
`Panel` o al `Control` que corresponda.

## Iconos

`iconos/play_32.png`, `iconos/puerta_32.png` y `iconos/calavera_32.png` son ampliaciones
2× con vecino más cercano de los iconos blancos de
`assets/materiales/interfaz/iconos/white/` (CC0, pixel-boy). Se dejaron en blanco para
tintarlos con `modulate` o con los colores de icono del tema.

## Escenas

Las escenas activas `escenas/menu.tscn` y `escenas/pausa.tscn` conservan su diseño
original y no usan el tema. El único elemento activo que reutiliza estos recursos es el
HUD del nivel, que toma `fuentes/PixelifySans.ttf` para el contador de jades.

La interfaz está pensada para el viewport de 1152×648 y usa anclas para adaptarse a
otras resoluciones 16:9.
