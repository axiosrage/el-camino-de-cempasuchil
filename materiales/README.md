# Materiales fuente

Arte editable y packs de terceros que **no** carga el juego. Esta carpeta tiene un
archivo `.gdignore`, así que Godot no la importa ni la incluye en las exportaciones.

## Contenido

| Carpeta | Contenido |
| --- | --- |
| `arte/` | Archivos `.ase`, `.aseprite` y `.psd` editables (personaje, ítems, fondo, barras). |
| `arte/tilesets/` | Presets `TileSet` de pasto y rocas, y piedras sueltas del pack. |
| `fuentes/BoldPixels/` | Kit completo de la fuente BoldPixels (OTF, TTF, WOFF, SVG, especímenes y licencia). |
| `interfaz/` | Iconos CC0 y packs de barras/controles (estos últimos no se versionan). |
| `referencias/` | Paletas, portadas y concept art. |
| `creditos/` | Textos originales de licencia y créditos de los autores. |
| `marca/` | Portada, logo y banner para tienda/itch.io. |

> **Packs no versionados:** `interfaz/barras/`, `interfaz/controles/` y
> `arte/fuentes/barras_xp.psd` no se suben al repositorio por sus condiciones de
> redistribución. Se conservan en local y están excluidos en `.gitignore`.

Los recursos que sí usa el juego están en `assets/`, con nombres limpios:
`assets/escenario/tilesets/` (tilesets y decoración), `assets/interfaz/` (fuentes,
menú y HUD), `assets/audio/` (sonidos), etc.

## Packs de terceros

| Pack | Autor | Licencia / crédito |
| --- | --- | --- |
| Retro Grasses FREE | ToffeeCraft | Uso personal y comercial; se puede modificar; prohibido redistribuir el pack por separado. |
| Retro Rocks FREE | ToffeeCraft | Igual que Retro Grasses. |
| Stones pack x10 free | SirCatIsCat | Uso libre; se agradece mención. |
| Pixel Xp Bars | justajokeart | Crédito al autor; revisar términos para uso comercial. |
| Icon Node For Godot | pixel-boy | CC0: uso libre, sin obligación de crédito. |
| Controllers and Keyboard | Vryell | Crédito al autor; revisar términos para uso comercial. |

Enlaces:

- Retro Grasses: <https://toffeecraft.itch.io/retro-grasses>
- Retro Rocks: <https://toffeecraft.itch.io/retro-rocks>
- Icon Node For Godot: <https://pixel-boy.itch.io/icon-godot-node>
- Controllers and Keyboard: <https://vryell.itch.io/>
- Pixel Xp Bars: <https://ko-fi.com/justajokeart>
- Stones pack: Telegram `@SirCatIsCat`

## Pasto y rocas

Las hojas de tiles miden 128×160 px y contienen una cuadrícula de 4×5 tiles de
32×32 px. Las copias que usa el nivel están en `assets/escenario/tilesets/pasto/` y
`assets/escenario/tilesets/rocas/`.

TileSets:

- `arte/tilesets/pasto/pasto_tileset.tres`: solo pasto.
- `arte/tilesets/rocas/rocas_tileset.tres`: solo rocas.
- `assets/escenario/tilesets/decoracion_tileset.tres`: pasto + rocas; es el que usa
  `Nivel1.tscn` en la capa `Decoracion`.

## Piedras sueltas

`arte/tilesets/rocas/piedras/piedra_01.png` … `piedra_10.png` son sprites individuales
de aproximadamente 49×37 px.

## Interfaz

- `interfaz/barras/sprites/`: barras de XP, corazones, círculos, baterías y cuadros en
  distintos estados.
- `interfaz/iconos/`: iconos de 16×16 px en variantes `color`, `control`, `node`,
  `node_2D`, `node_3D` y `white`.
- `interfaz/controles/`: controles de Xbox, PlayStation, Switch y minimalista,
  teclados claro/oscuro, mouse, cursores y sticks.

El proyecto usa filtro de textura **Nearest** (`project.godot`), así que el pixel art
se mantiene nítido.

## Archivos de referencia

- `referencias/paleta_rosy42.png`: paleta «rosy 42» de PineTreePizza con tres azules
  de edg32 (créditos en `creditos/paleta_rosy42.txt`).
- `referencias/piedras_portada.png`: portada del pack de piedras.
- `referencias/concept_arts/`: bocetos del nivel.
- `arte/fuentes/`: PSD de las barras y aseprite de la portada de piedras.
