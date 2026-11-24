# El camino de Cempasúchil

Juego de plataformas 2D en pixel art desarrollado en **Godot 4.7**. El nivel transcurre
en un paisaje inspirado en el Mictlán: plataformas, trampas, enemigos y agua que quita
vidas.

**Jugar en itch.io:** <https://axiosrage.itch.io/el-camino-de-cempasuchil>

## Estado

Prototipo jugable con:

- Menú principal, introducción de 24 viñetas y selector de 3 ranuras de guardado.
- Nivel 1 completo con checkpoints automáticos, enemigos, combate y lanzamiento de
  piedras.
- Sistema de 3 corazones, jades recolectables y reinicio de nivel al quedarse sin vida.
- Opciones de volumen, pantalla completa, pausa automática y pausa. En PC el juego
  arranca en pantalla completa; si lo desactivas en Ajustes, se respeta la elección.
- Sonidos de interfaz y de mundo, y música de menú y de nivel con fundido cruzado.
- Velas decorativas con brillo amarillo repartidas por todo el recorrido.
- Flor de cempasúchil final y portal que se abre al recogerla, con pantalla
  de final y vuelta al menú.
- **Controles táctiles automáticos en móviles y tabletas**, con build APK para Android.
- **Pausa automática por visión por computadora**: el juego detecta si sigues frente
  a la pantalla y se pausa solo cuando te alejas.

## Requisitos

- Godot **4.7.x** (probado con 4.7.2, renderer GL Compatibility).

## Cómo ejecutar

1. Abre Godot y elige **Importar**.
2. Selecciona el archivo `project.godot` de este repositorio.
3. Pulsa **F5** (o el botón de reproducir).

La escena principal es `escenas/menu.tscn`.

## Escenario

El fondo parallax calcula sus repeticiones a partir del ancho real del tilemap
`Nivel`, así que sigue cubriendo todo el recorrido si el mapa se amplía. La
decoración del suelo también se repite hasta el final del nivel: se apoya en el
primer tile sólido de cada columna y no modifica las celdas que ya estaban
dibujadas.

## Controles

| Acción | Tecla | Mando | Móvil |
| --- | --- | --- | --- |
| Moverse | `A` / `D` | Stick izquierdo / D-pad | `IZQ` / `DER` |
| Saltar | `Espacio` | A / Cruz | `SALTO` |
| Lanzar piedra | `F` | X / Cuadrado | `LANZAR` |
| Pausa | `Esc` | Start / Options | `PAUSA` |
| Volver / cerrar | `Esc` | B / Círculo | Botones de la pantalla |
| Avanzar panel de intro | `Espacio` / `Enter` / `A` | A / Cruz | `TOCA PARA CONTINUAR` o tocar la viñeta |
| Saltar intro completa | `Esc` | B / Círculo | `SALTAR INTRO` |
| Salir del juego | Menú → `Salir` | Menú → `Salir` | Menú o pausa → `Salir` |
| Panel de depuración de visión | `F3` | — | — |

El mando también funciona en los menús: stick o D-pad para navegar, `A` para
aceptar y `B` para volver. En Opciones, el foco empieza en el control de volumen
para poder ajustar los valores sin usar el teclado.

### Controles táctiles

En móviles y tabletas aparecen automáticamente cinco botones en pantalla durante
el nivel: `IZQ` y `DER` abajo a la izquierda, `LANZAR` y `SALTO` abajo a la
derecha, y `PAUSA` arriba a la derecha. Se muestran cuando el sistema informa de
que hay pantalla táctil; en escritorio permanecen ocultos y no estorban.

Cada botón envía exactamente la misma acción del InputMap que el teclado o el
mando (`mov_izquierda`, `mov_derecha`, `salto`, `lanzar` y `pausa`), por lo que
las físicas, la carga del lanzamiento y el menú de pausa funcionan igual. Se
pueden mantener varios botones a la vez (por ejemplo, correr y saltar) y, si el
juego se pausa con un dedo todavía apoyado, las acciones se sueltan solas.

