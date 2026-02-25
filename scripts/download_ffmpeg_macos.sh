#!/bin/bash
# ============================================================
# download_ffmpeg_macos.sh
# Downloads and creates a universal (arm64 + x86_64) static
# FFmpeg + FFprobe binary for the scraki macOS app bundle.
#
# Run this script once after cloning / when binaries are missing:
#   bash scripts/download_ffmpeg_macos.sh
#
# Binaries are placed in:
#   macos/Runner/Resources/ffmpeg
#   macos/Runner/Resources/ffprobe
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DEST="$ROOT_DIR/macos/Runner/Resources"
TMP_DIR=$(mktemp -d)

# ── Latest snapshot URLs from ffmpeg.martin-riedl.de ────────────────────────
AMD64_BASE="https://ffmpeg.martin-riedl.de/download/macos/amd64/1767299902_N-122320-g38e89fe502"
ARM64_BASE="https://ffmpeg.martin-riedl.de/download/macos/arm64/1771871259_N-122955-gfba9fc0c6b"

echo "📦 Downloading FFmpeg static binaries for macOS (Intel + Apple Silicon)..."

mkdir -p "$DEST"
cd "$TMP_DIR"

# Download in parallel
curl -# -L -o ffmpeg_amd64.zip  "$AMD64_BASE/ffmpeg.zip"  &
curl -# -L -o ffprobe_amd64.zip "$AMD64_BASE/ffprobe.zip" &
curl -# -L -o ffmpeg_arm64.zip  "$ARM64_BASE/ffmpeg.zip"  &
curl -# -L -o ffprobe_arm64.zip "$ARM64_BASE/ffprobe.zip" &
wait

echo "🔧 Extracting..."
unzip -q ffmpeg_amd64.zip  -d amd64
unzip -q ffprobe_amd64.zip -d amd64
unzip -q ffmpeg_arm64.zip  -d arm64
unzip -q ffprobe_arm64.zip -d arm64

echo "🔨 Creating universal binaries (lipo)..."
lipo -create amd64/ffmpeg  arm64/ffmpeg  -output "$DEST/ffmpeg"
lipo -create amd64/ffprobe arm64/ffprobe -output "$DEST/ffprobe"
chmod +x "$DEST/ffmpeg" "$DEST/ffprobe"

echo "🧹 Cleaning up temp files..."
cd /
rm -rf "$TMP_DIR"

echo ""
echo "✅ Done!"
file "$DEST/ffmpeg"
file "$DEST/ffprobe"
echo ""
echo "   ffmpeg  → $DEST/ffmpeg"
echo "   ffprobe → $DEST/ffprobe"
echo ""
echo "Now run: flutter build macos"
