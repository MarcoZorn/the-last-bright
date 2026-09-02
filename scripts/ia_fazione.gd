extends Node
class_name IAFazione
## Guida una fazione che nessun umano sta giocando. Non e' furba: sceglie a caso
## fra le azioni che puo' permettersi. Serve a rendere la partita provabile da
## soli -- quando arriveranno tre giocatori veri, questi nodi si tolgono.

var fazione: int = 0
var _fra_mosse := 0.0

func _process(delta: float) -> void:
	if GameState.finita or GameState.fase != GameState.Fase.GIORNO:
		return
	if fazione == GameState.fazione_giocatore:
		return
	_fra_mosse -= delta
	if _fra_mosse > 0.0:
		return
	_fra_mosse = randf_range(2.5, 5.0)
	var mia := GameState.Faction.RIBELLE if GameState.deposta == fazione else fazione
	var pronte := Azioni.istanza.per_fazione(mia).filter(func(a): return Azioni.istanza.eseguibile(a["id"]))
	if not pronte.is_empty():
		Azioni.istanza.esegui(pronte.pick_random()["id"])
