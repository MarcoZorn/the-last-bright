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

# --- entita' ---
const PLAYER_SPEED := 95.0
const ZOMBIE_SPEED := 26.0
const PATH_REFRESH := 0.6

# --- barricate ---
const BARRICATA_VITA := 200.0
const BARRICATA_DANNO := 1.5       # danno al secondo per zombie a contatto:
                                   # 6 zombie = ~22s per sfondare, c'e' tempo di reagire
const RIPARA_QUANTITA := 40.0
const RIPARA_COSTO := 8.0          # denaro per una riparazione

# --- posti di guardia ---
const GUARDIA_COSTO := 40.0
const GUARDIA_RAGGIO := 72.0
const GUARDIA_CADENZA := 1.1

# --- economia e morale: qui vive l'interdipendenza tra le fazioni ---
const TASSE_PER_ABITANTE := 0.30   # gettito a inizio giornata...
const TASSE_PESO_MORALE := 0.01    # ...moltiplicato per (morale * questo): morale 100 = pieno
const MORALE_PER_ABITANTE_PERSO := 0.8
const MORALE_RECUPERO_GIORNO := 4.0
const ABITANTI_PERSI_PER_ZOMBIE := 2
