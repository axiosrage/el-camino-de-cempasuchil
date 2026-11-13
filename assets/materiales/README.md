# Materiales de terceros

Recursos externos listos para usar en Mictlan. Se conservó el arte original; solo se
reorganizaron las carpetas y se eliminaron archivos temporales de macOS.

## Contenido

| Carpeta | Pack | Autor | Licencia / crédito |
| --- | --- | --- | --- |
| `pasto/` | Retro Grasses FREE | ToffeeCraft | Uso personal y comercial; se puede modificar; prohibido redistribuir el pack por separado. |
| `rocas/hojas/` | Retro Rocks FREE | ToffeeCraft | Igual que Retro Grasses. |
| `rocas/piedras/` | Stones pack x10 free | SirCatIsCat | Uso libre; se agradece mención. |
| `interfaz/barras/` | Pixel Xp Bars | justajokeart | Crédito al autor; revisar términos para uso comercial. |
| `interfaz/iconos/` | Icon Node For Godot | pixel-boy | CC0: uso libre, sin obligación de crédito. |
| `interfaz/controles/` | Controllers and Keyboard | Vryell | Crédito al autor; revisar términos para uso comercial. |

Enlaces:

- Retro Grasses: https://toffeecraft.itch.io/retro-grasses
- Retro Rocks: https://toffeecraft.itch.io/retro-rocks
- Icon Node For Godot: https://pixel-boy.itch.io/icon-godot-node
- Controllers and Keyboard: https://vryell.itch.io/
- Pixel Xp Bars: https://ko-fi.com/justajokeart
- Stones pack: Telegram `@SirCatIsCat`

## Pasto y rocas

Las hojas `pasto/hojas/*.png` y `rocas/hojas/*.png` miden 128×160 px y contienen una
cuadrícula de 4×5 tiles de 32×32 px. Hay 40 variantes de pasto y 80 de rocas.

Se incluyen tres recursos `TileSet`:

- `pasto/pasto_tileset.tres`: solo pasto.
- `rocas/rocas_tileset.tres`: solo rocas.
- `decoracion_tileset.tres`: pasto + rocas en un mismo TileSet.

Uso recomendado:

1. Añade un nodo `TileMapLayer` a la escena.
2. Asígnale `res://assets/materiales/decoracion_tileset.tres` en la propiedad `Tile Set`.
3. Pinta las decoraciones con la pestaña **TileMap** del editor.

La escena `Nivel1.tscn` ya incluye una capa vacía llamada `Decoracion` con ese TileSet
asignado.

## Piedras sueltas

`rocas/piedras/piedra_01.png` … `piedra_10.png` son sprites individuales de
aproximadamente 49×37 px. Se pueden arrastrar directamente a un `Sprite2D`.

## Interfaz

- `interfaz/barras/sprites/`: barras de XP, corazones, círculos, baterías y cuadros
  en distintos estados (lleno, vacío, porcentajes).
- `interfaz/iconos/`: iconos de 16×16 px en las variantes `color`, `control`, `node`,
  `node_2D`, `node_3D` y `white`.
- `interfaz/controles/`: hojas de sprites de controles (Xbox, PlayStation, Switch y
  minimalista), teclados claro/oscuro, mouse, cursores y sticks.

Los sprites de interfaz se pueden usar en `TextureRect`, `TextureButton` o `Sprite2D`.
El proyecto ya tiene el filtro de textura en **Nearest** (`project.godot`), así que el
pixel art se mantiene nítido.

## Archivos de referencia

- `referencia/paleta_rosy42.png`: paleta «rosy 42» de PineTreePizza con tres azules
  de edg32 (créditos en `creditos/paleta_rosy42.txt`).
- `referencia/piedras_portada.png`: portada del pack de piedras.
- `fuentes/`: PSD de las barras y aseprite de la portada de piedras, por si se
  quieren editar.

## Créditos originales

Los textos originales de los autores se conservan en `creditos/`.
