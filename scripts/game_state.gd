extends Node
## Stato della citta'-stato. Autoload.
## NOTA ARCHITETTURALE: quando arrivera' il multiplayer questo vive SOLO sul
## server e viene replicato filtrato per giocatore (serve al ribelle: se il
## client conosce tutto lo stato, il tradimento e' barabile da console).

enum Faction { CHIESA, GOVERNO, ESERCITO, RIBELLE }
enum Fase { GIORNO, NOTTE }

const NOMI := ["Chiesa", "Governo", "Esercito", "Ribelle"]

var morale: float = Balance.MORALE_INIZIALE
var denaro: float = Balance.DENARO_INIZIALE
var viveri: float = Balance.VIVERI_INIZIALI
var sicurezza: float = 100.0                  # derivata dallo stato delle mura
var popolazione: int = Balance.POPOLAZIONE_INIZIALE

## Somma sempre 100: prendere potere significa per forza toglierlo a qualcuno.
var potere: Array[float] = [34.0, 33.0, 33.0]
var deposta: int = -1                         # fazione ribelle, -1 se nessuna
var fazione_giocatore: int = 0
var livello_guardie: int = 0
var addestramenti: int = 0

var fase: Fase = Fase.GIORNO
var giorno: int = 1
var tempo_fase: float = 0.0
var zombie_uccisi: int = 0
var finita := false
var vinta := false

signal cambiato
signal fase_cambiata(nuova: Fase)
signal annuncio(testo: String, colore: Color)

func _ready() -> void:
	_registra_tasti()

## La fazione che stai giocando davvero: se ti hanno deposto, giochi da ribelle.
func fazione_effettiva() -> int:
	return Faction.RIBELLE if deposta == fazione_giocatore else fazione_giocatore

func modifica(campo: String, delta: float) -> void:
	set(campo, clampf(get(campo) + delta, 0.0, 9999.0))
	cambiato.emit()

func costo_addestramento() -> float:
	return Balance.GUARDIA_ADDESTRAMENTO_COSTO * pow(2.0, addestramenti)

func cambia_fase(nuova: Fase) -> void:
	fase = nuova
	tempo_fase = 0.0
	if nuova == Fase.GIORNO:
		giorno += 1
		_alba()
	fase_cambiata.emit(nuova)
	cambiato.emit()

## L'alba e' il momento in cui la citta' fa i conti: incassa, mangia, e ridistribuisce
## il potere in base a chi ha effettivamente tenuto in piedi la baracca.
func _alba() -> void:
	denaro += popolazione * Balance.TASSE_PER_ABITANTE * (morale * Balance.TASSE_PESO_MORALE)

	var mangiato := popolazione * Balance.VIVERI_PER_ABITANTE
	if viveri >= mangiato:
		viveri -= mangiato
		morale = minf(morale + Balance.MORALE_RECUPERO_GIORNO, 100.0)
	else:
		viveri = 0.0
		morale = maxf(morale - Balance.FAME_MORALE, 0.0)
		perdi_abitanti(Balance.FAME_ABITANTI)
		annuncio.emit("LA CITTA' HA FAME", Color(1, 0.6, 0.3))

	_ridistribuisci_potere()
	_controlla_golpe()
	if giorno > Balance.GIORNI_PER_VINCERE and not finita:
		finita = true
		vinta = true

## Chi produce risultati guadagna consenso, e lo toglie agli altri.
## Quanto entrera' alla prossima alba, con i numeri di adesso.
func gettito_atteso() -> float:
	return popolazione * Balance.TASSE_PER_ABITANTE * (morale * Balance.TASSE_PESO_MORALE)


func _ridistribuisci_potere() -> void:
	potere[0] += (morale - 50.0) * Balance.POTERE_SPINTA_MORALE
	potere[1] += (denaro - 100.0) * Balance.POTERE_SPINTA_DENARO
	potere[2] += (sicurezza - 50.0) * Balance.POTERE_SPINTA_MURA
	normalizza_potere()

func normalizza_potere() -> void:
	var totale := 0.0
	for i in 3:
		potere[i] = maxf(potere[i], 1.0)
		totale += potere[i]
	for i in 3:
		potere[i] = potere[i] * 100.0 / totale

func sposta_potere(da: int, a: int, quanto: float) -> void:
	if da >= 0 and da < 3:
		potere[da] -= quanto
	if a >= 0 and a < 3:
		potere[a] += quanto
	normalizza_potere()
	cambiato.emit()

## Un leader che perde il potere non e' eliminato: passa dall'altra parte.
func _controlla_golpe() -> void:
	if deposta == -1:
		for f in 3:
			if potere[f] < Balance.POTERE_SOGLIA_GOLPE:
				deposta = f
				var chi := "SEI STATO DEPOSTO" if f == fazione_giocatore else "%s E' STATA DEPOSTA" % NOMI[f]
				annuncio.emit(chi, Color(1, 0.4, 0.4))
				return
	elif potere[deposta] >= Balance.POTERE_SOGLIA_RITORNO:
		# il ribelle si riprende il potere, e chi e' rimasto indietro finisce fuori
		var tornato := deposta
		var peggiore := 0
		for f in 3:
			if f != tornato and potere[f] < potere[peggiore]:
				peggiore = f
		deposta = peggiore
		annuncio.emit("%s TORNA AL POTERE" % NOMI[tornato], Color(0.5, 1, 0.6))

func perdi_abitanti(quanti: int) -> void:
	popolazione = maxi(popolazione - quanti, 0)
	morale = maxf(morale - quanti * Balance.MORALE_PER_ABITANTE_PERSO, 0.0)
	if popolazione == 0:
		finita = true
	cambiato.emit()

## Rimette tutto come all'inizio: l'autoload sopravvive al cambio scena, quindi
## senza questo la seconda partita partirebbe con lo stato della prima.
func ripristina() -> void:
	morale = Balance.MORALE_INIZIALE
	denaro = Balance.DENARO_INIZIALE
	viveri = Balance.VIVERI_INIZIALI
	sicurezza = 100.0
	popolazione = Balance.POPOLAZIONE_INIZIALE
	potere = [34.0, 33.0, 33.0]
	deposta = -1
	livello_guardie = 0
	addestramenti = 0
	fase = Fase.GIORNO
	giorno = 1
	tempo_fase = 0.0
	zombie_uccisi = 0
	finita = false
	vinta = false
	Spedizione.in_corso = 0

func _registra_tasti() -> void:
	var movimento := {"ui_up": KEY_W, "ui_down": KEY_S, "ui_left": KEY_A, "ui_right": KEY_D}
	for azione in movimento:
		var ev := InputEventKey.new()
		ev.physical_keycode = movimento[azione]
		InputMap.action_add_event(azione, ev)
	var extra := {"ripara": KEY_E, "costruisci": KEY_Q, "attacca": KEY_SPACE,
		"azione_1": KEY_1, "azione_2": KEY_2, "azione_3": KEY_3, "azione_4": KEY_4, "azione_5": KEY_5, "azione_6": KEY_6,
		"fazione_1": KEY_F1, "fazione_2": KEY_F2, "fazione_3": KEY_F3,
		"ricomincia": KEY_R, "manuale": KEY_H}
	for nome in extra:
		if not InputMap.has_action(nome):
			InputMap.add_action(nome)
		var ev2 := InputEventKey.new()
		ev2.physical_keycode = extra[nome]
		InputMap.action_add_event(nome, ev2)