La escena está en `escenas/controles_tactiles.tscn` y se añade al nivel desde
`escenas/nivel_1.gd`, sin modificar la escena `Nivel1.tscn`. Los menús, la intro
y la pantalla final ya usan botones táctiles normales de Godot, así que se pueden
pulsar directamente con el dedo.

Con un panel abierto en el menú, `Espacio`, `Enter` o `A` pueden saltarlo: si el
foco está en un botón, se activa ese botón; si está en otro control (por
ejemplo, el volumen), el panel se cierra directamente. `B`/`Esc` siempre lo
cierran.

En la intro de cómic, `Espacio`, `Enter` o `A` avanzan al siguiente panel. `Esc`
o `B` (o el botón `SALTAR INTRO`) saltan la intro completa. En web y móvil
aparece además `TOCA PARA CONTINUAR` y se puede tocar directamente la viñeta para
pasar al panel siguiente sin esperar el temporizador.

## Agua, velas y final del nivel

El agua conserva su colisión sólida, igual que en `mictlan (2)`, para que la
tabla del perro flote en la superficie. Una zona de muerte reconstruida en
runtime cubre todas sus celdas, con 4 px extra por encima: tocar cualquier
charca mata al jugador, también si aparece dentro de ella. Mientras el niño va
montado en la tabla el agua no lo mata; al detenerse la tabla junto a la orilla,
salta automáticamente a la tierra firme y vuelve a ser vulnerable. Las velas se
reparten con una semilla fija por repisas secas, lejos del agua y de los puntos
importantes; su llama lleva un destello amarillo pulsante.

Al final del mapa están la flor de cempasúchil y el portal. El portal empieza
sellado y avisa si se intenta usar antes de tiempo. Al recoger la flor se
registra en la partida guardada, el portal se ilumina y se abre. Al entrar
aparece primero el panel `assets/intro/finalDemo.png`; se puede avanzar con
`Espacio`, `Enter` o `A`, o esperar a que termine su tiempo. Después aparece la
pantalla `EL CAMINO DE CEMPASÚCHIL`, desde la que se vuelve al menú.

## Música

Hay dos pistas en `assets/audio/`: `musica menu.mp3` suena en el menú y en la
intro, y `musica del juego.mp3` en el nivel. El autoload `Musica` las reproduce
en bucle y hace un fundido cruzado de un segundo al cambiar de escena. Sigue
sonando mientras el juego está en pausa, incluida la pantalla final.

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

- Cualquier acción manual (tecla `Esc`, `Start` del mando, botones del menú)
  convierte la pausa automática en manual.
- La cámara se apaga al pausar manualmente, al salir del nivel o al desactivar
  la opción. Durante la pausa automática sigue encendida para detectar el
  regreso.
- En Linux se recomienda usar 10 s si hay movimiento de fondo, porque la
  detección es por movimiento y no por rostro.
- Si conectas una **cámara externa USB**, el backend de Linux la prefiere sobre
  la cámara integrada (revisa el nombre del dispositivo y su posición) y vuelve
  a buscar feeds si deja de llegar imagen. El backend web también prioriza
  dispositivos externos cuando el navegador expone sus nombres, y reanuda la
  captura si el dispositivo se desconecta.
- `F3` muestra un panel con el estado del detector, la presencia, la latencia y
  la cuenta atrás. En Linux el nombre del backend incluye la cámara elegida.

**Privacidad:** todo el procesamiento ocurre en el equipo. No se guardan ni se
envían imágenes de la cámara. En web, MediaPipe y el modelo BlazeFace se
empaquetan dentro del build y se cargan solo al activar la opción.

### Aviso al abrir el juego

La primera vez que se abre el menú en cada sesión aparece el aviso
`PAUSA AUTOMÁTICA`. Explica que el juego puede pausarse por la cámara (Linux y
web) o por pérdida de foco (Windows) y ofrece dos botones:

