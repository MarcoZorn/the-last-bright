extends Node
## godot --headless res://tools/test_tutorial.tscn
## Ogni passo del tutorial che chiede di fare qualcosa deve essere davvero
## possibile nel momento in cui lo chiede. Il primo giro chiedeva di riparare
## una barricata quando erano tutte intere: il tutorial restava bloccato li'.

var _partita: Node
var _tut: Node
var _passo := 0
var _pronto := false

func _ready() -> void:
	GameState.ripristina()
	GameState.tutorial = true
	GameState.tutorial_notte = false
	GameState.fazione_giocatore = 0
	_partita = load("res://scenes/main.tscn").instantiate()
	add_child(_partita)

func _process(_d: float) -> void:
	if not _pronto:
		for n in _partita.get_children():
			if n.get_script() != null and str(n.get_script().resource_path).ends_with("tutorial.gd"):
				_tut = n
		if _tut == null or _tut._passi.is_empty():
			return
		_pronto = true
		print("   passi nel tutorial: %d" % _tut._passi.size())

	if _passo >= _tut._passi.size():
		print("OK tutorial: ogni passo che chiede qualcosa e' completabile")
		get_tree().quit()
		return

	var p: Dictionary = _tut._passi[_passo]
	if p.has("inizia"):
		p["inizia"].call()
	if p.has("fatto"):
		_verifica(_passo, p)
	_passo += 1

## Non simuliamo il giocatore: controlliamo che il mondo gli permetta di agire.
func _verifica(n: int, p: Dictionary) -> void:
	var testo: String = p["t"]
	if testo.begins_with("MUOVITI"):
		assert(get_tree().get_first_node_in_group("mio") != null, "passo %d: non c'e' un leader da muovere" % n)
	elif testo.begins_with("RIPARA"):
		var riparabili := get_tree().get_nodes_in_group("barricata").filter(
			func(b): return b.in_piedi and b.vita < Balance.BARRICATA_VITA)
		assert(not riparabili.is_empty(), "passo %d: nessuna barricata da riparare" % n)
		assert(GameState.denaro >= Balance.RIPARA_COSTO, "passo %d: non bastano i soldi per riparare" % n)
		print("   ripara: %d barricate danneggiate, %.0f in cassa" % [riparabili.size(), GameState.denaro])
	elif testo.begins_with("RECLUTA"):
		assert(GameState.denaro >= Balance.GUARDIA_COSTO, "passo %d: non bastano i soldi per reclutare" % n)
		print("   recluta: %.0f in cassa, ne servono %.0f" % [GameState.denaro, Balance.GUARDIA_COSTO])
	elif testo.begins_with("USA UN'AZIONE"):
		var mia := GameState.fazione_effettiva()
		var pronte := Azioni.istanza.per_fazione(mia).filter(
			func(a): return Azioni.istanza.eseguibile(a["id"], mia))
		assert(not pronte.is_empty(), "passo %d: nessuna azione eseguibile" % n)
		print("   azioni: %d disponibili" % pronte.size())
	elif testo.begins_with("Adesso arriva la notte"):
		var zombi := get_tree().get_nodes_in_group("zombie").size()
		assert(zombi > 0, "passo %d: non c'e' nessuno zombie da ammazzare" % n)
		print("   notte: %d zombie in campo" % zombi)
