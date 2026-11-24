#!/usr/bin/env bash
# Exporta la versión web y copia los archivos de visión por computadora.
# Uso: herramientas/exportar_web.sh [ruta-de-godot]
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${1:-${GODOT:-$HOME/Descargas/Programas/Godot_v4.7.2-stable_linux.x86_64}}"
DESTINO="$RAIZ/exports/web"

if [[ ! -x "$GODOT" ]]; then
	echo "No se encontró Godot en: $GODOT" >&2
	exit 1
fi

rm -rf "$DESTINO"
mkdir -p "$DESTINO/mediapipe/wasm"

echo "Exportando preset Web…"
"$GODOT" --headless --path "$RAIZ" --export-release "Web" "$DESTINO/index.html"

echo "Copiando detector de presencia y MediaPipe…"
cp "$RAIZ/web/presencia_camara.js" "$DESTINO/"
cp "$RAIZ/web/pantalla_completa.js" "$DESTINO/"
cp "$RAIZ/web/salida_web.js" "$DESTINO/"
cp "$RAIZ/web/mediapipe/vision_bundle.js" "$DESTINO/mediapipe/"
cp "$RAIZ/web/mediapipe/blaze_face_short_range.tflite" "$DESTINO/mediapipe/"
cp "$RAIZ/web/mediapipe/LICENCIA-APACHE-2.0.txt" "$DESTINO/mediapipe/"
cp "$RAIZ/web/mediapipe/LEEME.txt" "$DESTINO/mediapipe/"
cp "$RAIZ/web/mediapipe/wasm/"* "$DESTINO/mediapipe/wasm/"

echo "Listo: $DESTINO"
du -sh "$DESTINO"
