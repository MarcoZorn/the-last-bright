# The Last Bright

Prototipo 2D top-down di un gioco multiplayer asimmetrico: una piazza fortificata
tipo Ponte Milvio durante un'apocalisse zombie, governata da tre fazioni
(Chiesa, Governo, Esercito) che devono collaborare contro l'esterno e si
contendono il potere all'interno.

Il 2D e' un gradino, non la meta: serve a capire se le meccaniche funzionano
prima di affrontare il 3D in terza persona.

## Provarlo

```bash
godot --path .            # oppure apri il progetto nell'editor
```

WASD per muoversi, **E** ripara la barricata piu' vicina, **Q** piazza un posto
di guardia. Il giorno dura 45 secondi, poi arriva la notte.

## Come e' fatto

Stato attuale: ciclo giorno/notte, ondate crescenti, barricate distruttibili e
riparabili, posti di guardia, tre risorse che si influenzano a vicenda.
Ancora da fare: multiplayer, loop politico, ribelle in stealth, spedizioni.

Una cosa da capire prima di toccare il codice: **gli zombie non inseguono
nessuno.** Puntano al centro della piazza e chiedono ad A\* una strada. Finche'
le barricate sono in piedi quella strada non esiste, quindi vanno a sfondare la
barricata piu' vicina. Appena una cade, tutti gli altri trovano il varco da
soli. L'assedio non e' scritto da nessuna parte: viene fuori dalla mappa.

## Dove mettere le mani

| Voglio... | File |
|---|---|
| cambiare la mappa | `assets/map.txt` — e' testo, la legenda e' in cima a `tools/gen_map.py` |
| tarare un numero (vita, costi, durate, ondate) | `scripts/balance.gd` — **tutti** i numeri stanno li' |
| cambiare che tile usa un terreno | la tabella `TILES` in cima a `scripts/world.gd` |
| cambiare l'economia | `_alba()` in `scripts/game_state.gd` |

Dopo aver modificato la mappa:

```bash
python3 tools/check_map.py                                  # non hai murato un varco?
godot --headless --script res://tools/test_assedio.gd       # l'assedio funziona ancora?
godot --headless --resolution 1280x720 -- --shot --notte    # panoramica in /tmp/lastbright_shot.png
```

## Asset

Kenney (kenney.nl), licenza CC0. Scaricati con `tools/fetch-assets.sh`.
Sono placeholder: servono a leggere la mappa, non a essere l'aspetto finale.
