class_name Balance
## Tutti i numeri tarabili del gioco stanno QUI e solo qui.
## Si modificano senza toccare la logica: e' il file da smanettare durante i playtest.

const TILE := 16

# --- risorse di partenza ---
const MORALE_INIZIALE := 60.0
const DENARO_INIZIALE := 120.0
const VIVERI_INIZIALI := 200.0
const POPOLAZIONE_INIZIALE := 120

# --- ritmo: i primi giorni sono corti, poi si allungano ---
const GIORNO_BASE := 15.0
const GIORNO_CRESCITA := 3.0       # secondi in piu' per ogni giorno passato
const GIORNO_MAX := 45.0
const NOTTE_MAX := 200.0
const GIORNI_PER_VINCERE := 10

# --- ondate ---
const ONDATA_BASE := 5
const ONDATA_CRESCITA := 4
const SPAWN_RITMO := 0.8
const ZOMBIE_MAX := 150

# --- il tuo leader ---
const PLAYER_SPEED := 95.0
const PLAYER_VITA := 100.0
const ATTACCO_DANNO := 2.0
const ATTACCO_RAGGIO := 34.0
const ATTACCO_CADENZA := 0.35
const RIANIMAZIONE := 4.0
const MORALE_PER_CADUTA := 5.0

# --- zombie: ogni notte sono di piu', piu' duri e piu' cattivi ---
const ZOMBIE_VITA := 3.0
const ZOMBIE_VITA_PER_GIORNO := 1.2
const ZOMBIE_SPEED := 26.0
const ZOMBIE_SPEED_PER_GIORNO := 0.9
const ZOMBIE_DANNO := 22.0
const ZOMBIE_DANNO_PER_GIORNO := 1.5
const MORSO_MURA_PER_GIORNO := 0.15   # quanto piu' in fretta rodono le barricate

## Da dove possono arrivare. All'inizio solo dal ponte: e' l'unico fronte da
## tenere. Poi la citta' si scopre circondata.
const GIORNO_FIANCHI := 5
const GIORNO_ACCERCHIAMENTO := 10
const PATH_REFRESH := 0.6
const SPINTA_COLPO := 110.0

# --- barricate ---
const BARRICATA_VITA := 200.0
const BARRICATA_DANNO := 1.5
const RIPARA_QUANTITA := 40.0
const RIPARA_COSTO := 8.0

# --- guardie: partono da recluta scarsa, si migliorano a pagamento ---
## Non si comprano una volta e basta: ogni alba vanno pagate. Una guarnigione
## grossa e' un impegno permanente sulle casse, non un acquisto.
const GUARDIA_COSTO := 35.0             # reclutamento, una tantum
const GUARDIA_STIPENDIO := 7.0          # ogni alba, per ogni guardia in servizio
const GUARDIA_LIQUIDAZIONE := 20.0      # quanto rientra licenziandone una
const DISERZIONE_MORALE := 6.0          # se non paghi, se ne vanno e si sa in giro
const GUARDIA_VELOCITA := 68.0
const PROIETTILE_VELOCITA := 240.0
const GUARDIA_LIVELLO_MAX := 3
const GUARDIA_ADDESTRAMENTO_COSTO := 70.0   # per il primo livello, poi raddoppia
## livello 0 = recluta con un fucile scassato. Ogni livello e' una scelta di
## bilancio dell'Esercito, non un regalo.
const GUARDIA_VITA := [40.0, 60.0, 85.0, 120.0]
const GUARDIA_RAGGIO := [58.0, 70.0, 82.0, 96.0]
const GUARDIA_CADENZA := [1.6, 1.25, 0.95, 0.7]
const PROIETTILE_DANNO := [0.8, 1.2, 1.7, 2.4]

# --- edifici delle fazioni ---
const EDIFICIO_VITA := 400.0
const EDIFICIO_CADUTO_MORALE := 30.0
const EDIFICIO_CADUTO_ABITANTI := 20

# --- economia dell'alba ---
const TASSE_PER_ABITANTE := 0.30
const TASSE_PESO_MORALE := 0.01
const VIVERI_PER_ABITANTE := 0.35   # quanto mangia la citta' ogni giorno
const FAME_MORALE := 12.0           # morale perso quando i viveri finiscono
const FAME_ABITANTI := 6
const MORALE_PER_ABITANTE_PERSO := 0.8
const MORALE_RECUPERO_GIORNO := 3.0
const ABITANTI_PERSI_PER_ZOMBIE := 2

# --- potere e legittimita': la somma dei tre fa sempre 100, quindi guadagnare
#     potere significa per forza toglierlo a qualcun altro ---
const POTERE_SOGLIA_GOLPE := 12.0   # sotto questa quota vieni deposto
const POTERE_SOGLIA_RITORNO := 36.0 # il ribelle che la supera si riprende il potere
const POTERE_SPINTA_MORALE := 0.10  # quanto il morale alto premia la Chiesa
const POTERE_SPINTA_DENARO := 0.04  # quanto le casse piene premiano il Governo
const POTERE_SPINTA_MURA := 0.10    # quanto le mura intatte premiano l'Esercito

# --- spedizioni fuori le mura ---
const SPEDIZIONE_DURATA := 22.0
const SPEDIZIONE_BOTTINO_DENARO := 55.0
const SPEDIZIONE_BOTTINO_VIVERI := 70.0
const SPEDIZIONE_RISCHIO := 0.28    # probabilita' di non tornare

