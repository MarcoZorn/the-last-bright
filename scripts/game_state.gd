extends Node
## Stato della citta'-stato. Autoload.
## NOTA ARCHITETTURALE: quando arrivera' il multiplayer questo vive SOLO sul
## server e viene replicato filtrato per giocatore (serve al ribelle stealth:
## se il client conosce tutto lo stato, il tradimento e' barabile da console).

enum Faction { CHIESA, GOVERNO, ESERCITO }
enum Fase { GIORNO, NOTTE }

const NOMI := {
	Faction.CHIESA: "Chiesa",
	Faction.GOVERNO: "Governo",
	Faction.ESERCITO: "Esercito",
}

var morale: float = Balance.MORALE_INIZIALE       # Chiesa
var denaro: float = Balance.DENARO_INIZIALE       # Governo
var sicurezza: float = 100.0                      # Esercito: derivata dalle barricate
var popolazione: int = Balance.POPOLAZIONE_INIZIALE

var fase: Fase = Fase.GIORNO
var giorno: int = 1
var tempo_fase: float = 0.0
var zombie_uccisi: int = 0
var finita := false

signal cambiato
signal fase_cambiata(nuova: Fase)

func _ready() -> void:
	_registra_wasd()

func modifica(campo: String, delta: float) -> void:
	set(campo, clampf(get(campo) + delta, 0.0, 999.0))
	cambiato.emit()

func cambia_fase(nuova: Fase) -> void:
	fase = nuova
	tempo_fase = 0.0
	if nuova == Fase.GIORNO:
		giorno += 1
		_alba()
	fase_cambiata.emit(nuova)
	cambiato.emit()

## L'alba e' il momento in cui le fazioni contano i danni e incassano.
## Qui vive la prima interdipendenza vera: una popolazione demoralizzata
## paga meno tasse, quindi la Chiesa finanzia indirettamente l'Esercito.
func _alba() -> void:
	var gettito := popolazione * Balance.TASSE_PER_ABITANTE * (morale * Balance.TASSE_PESO_MORALE)
	denaro += gettito
	morale = minf(morale + Balance.MORALE_RECUPERO_GIORNO, 100.0)

func perdi_abitanti(quanti: int) -> void:
	popolazione = maxi(popolazione - quanti, 0)
	morale = maxf(morale - quanti * Balance.MORALE_PER_ABITANTE_PERSO, 0.0)
	if popolazione == 0:
		finita = true
	cambiato.emit()

func _registra_wasd() -> void:
	var mappa := {"ui_up": KEY_W, "ui_down": KEY_S, "ui_left": KEY_A, "ui_right": KEY_D}
	for azione in mappa:
		var ev := InputEventKey.new()
		ev.physical_keycode = mappa[azione]
		InputMap.action_add_event(azione, ev)
	for nome in {"ripara": KEY_E, "costruisci": KEY_Q}:
		if not InputMap.has_action(nome):
			InputMap.add_action(nome)
		var ev2 := InputEventKey.new()
		ev2.physical_keycode = {"ripara": KEY_E, "costruisci": KEY_Q}[nome]
		InputMap.action_add_event(nome, ev2)
