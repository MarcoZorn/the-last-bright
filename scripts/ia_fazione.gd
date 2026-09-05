extends Node
class_name IAFazione
## Guida una fazione che nessun umano sta giocando. Non e' furba: sceglie a caso
## fra le azioni che puo' permettersi. Serve a rendere la partita provabile da
## soli -- quando arriveranno tre giocatori veri, questi nodi si tolgono.

const GUARNIGIONE_MINIMA := 6

var fazione: int = 0
var _fra_mosse := 0.0

## Le fazioni in mano a una persona: da sola, la tua; in rete, quelle di tutti
## i peer collegati. L'IA riempie solo i posti vuoti.
func _fazioni_umane() -> Array:
	if Rete.in_rete:
		return Rete.fazioni.values()
	return [GameState.fazione_giocatore]

func _process(delta: float) -> void:
	if GameState.finita or GameState.tutorial or GameState.fase != GameState.Fase.GIORNO:
		return
	if not Rete.e_il_server():
		return          # in rete decide il server, altrimenti si accavallano
	if not GameState.senza_umano and fazione in _fazioni_umane():
		return
	_fra_mosse -= delta
	if _fra_mosse > 0.0:
		return
	_fra_mosse = randf_range(2.5, 5.0)
	var mia := GameState.Faction.RIBELLE if GameState.deposta == fazione else fazione
	var pronte := Azioni.istanza.per_fazione(mia).filter(
		func(a): return Azioni.istanza.eseguibile(a["id"], mia))
	if pronte.is_empty():
		return
	Azioni.istanza.esegui(_scelta(pronte)["id"], mia)

## Non e' furba, ma non e' cieca: guarda le emergenze in ordine di gravita'.
## L'ordine conta: prima che l'IA lo avesse, in tre partite simulate su cinque
## non reclutava una sola guardia e la citta' si difendeva da sola con le mura.
func _scelta(pronte: Array) -> Dictionary:
	var urgenti: Array = []

	# senza una guarnigione le mura si riparano all'infinito e non serve a niente
	if _guardie() < GUARNIGIONE_MINIMA:
		urgenti = pronte.filter(func(a): return a["id"] == "leva")
	if urgenti.is_empty() and GameState.viveri < 100.0:
		urgenti = pronte.filter(func(a): return a["id"] in ["razionamento", "spedizione"])
	if urgenti.is_empty() and GameState.sicurezza < 55.0:
		urgenti = pronte.filter(func(a): return a["id"] in ["rinforza", "leva"])
	if urgenti.is_empty() and GameState.morale < 35.0:
		urgenti = pronte.filter(func(a): return a["id"] in ["predica", "processione"])
	if urgenti.is_empty() and _guardie() >= GUARNIGIONE_MINIMA and GameState.denaro > 150.0:
		urgenti = pronte.filter(func(a): return a["id"] == "addestramento")
	return (urgenti if not urgenti.is_empty() else pronte).pick_random()

func _guardie() -> int:
	return get_tree().get_nodes_in_group("guardia").size()