## Le azioni delle fazioni. Aggiungerne una e' aggiungere una riga qui.
## fazione: 0 Chiesa, 1 Governo, 2 Esercito, 3 Ribelle, -1 chiunque
## effetti: variazioni dirette alle risorse. speciale: aggancia codice in azioni.gd
const AZIONI := [
	{"id": "predica", "fazione": 0, "nome": "Predica", "ricarica": 10.0,
		"effetti": {"morale": 7.0}, "desc": "La citta' ritrova un po' di fede"},
	{"id": "processione", "fazione": 0, "nome": "Processione", "ricarica": 22.0,
		"effetti": {"morale": 16.0, "denaro": -18.0}, "desc": "Morale alto, casse piu' leggere"},
	{"id": "scomunica", "fazione": 0, "nome": "Scomunica", "ricarica": 35.0,
		"effetti": {"morale": -4.0}, "speciale": "scomunica",
		"desc": "Toglie potere alla fazione piu' forte, ma il popolo si spaventa"},

	{"id": "tassa", "fazione": 1, "nome": "Tassa straord.", "ricarica": 16.0,
		"effetti": {"denaro": 45.0, "morale": -9.0}, "desc": "Soldi subito, malcontento subito"},
	{"id": "razionamento", "fazione": 1, "nome": "Razionamento", "ricarica": 22.0,
		"effetti": {"viveri": 45.0, "morale": -7.0}, "desc": "Allunga le scorte affamando la gente"},
	{"id": "decreto", "fazione": 1, "nome": "Decreto", "ricarica": 38.0,
		"effetti": {"morale": -5.0}, "speciale": "decreto",
		"desc": "Un colpo di mano legale: piu' potere al Governo"},

	{"id": "rinforza", "fazione": 2, "nome": "Rinforza mura", "ricarica": 14.0,
		"effetti": {"denaro": -30.0}, "speciale": "ripara_tutto",
		"desc": "Ripara ogni barricata della citta'"},
	{"id": "coprifuoco", "fazione": 2, "nome": "Coprifuoco", "ricarica": 30.0,
		"effetti": {"morale": -8.0}, "speciale": "coprifuoco",
		"desc": "Ordine e disciplina: piu' potere all'Esercito"},
	{"id": "addestramento", "fazione": 2, "nome": "Addestramento", "ricarica": 8.0,
		"effetti": {}, "speciale": "addestramento",
		"desc": "Migliora tutte le guardie di un livello. Costa sempre di piu'"},
	{"id": "licenzia", "fazione": 2, "nome": "Licenzia", "ricarica": 3.0,
		"effetti": {}, "speciale": "licenzia",
		"desc": "Congedi la guardia selezionata: recuperi 20$ e uno stipendio in meno"},
	{"id": "leva", "fazione": 2, "nome": "Leva", "ricarica": 26.0,
		"effetti": {"denaro": -35.0, "morale": -4.0}, "speciale": "leva",
		"desc": "Due guardie subito, arruolate a forza"},

	{"id": "sabotaggio", "fazione": 3, "nome": "Sabotaggio", "ricarica": 26.0,
		"effetti": {}, "speciale": "sabota",
		"desc": "Indebolisci una barricata di nascosto: l'Esercito ci fara' brutta figura"},
	{"id": "voci", "fazione": 3, "nome": "Diffondi voci", "ricarica": 22.0,
		"effetti": {"morale": -10.0}, "speciale": "voci",
		"desc": "Screditi la Chiesa e ti riprendi consenso"},
	{"id": "furto", "fazione": 3, "nome": "Furto", "ricarica": 24.0,
		"effetti": {}, "speciale": "furto",
		"desc": "Svuoti le casse del Governo e ti finanzi"},

	{"id": "spedizione", "fazione": -1, "nome": "Spedizione", "ricarica": 34.0,
		"effetti": {}, "speciale": "spedizione",
		"desc": "Mandi qualcuno oltre le mura a cercare risorse. Puo' non tornare"},
]

static func giorno_durata(giorno: int) -> float:
	return minf(GIORNO_BASE + GIORNO_CRESCITA * (giorno - 1), GIORNO_MAX)

static func zombie_vita(giorno: int) -> float:
	return ZOMBIE_VITA + ZOMBIE_VITA_PER_GIORNO * (giorno - 1)

static func zombie_velocita(giorno: int) -> float:
	return ZOMBIE_SPEED + ZOMBIE_SPEED_PER_GIORNO * (giorno - 1)

static func zombie_danno(giorno: int) -> float:
	return ZOMBIE_DANNO + ZOMBIE_DANNO_PER_GIORNO * (giorno - 1)

static func morso_mura(giorno: int) -> float:
	return BARRICATA_DANNO + MORSO_MURA_PER_GIORNO * (giorno - 1)

## I fronti aperti in un dato giorno: "nord" c'e' sempre, gli altri si aggiungono.
static func fronti(giorno: int) -> Array:
	var f := ["nord"]
	if giorno >= GIORNO_FIANCHI:
		f.append("fianchi")
	if giorno >= GIORNO_ACCERCHIAMENTO:
		f.append("sud")
	return f
