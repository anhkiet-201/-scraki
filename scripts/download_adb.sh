#!/bin/bash
# ============================================================
# download_adb.sh
# Downloads ADB (Android Debug Bridge) standalone binaries
# for macOS (universal arm64 + x86_64) and Windows (exe + DLLs).
#
# Run ONCE after cloning or when binaries are missing:
#   bash scripts/download_adb.sh [--macos] [--windows] [--all]
#
# Without flags, downloads for the current platform.
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

MACOS_DEST="$ROOT_DIR/macos/Runner/Resources"
WIN_DEST="$ROOT_DIR/windows/runner/resources"
TMP_DIR=$(mktemp -d)

PLATFORM_TOOLS_MACOS="https://dl.google.com/android/repository/platform-tools-latest-darwin.zip"
PLATFORM_TOOLS_WINDOWS="https://dl.google.com/android/repository/platform-tools-latest-windows.zip"

download_macos() {
  echo "📦 Downloading ADB platform-tools for macOS..."
  curl -# -L -o "$TMP_DIR/pt-mac.zip" "$PLATFORM_TOOLS_MACOS"
  unzip -q "$TMP_DIR/pt-mac.zip" "platform-tools/adb" -d "$TMP_DIR/mac"
  mkdir -p "$MACOS_DEST"
  cp "$TMP_DIR/mac/platform-tools/adb" "$MACOS_DEST/adb"
  chmod +x "$MACOS_DEST/adb"
  echo "✅ macOS ADB: $MACOS_DEST/adb"
  file "$MACOS_DEST/adb"
}

download_windows() {
  echo "📦 Downloading ADB platform-tools for Windows..."
  curl -# -L -o "$TMP_DIR/pt-win.zip" "$PLATFORM_TOOLS_WINDOWS"
  unzip -q "$TMP_DIR/pt-win.zip" \
    "platform-tools/adb.exe" \
    "platform-tools/AdbWinApi.dll" \
    "platform-tools/AdbWinUsbApi.dll" \
    -d "$TMP_DIR/win"
  mkdir -p "$WIN_DEST"
  cp "$TMP_DIR/win/platform-tools/adb.exe"         "$WIN_DEST/"
  cp "$TMP_DIR/win/platform-tools/AdbWinApi.dll"   "$WIN_DEST/"
  cp "$TMP_DIR/win/platform-tools/AdbWinUsbApi.dll" "$WIN_DEST/"
  echo "✅ Windows ADB: $WIN_DEST/"
  ls -lh "$WIN_DEST/"*.{exe,dll} 2>/dev/null || true
}

# ── Argument parsing ──────────────────────────────────────────────────────────
DO_MACOS=false
DO_WINDOWS=false

if [[ $# -eq 0 ]]; then
  # No args → detect current platform
  if [[ "$(uname)" == "Darwin" ]]; then DO_MACOS=true; fi
  if [[ "$(uname)" == *"NT"* ]] || [[ "$OS" == "Windows_NT" ]]; then DO_WINDOWS=true; fi
fi

for arg in "$@"; do
  case "$arg" in
    --macos)   DO_MACOS=true ;;
    --windows) DO_WINDOWS=true ;;
    --all)     DO_MACOS=true; DO_WINDOWS=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

$DO_MACOS   && download_macos
$DO_WINDOWS && download_windows

echo ""
echo "🧹 Cleaning up..."
rm -rf "$TMP_DIR"
echo "Done! ADB binaries ready."
