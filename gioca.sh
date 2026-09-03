#!/usr/bin/env bash
# The Last Bright — comandi del progetto.
#   ./gioca.sh            avvia il gioco
#   ./gioca.sh test       lancia tutti i controlli
#   ./gioca.sh sim        fa giocare l'IA e riporta il bilanciamento
#   ./gioca.sh foto       salva una panoramica in /tmp/lastbright_shot.png
#   ./gioca.sh windows    compila l'eseguibile per Windows
#   ./gioca.sh web        compila per il browser e lo serve su localhost:8777
set -euo pipefail
cd "$(dirname "$0")"

# sotto xvfb non c'e' scheda audio: senza driver dummy Godot resta appeso
FOTO=(xvfb-run -a godot --audio-driver Dummy --resolution 1280x720)

case "${1:-gioca}" in
  gioca)   godot ;;
  test)
    python3 tools/check_map.py
    godot --headless res://tools/test_assedio.tscn 2>&1 | grep -E "^OK|error" || true
    godot --headless res://tools/test_potere.tscn  2>&1 | grep -E "^OK|error" || true
    ;;
  sim)     godot --headless --audio-driver Dummy res://tools/sim.tscn 2>&1 | grep -vE "^\s*$" ;;
  foto)    "${FOTO[@]}" -- --shot "${@:2}" >/dev/null 2>&1; echo "/tmp/lastbright_shot.png" ;;
  windows)
    godot --headless --export-release "Windows Desktop" >/dev/null 2>&1
    ls -lh build/windows/TheLastBright.exe ;;
  web)
    godot --headless --export-release "Web" >/dev/null 2>&1
    echo "apri http://localhost:8777"
    (cd build/web && python3 -m http.server 8777) ;;
  *) sed -n '2,9p' "$0"; exit 1 ;;
esac
