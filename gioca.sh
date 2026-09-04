#!/usr/bin/env bash
# The Last Bright — comandi del progetto.
#   ./gioca.sh            avvia il gioco
#   ./gioca.sh test       lancia tutti i controlli
#   ./gioca.sh verifica   esporta e controlla che il build disegni davvero
#   ./gioca.sh sim        fa giocare l'IA e riporta il bilanciamento
#   ./gioca.sh foto       salva una panoramica in /tmp/lastbright_shot.png
#   ./gioca.sh windows    compila l'eseguibile per Windows
#   ./gioca.sh linux      compila l'eseguibile per Linux
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
    godot --headless res://tools/test_guardia.tscn 2>&1 | grep -E "^OK|error" || true
    ;;
  sim)     godot --headless --audio-driver Dummy res://tools/sim.tscn 2>&1 | grep -vE "^\s*$" ;;
  foto)    "${FOTO[@]}" -- --shot "${@:2}" >/dev/null 2>&1; echo "/tmp/lastbright_shot.png" ;;
  windows)
    # niente >/dev/null: un export fallito passava inosservato e restava in giro
    # l'eseguibile vecchio. Succede se un altro Godot ha il progetto aperto.
    if ! godot --headless --export-release "Windows Desktop" 2>&1 | grep -qiE "^ERROR|Failed"; then
      ls -lh build/windows/TheLastBright.exe
    else
      echo "export Windows FALLITO (un altro Godot ha il progetto aperto?)" >&2
      exit 1
    fi ;;
  verifica)
    # l'unico controllo che avrebbe preso il bug di map.txt: eseguire il build
    # ESPORTATO e guardare se disegna qualcosa, invece di fidarsi dell'editor
    godot --headless --export-release "Linux" 2>&1 | grep -E "^ERROR|Failed" && exit 1
    rm -f /tmp/lastbright_shot.png
    xvfb-run -a ./build/linux/TheLastBright.x86_64 --audio-driver Dummy \
      --resolution 1280x720 -- --shot >/dev/null 2>&1
    peso=$(stat -c%s /tmp/lastbright_shot.png 2>/dev/null || echo 0)
    if [ "$peso" -lt 40000 ]; then
      echo "IL BUILD ESPORTATO NON DISEGNA (screenshot $peso byte)" >&2; exit 1
    fi
    echo "build esportato ok: disegna ($peso byte) -> /tmp/lastbright_shot.png" ;;
  linux)
    godot --headless --export-release "Linux" 2>&1 | grep -E "^ERROR|Failed" && { echo "export Linux FALLITO" >&2; exit 1; }
    ls -lh build/linux/TheLastBright.x86_64 ;;
  web)
    godot --headless --export-release "Web" 2>&1 | grep -iE "^ERROR|Failed" && { echo "export Web FALLITO" >&2; exit 1; }
    echo "apri http://localhost:8777"
    (cd build/web && python3 -m http.server 8777) ;;
  *) sed -n '2,9p' "$0"; exit 1 ;;
esac