- `ENTENDIDO` (`Espacio` / `A` / `Enter`) cierra el aviso y devuelve el foco al
  menú.
- `VER OPCIONES` abre directamente el panel de Opciones; al cerrarlo, el foco
  vuelve al menú.

El aviso no se repite al volver al menú desde una partida, no se guarda en
`configuracion.cfg` y vuelve a aparecer la próxima vez que se inicie el juego.

## Estructura del proyecto

```text
assets/       Recursos que carga el juego (audio, sprites, tilesets, interfaz).
escenas/      Escenas .tscn y sus scripts .gd.
autoload/     Singletons: estado de partida, configuración, salida, sonidos, música y detector de presencia.
autoload/presencia/  Backends de cámara para web, Linux y plataformas sin cámara.
web/          Detector JS, control de pantalla completa, salida web y MediaPipe para la exportación (ignorado por Godot).
herramientas/ Scripts de exportación web y Android, y HTML de inclusión.
pruebas/      Escenas y backends falsos para probar controles, pausa, final y música.
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

El nivel tiene puntos de guardado fijos repartidos en los tramos seguros. Al perder un
corazón se reaparece en el último punto alcanzado, conservando la vida restante, los
jades y la flor. El perro acompañante reaparece al lado del niño en ese mismo punto y
sigue acompañándolo. Solo al perder el tercer corazón se reinicia el nivel completo,
con el perro en su sitio inicial. Las posiciones se pueden ajustar en `PUNTOS_GUARDADO`,
en `escenas/nivel_1.gd`.

## Exportación

`export_presets.cfg` incluye cuatro presets:

| Preset | Plataforma | Salida |
| --- | --- | --- |
| `Web` | HTML5 | `exports/web/index.html` |
| `Windows` | Windows Desktop (x86_64) | `exports/windows/ElCaminoDeCempasuchil.exe` |
| `Linux` | Linux (x86_64) | `exports/linux/ElCaminoDeCempasuchil.x86_64` |
| `Android` | Android (ARM64 y ARMv7, desde API 24) | `exports/android/ElCaminoDeCempasuchil.apk` |

Las exportaciones se generan en `exports/`, que está ignorada por git. Los builds
publicados se suben a itch.io con `butler` en los canales `html5`, `windows`, `linux`
y `android`.

Para la versión web, usa el script:

```bash
./herramientas/exportar_web.sh
```

El script exporta el preset `Web` y copia `web/presencia_camara.js`,
`web/pantalla_completa.js`, `web/salida_web.js` y la carpeta `web/mediapipe/`
(runtime, modelo y licencia) junto a `index.html`. El modelo se carga de forma
diferida la primera vez que se activa la cámara, así que el arranque del juego
no se ve afectado.

Para generar el APK de Android:

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/home/andre/.android/cempasuchil-release.jks
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=cempasuchil
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=...
./herramientas/exportar_android.sh
```

El script usa el preset `Android`, firma el APK con esa clave y lo deja en
`exports/android/ElCaminoDeCempasuchil.apk`. La contraseña se pasa por variable de
entorno y no se guarda en el repositorio. El paquete es
`com.axiosrage.cempasuchil`, se instala desde Android 7.0 (API 24) y se ejecuta en
horizontal con `arm64-v8a` y `armeabi-v7a`.

En navegadores que lo permiten, `Esc` abre el menú sin sacar de pantalla completa:
`pantalla_completa.js` usa Keyboard Lock para capturar la tecla. Si el navegador no
ofrece esa API, el juego vuelve a pedir pantalla completa y muestra un aviso
pulsable. Para salir realmente de pantalla completa, desactiva «PANTALLA COMPLETA»
en Ajustes.

