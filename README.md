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

| tasto | cosa fa |
|---|---|
| WASD | muovi il tuo leader |
| SPAZIO | fendente frontale |
| E | ripara la barricata piu' vicina |
| Q | recluta una guardia |
| 1-6 | le azioni della tua fazione (cambiano se ti depongono) |
| click sx / dx | seleziona una guardia / mandala li' |
| F1 F2 F3 | cambi fazione, per provare il gioco da solo |

**Giorno** (15 secondi all'inizio, si allunga): incassi le tasse, ripari, recluti,
mandi spedizioni, e usi le azioni della tua fazione per portare a casa consenso.
**Notte**: arrivano. I primi giorni solo dal ponte a nord; dal giorno 5 anche dai
fianchi; dal giorno 10 sei circondato. Ogni notte sono di piu' e piu' duri.

**Il potere e' a somma zero.** Chiesa, Governo ed Esercito si dividono 100 punti
di legittimita': all'alba chi ha prodotto risultati ne guadagna, e li toglie agli
altri. Morale alto premia la Chiesa, casse piene il Governo, mura intatte
l'Esercito. Chi scende sotto 12 viene **deposto** -- ma non e' eliminato: passa
a giocare da ribelle, con azioni sue (sabotaggio, voci, furto) per riprendersi il
consenso. Se risale sopra 36 torna al potere, e chi e' rimasto indietro finisce
fuori al posto suo.

Vinci se reggi 10 giorni. Perdi se la popolazione arriva a zero o se crollano
tutti e tre gli edifici.

Una guardia costa 35$ e l'addestramento raddoppia di prezzo a ogni livello, quindi
poche guardie forti e tante guardie scarse sono due strategie diverse. Se una non
ti serve piu' la congedi (azione 4 dell'Esercito) e recuperi 20$. Il gettito
dell'alba dipende dal morale: una citta' demoralizzata e' anche una citta' povera.

Il tuo leader non e' un soldato: il fendente serve a toglierti dai guai. Per
reggere un'ondata servono le guardie, che partono scarse e migliorano solo se
l'Esercito paga l'addestramento -- coi soldi del Governo. Se cadi ti rialzi in
piazza dopo qualche secondo, ma la citta' ti ha visto cadere.

## Come e' fatto

Stato attuale: ciclo giorno/notte, ondate crescenti su piu' fronti, barricate,
guardie comandabili con livelli di addestramento, i tre edifici come bersagli,
combattimento, economia con viveri, potere a somma zero, golpe e ribelle,
spedizioni fuori le mura. Le due fazioni che non giochi sono guidate da una IA
scema (`ia_fazione.gd`) che si toglie il giorno che arriveranno tre giocatori veri.

Ancora da fare: stealth vero per il ribelle (adesso agisce ma non si
nasconde), sprite animati, audio.

Una cosa da capire prima di toccare il codice: **gli zombie non inseguono
nessuno.** Puntano al centro della piazza e chiedono ad A\* una strada. Finche'
le barricate sono in piedi quella strada non esiste, quindi vanno a sfondare la
barricata piu' vicina. Appena una cade, tutti gli altri trovano il varco da
soli. L'assedio non e' scritto da nessuna parte: viene fuori dalla mappa.

## Dove mettere le mani

| Voglio... | File |
|---|---|
| cambiare la mappa | `assets/map.txt` — e' testo, la legenda e' in cima a `tools/gen_map.py` |
| tarare un numero (vita, costi, durate, ondate, difficolta') | `scripts/balance.gd` — **tutti** i numeri stanno li' |
| aggiungere o cambiare un'azione di fazione | la tabella `AZIONI` in `scripts/balance.gd` |
| cambiare che tile usa un terreno | la tabella `TILES` in cima a `scripts/world.gd` |
| cambiare l'economia | `_alba()` in `scripts/game_state.gd` |

Dopo aver modificato la mappa:

```bash
python3 tools/check_map.py                                  # non hai murato un varco?
godot --headless --script res://tools/test_assedio.gd       # l'assedio funziona ancora?
godot --headless --script res://tools/test_potere.gd        # il golpe scatta ancora?
godot --headless --resolution 1280x720 -- --shot --notte    # panoramica in /tmp/lastbright_shot.png
```

## Asset

Kenney (kenney.nl), licenza CC0. Scaricati con `tools/fetch-assets.sh`.
Sono placeholder: servono a leggere la mappa, non a essere l'aspetto finale.

## Giocare in tre

`O` ospita, `U` si unisce, porta 8910. Il movimento dei leader e' del client,
tutto il resto (risorse, potere, ondate, zombie, barricate) e' del server.
Provarlo senza cliccare:

```bash
godot -- --ospita --avvia-fra=5      # in un terminale
godot -- --unisciti=127.0.0.1        # in un altro
```

## Far provare il gioco a qualcuno

Il manuale completo e' in [MANUALE.md](MANUALE.md), e si apre anche dentro il
gioco col tasto **H**.

### A un amico con Windows

```bash
godot --headless --export-release "Windows Desktop"
```

Produce `build/windows/TheLastBright.exe`: **un unico file da ~105 MB**, con il
motore incluso. Non serve installare niente, si fa doppio clic. Windows mostrera'
l'avviso "SmartScreen" perche' l'eseguibile non e' firmato: "Ulteriori
informazioni" → "Esegui comunque". Per mandarlo, zippalo (scende a ~45 MB) e
usa WeTransfer o una Release di GitHub -- via mail non passa.

### Sul web

```bash
godot --headless --export-release "Web"
```

Produce `build/web/`. E' compilato **senza thread**, quindi gira su qualunque
hosting statico senza bisogno di header speciali (COOP/COEP), che e' la trappola
classica dei build web di Godot.

Per provarlo in locale:

```bash
cd build/web && python3 -m http.server 8777
# poi apri http://localhost:8777
```

Per metterlo online, in ordine di comodita':

1. **itch.io** — la strada giusta per un gioco. Crei un progetto, scegli "HTML",
   carichi lo zip di `build/web/`, imposti `index.html` come file principale.
   Gratis, e puoi tenerlo **non in elenco** con un link segreto da mandare solo
   a chi vuoi.
2. **GitHub Pages** — gratis ma richiede che il repo sia **pubblico**:
   ```bash
   gh repo edit --visibility public --accept-visibility-change-consequences
   git subtree push --prefix build/web origin gh-pages
   gh api -X POST repos/:owner/:repo/pages -f source[branch]=gh-pages -f source[path]=/
   ```
   Il gioco finisce su `https://<utente>.github.io/<repo>/`.
3. **Netlify / Cloudflare Pages** — trascini la cartella `build/web` nella loro
   pagina di upload e ti danno un link. Zero configurazione, repo privato.

> `build/` non e' versionato: sono ~150 MB di roba rigenerabile con due comandi.
