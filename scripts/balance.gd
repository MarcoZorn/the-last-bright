class_name Balance
## Tutti i numeri tarabili del gioco stanno QUI e solo qui.
## Si modificano senza toccare la logica: e' il file da smanettare durante i playtest.

const TILE := 16

# --- risorse di partenza ---
const MORALE_INIZIALE := 60.0      # Chiesa
const DENARO_INIZIALE := 120.0     # Governo
const POPOLAZIONE_INIZIALE := 120
# la sicurezza NON e' un numero libero: e' lo stato reale delle barricate, calcolato

# --- ritmo ---
const GIORNO_DURATA := 45.0        # secondi di fase gestionale
const NOTTE_MAX := 200.0           # tetto di sicurezza se qualcosa si incastra

# --- ondate (crescono col numero del giorno) ---
const ONDATA_BASE := 6
const ONDATA_CRESCITA := 4         # zombie in piu' per ogni giorno passato
const SPAWN_RITMO := 1.1           # secondi tra uno zombie e il successivo
const ZOMBIE_MAX := 150

# --- il tuo leader ---
const PLAYER_SPEED := 95.0
const PLAYER_VITA := 100.0
const ATTACCO_DANNO := 2.0
const ATTACCO_RAGGIO := 34.0
const ATTACCO_CADENZA := 0.35
const RIANIMAZIONE := 4.0          # secondi a terra prima di tornare in piazza
const MORALE_PER_CADUTA := 5.0     # vedere il proprio leader cadere demoralizza

# --- zombie ---
const ZOMBIE_VITA := 3.0
const ZOMBIE_DANNO := 22.0         # al secondo, addosso al giocatore
const ZOMBIE_SPEED := 26.0
const PATH_REFRESH := 0.6

# --- barricate ---
const BARRICATA_VITA := 200.0
const BARRICATA_DANNO := 1.5       # danno al secondo per zombie a contatto:
                                   # 6 zombie = ~22s per sfondare, c'e' tempo di reagire
const RIPARA_QUANTITA := 40.0
const RIPARA_COSTO := 8.0          # denaro per una riparazione

# --- guardie (si selezionano e si spostano, non sono torrette) ---
const GUARDIA_COSTO := 40.0
const GUARDIA_VITA := 60.0
const GUARDIA_VELOCITA := 68.0
const GUARDIA_RAGGIO := 82.0
const GUARDIA_CADENZA := 1.0
const PROIETTILE_VELOCITA := 240.0
const PROIETTILE_DANNO := 1.5

# --- edifici delle fazioni: sono bersagli veri, non decorazione ---
const EDIFICIO_VITA := 400.0
const EDIFICIO_CADUTO_MORALE := 30.0
const EDIFICIO_CADUTO_ABITANTI := 20

# --- contraccolpo ---
const SPINTA_COLPO := 110.0

# --- economia e morale: qui vive l'interdipendenza tra le fazioni ---
const TASSE_PER_ABITANTE := 0.30   # gettito a inizio giornata...
const TASSE_PESO_MORALE := 0.01    # ...moltiplicato per (morale * questo): morale 100 = pieno
const MORALE_PER_ABITANTE_PERSO := 0.8
const MORALE_RECUPERO_GIORNO := 4.0
const ABITANTI_PERSI_PER_ZOMBIE := 2
