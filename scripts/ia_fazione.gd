extends Node
class_name IAFazione
## Guida una fazione che nessun umano sta giocando. Non e' furba: sceglie a caso
## fra le azioni che puo' permettersi. Serve a rendere la partita provabile da
## soli -- quando arriveranno tre giocatori veri, questi nodi si tolgono.

var fazione: int = 0
var _fra_mosse := 0.0

## Le fazioni in mano a una persona: da sola, la tua; in rete, quelle di tutti
## i peer collegati. L'IA riempie solo i posti vuoti.
func _fazioni_umane() -> Array:
	if Rete.in_rete:
		return Rete.fazioni.values()
	return [GameState.fazione_giocatore]

func _process(delta: float) -> void:
	if GameState.finita or GameState.fase != GameState.Fase.GIORNO:
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

## Non e' furba, ma non e' cieca: se c'e' un'emergenza evidente la guarda.
func _scelta(pronte: Array) -> Dictionary:
	var urgenti: Array = []
	if GameState.sicurezza < 60.0:
		urgenti = pronte.filter(func(a): return a["id"] in ["rinforza", "leva", "addestramento"])
	if urgenti.is_empty() and GameState.viveri < 80.0:
		urgenti = pronte.filter(func(a): return a["id"] in ["razionamento", "spedizione"])
	if urgenti.is_empty() and GameState.morale < 30.0:
		urgenti = pronte.filter(func(a): return a["id"] in ["predica", "processione"])
	return (urgenti if not urgenti.is_empty() else pronte).pick_random()
