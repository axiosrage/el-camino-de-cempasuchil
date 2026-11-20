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
- Opciones de volumen, pantalla completa, pausa automática y pausa.
- Sonidos de interfaz y de mundo.
- **Pausa automática por visión por computadora**: el juego detecta si sigues frente
  a la pantalla y se pausa solo cuando te alejas.

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
| Panel de depuración de visión | `F3` |

## Pausa automática (visión por computadora)

En **Opciones → PAUSA AUTOMÁTICA** se puede elegir el tiempo sin presencia
(3, 5, 10 o 20 segundos; por defecto 5) y activar la cámara. La cámara está
apagada por defecto.

La pausa solo se activa si durante ese tiempo **no se detecta presencia y
tampoco hay actividad de teclado, ratón o gamepad**. En los últimos 2 segundos
aparece el aviso `¿SIGUES AHÍ?`. La pausa por pérdida de foco es independiente
y está activada por defecto.

| Plataforma | Técnica | Reanudación |
| --- | --- | --- |
| Web | MediaPipe Face Detector (BlazeFace), CNN preentrenada | 2 s de rostro |
| Linux instalado | `CameraServer` (V4L2) y detección de movimiento | 0.8 s de movimiento |
| Windows | Solo pérdida de foco | 0.4 s al recuperar el foco |

- Cualquier acción manual (tecla `Esc`, botones del menú) convierte la pausa
  automática en manual.
- La cámara se apaga al pausar manualmente, al salir del nivel o al desactivar
  la opción. Durante la pausa automática sigue encendida para detectar el
  regreso.
- En Linux se recomienda usar 10 s si hay movimiento de fondo, porque la
  detección es por movimiento y no por rostro.
- `F3` muestra un panel con el estado del detector, la presencia, la latencia y
  la cuenta atrás.

**Privacidad:** todo el procesamiento ocurre en el equipo. No se guardan ni se
envían imágenes de la cámara. En web, MediaPipe y el modelo BlazeFace se
empaquetan dentro del build y se cargan solo al activar la opción.

## Estructura del proyecto

```text
assets/       Recursos que carga el juego (audio, sprites, tilesets, interfaz).
escenas/      Escenas .tscn y sus scripts .gd.
autoload/     Singletons: estado de partida, configuración, sonidos y detector de presencia.
autoload/presencia/  Backends de cámara para web, Linux y plataformas sin cámara.
web/          Detector JS y MediaPipe para la exportación web (ignorado por Godot).
herramientas/ Script de exportación web y HTML de inclusión.
pruebas/      Escenas y backends falsos para probar la pausa automática.
materiales/   Arte fuente editable (.ase, .psd, packs, fuentes completas).
docs/         Créditos y documentación.
exports/      Salidas de exportación (ignorado por git).
```

`materiales/` contiene un archivo `.gdignore`, por lo que Godot no lo importa ni lo
incluye en las exportaciones. `web/` también tiene `.gdignore`; sus archivos se
copian aparte al exportar la versión HTML5. `pruebas/` se excluye de los tres presets
mediante `exclude_filter`; no forma parte de los builds publicados.

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

Para la versión web, usa el script:

```bash
./herramientas/exportar_web.sh
```

El script exporta el preset `Web` y copia `web/presencia_camara.js` y la carpeta
`web/mediapipe/` (runtime, modelo y licencia) junto a `index.html`. El modelo se
carga de forma diferida la primera vez que se activa la cámara, así que el arranque
del juego no se ve afectado.

Si el navegador bloquea la cámara dentro del iframe de itch.io, abre el juego en una
pestaña nueva desde el botón de pantalla completa o el enlace de la página.

## Créditos

Consulta [docs/CREDITOS.md](docs/CREDITOS.md) para los recursos de terceros y sus
licencias. Los textos originales de los packs están en `materiales/creditos/`.
