#!/usr/bin/env bash
# Exporta el APK de Android firmado con la clave de publicación.
#
# La contraseña de la clave no se guarda en el repositorio. Antes de ejecutar:
#   export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/home/andre/.android/cempasuchil-release.jks
#   export GODOT_ANDROID_KEYSTORE_RELEASE_USER=cempasuchil
#   export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=...
#
# Uso: ./herramientas/exportar_android.sh [ruta_a_godot]

set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${1:-/home/andre/Descargas/Programas/Godot_v4.7.2-stable_linux.x86_64}"

export ANDROID_HOME="${ANDROID_HOME:-/home/andre/Android/Sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

: "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Define la ruta del keystore de publicación}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Define el alias del keystore}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Define la contraseña del keystore}"

mkdir -p "$RAIZ/exports/android"
"$GODOT" --headless --path "$RAIZ" --export-release "Android" \
	"$RAIZ/exports/android/ElCaminoDeCempasuchil.apk"

echo "Listo: $RAIZ/exports/android/ElCaminoDeCempasuchil.apk"