En web, «Salir» (en el menú o en la pausa) oculta el lienzo y muestra una pantalla
de despedida con «VOLVER A JUGAR» y un enlace a la página del juego. Así el juego
no se queda congelado en el último frame dentro del iframe de itch.io. Los
navegadores no permiten cerrar desde JavaScript una pestaña que no se abrió desde
JavaScript, por eso se muestra esa pantalla en lugar de cerrar la pestaña.

Si el navegador bloquea la cámara dentro del iframe de itch.io, abre el juego en una
pestaña nueva desde el botón de pantalla completa o el enlace de la página.

## Pruebas

### Controles táctiles

```bash
godot --headless --path . pruebas/controles_tactiles_test.tscn
```

Comprueba que el nivel crea los cinco botones, que mantienen y sueltan las
acciones del InputMap, que mueven al jugador real, que permiten pulsar dos a la
vez y que `PAUSA` abre y cierra el menú de pausa.

### Agua, velas, final y música

```bash
godot --headless --path . pruebas/agua_test.tscn
godot --headless --path . pruebas/perro_agua_test.tscn
godot --headless --path . pruebas/checkpoints_test.tscn
godot --headless --path . pruebas/vela_test.tscn
godot --headless --path . pruebas/final_test.tscn
godot --headless --path . pruebas/musica_test.tscn
```

Comprueban, en orden, que el agua cubre todas sus celdas y conserva su colisión
sólida; que el niño se monta en la tabla, cruza sin ahogarse y salta a tierra
firme; que los puntos de guardado son seguros y que solo se reinicia el nivel al
perder el último corazón; que las velas se apoyan en suelo seco y brillan; que el
portal solo se abre con la flor, que al entrar aparece primero el panel
`finalDemo` y después el mensaje final con el botón de volver al menú; y que las
dos pistas de música hacen el fundido cruzado en bucle.

### Pausa automática

La lógica del detector se puede probar sin cámara, con un backend falso:

```bash
godot --headless --path . pruebas/detector_test.tscn
```

La prueba simula ausencia, entrada de teclado, pérdida de foco y apagado/reactivación
de la cámara. `pruebas/camara_externa_test.tscn` comprueba, sin hardware, que la
puntuación del backend Linux prefiere cámaras USB/externas sobre la integrada.

### Pausa

```bash
godot --headless --path . pruebas/pausa_test.tscn
```

Comprueba que el menú de pausa incluye el botón «Salir» junto a «Reanudar»,
«Opciones» e «Ir al menú».

### Mando

El soporte de mando se prueba sin hardware, enviando eventos de gamepad al
InputMap:

```bash
godot --headless --path . pruebas/mando_test.tscn
godot --headless --path . pruebas/nivel_mando_test.tscn
```

La primera comprueba el mapa, la navegación de foco y la pausa; la segunda usa
el jugador real de `Nivel1` para verificar D-pad, stick, salto y pausa con Start.
`pruebas/` está excluido de los presets de exportación.

### Aviso inicial

```bash
godot --headless --path . pruebas/aviso_pausa_test.tscn
```

Comprueba que el aviso aparece una sola vez por sesión, que el foco queda
atrapado entre sus dos botones, que el menú no recibe foco mientras está
abierto, que `Espacio`, `A` y `B` lo cierran, que `Espacio` también salta
Opciones y que `VER OPCIONES` abre Opciones y devuelve el foco al menú al
cerrarlas.

### Intro

```bash
godot --headless --path . pruebas/intro_test.tscn
```

Comprueba que la intro carga las 24 viñetas de `assets/intro/Historia_Mictlán`,
que `Espacio`, `A` y `Enter` avanzan al siguiente panel, que el botón táctil y el
toque en la viñeta también avanzan, y que `B` salta la intro completa sin que los
botones capturen esas teclas.

## Créditos

Consulta [docs/CREDITOS.md](docs/CREDITOS.md) para los recursos de terceros y sus
licencias. Los textos originales de los packs están en `materiales/creditos/`.
