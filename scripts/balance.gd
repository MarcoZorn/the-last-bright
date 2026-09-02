class_name Balance
## Tutti i numeri tarabili del gioco stanno QUI e solo qui.
## Si modificano senza toccare la logica: e' il file da smanettare durante i playtest.

const TILE := 16

# --- risorse di partenza ---
const MORALE_INIZIALE := 60.0      # Chiesa
const DENARO_INIZIALE := 100.0     # Governo
const SICUREZZA_INIZIALE := 50.0   # Esercito
const POPOLAZIONE_INIZIALE := 120

# --- entita' ---
const PLAYER_SPEED := 90.0
const ZOMBIE_SPEED := 28.0
const ZOMBIE_HP := 3
const ZOMBIE_DANNO_MURA := 1.0     # sicurezza persa per zombie che sfonda

# --- ondate ---
const ONDATA_INTERVALLO := 12.0    # secondi tra uno spawn e l'altro
const ONDATA_QUANTITA := 4         # zombie per spawn
const ZOMBIE_MAX := 120            # tetto per non far esplodere il framerate

# --- ricalcolo path degli zombie (costo CPU vs reattivita') ---
const PATH_REFRESH := 0.6
