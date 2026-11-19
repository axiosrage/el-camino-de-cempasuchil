# El camino de Cempasúchil

Juego de plataformas 2D en pixel art desarrollado en **Godot 4.7**. El nivel transcurre
en un paisaje inspirado en el Mictlán: plataformas, trampas, enemigos y agua que quita
vidas.

**Jugar en itch.io:** <https://axiosrage.itch.io/el-camino-de-cempasuchil>

## Estado

Prototipo jugable con:

- Menú principal, introducción y selector de 3 ranuras de guardado.
- Nivel 1 completo con checkpoints automáticos, enemigos, combate y lanzamiento de
  piedras.
- Sistema de 3 corazones, jades recolectables y reinicio de nivel al quedarse sin vida.
- Opciones de volumen y pantalla completa, y pausa.
- Sonidos de interfaz y de mundo.

## Requisitos

- Godot **4.7.x** (probado con 4.7.2, renderer GL Compatibility).

## Cómo ejecutar

1. Abre Godot y elige **Importar**.
2. Selecciona el archivo `project.godot` de este repositorio.
3. Pulsa **F5** (o el botón de reproducir).

La escena principal es `escenas/menu.tscn`.

## Controles

| Acción | Tecla |
| --- | --- |
| Moverse | `A` / `D` |
| Saltar | `Espacio` |
| Lanzar piedra | `F` |
| Pausa / volver | `Esc` |

## Estructura del proyecto

```text
assets/       Recursos que carga el juego (audio, sprites, tilesets, interfaz).
escenas/      Escenas .tscn y sus scripts .gd.
autoload/     Singletons: estado de partida, configuración y sonidos.
materiales/   Arte fuente editable (.ase, .psd, packs, fuentes completas).
docs/         Créditos y documentación.
exports/      Salidas de exportación (ignorado por git).
```

`materiales/` contiene un archivo `.gdignore`, por lo que Godot no lo importa ni lo
incluye en las exportaciones.

## Guardado

Las partidas se guardan en `user://partidas/ranura_1.json`, `ranura_2.json` y
`ranura_3.json`. Cada ranura guarda nivel, posición, vida, jades y checkpoint. Solo se
escribe en la ranura activa.

## Exportación

`export_presets.cfg` incluye tres presets:

| Preset | Plataforma | Salida |
| --- | --- | --- |
| `Web` | HTML5 | `exports/web/index.html` |
| `Windows` | Windows Desktop (x86_64) | `exports/windows/ElCaminoDeCempasuchil.exe` |
| `Linux` | Linux (x86_64) | `exports/linux/ElCaminoDeCempasuchil.x86_64` |

Las exportaciones se generan en `exports/`, que está ignorada por git. Los builds
publicados se suben a itch.io con `butler` en los canales `html5`, `windows` y `linux`.

## Créditos

Consulta [docs/CREDITOS.md](docs/CREDITOS.md) para los recursos de terceros y sus
licencias. Los textos originales de los packs están en `materiales/creditos/`.
