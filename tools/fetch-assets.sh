#!/usr/bin/env bash
# Scarica i pack CC0 di Kenney. Il link zip e' generato con un hash, va estratto dalla pagina.
set -euo pipefail
DEST="$(dirname "$0")/../assets/kenney"
mkdir -p "$DEST"
for slug in "$@"; do
  [ -d "$DEST/$slug" ] && { echo "skip $slug (gia' presente)"; continue; }
  url=$(curl -sL --max-time 30 "https://kenney.nl/assets/$slug" \
        | grep -oE "https://kenney\.nl/media/pages/assets/$slug/[^']+\.zip" | head -1)
  [ -z "$url" ] && { echo "!! link non trovato per $slug"; continue; }
  echo "-> $slug"
  curl -sL --max-time 120 "$url" -o "/tmp/$slug.zip"
  unzip -qo "/tmp/$slug.zip" -d "$DEST/$slug" && rm "/tmp/$slug.zip"
done
