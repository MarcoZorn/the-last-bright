extends SceneTree
## godot --headless --script res://tools/test_stipendi.gd
## Gli stipendi sono l'unico costo ricorrente del gioco: se sbagliano il conto,
## l'Esercito diventa gratis e tutta la tensione col Governo sparisce.

var GS: Node

func _process(_delta: float) -> bool:
	GS = root.get_node_or_null("GameState")
	if GS == null:
		print("!! autoload GameState non disponibile")
		return true

	_guarnigione(5)
	GS.denaro = 100.0
	GS._paga_stipendi()
	assert(is_equal_approx(GS.denaro, 100.0 - 5 * Balance.GUARDIA_STIPENDIO), "cinque guardie, cinque stipendi")
	assert(_quante() == 5, "se paghi non deserta nessuno")
	print("OK paga: 100 -> %.0f con 5 guardie" % GS.denaro)

	# casse quasi vuote: si tiene solo chi si puo' permettere
	GS.denaro = 2 * Balance.GUARDIA_STIPENDIO
	GS.morale = 50.0
	GS._paga_stipendi()
	assert(_quante() == 2, "devono restare solo le guardie pagabili, invece sono %d" % _quante())
	assert(GS.morale < 50.0, "una diserzione deve costare morale")
	print("OK diserzione: restano %d guardie, morale %.1f" % [_quante(), GS.morale])

	# nessuna guardia, nessun conto
	for g in root.get_tree().get_nodes_in_group("guardia"):
		g.queue_free()
	_svuota()
	GS.denaro = 50.0
	GS._paga_stipendi()
	assert(is_equal_approx(GS.denaro, 50.0), "senza guarnigione non si paga niente")
	print("OK nessuna guardia: casse intatte")
	return true

func _guarnigione(quante: int) -> void:
	_svuota()
	for i in quante:
		var n := Node2D.new()
		n.add_to_group("guardia")
		root.add_child(n)

func _svuota() -> void:
	for g in root.get_tree().get_nodes_in_group("guardia"):
		g.remove_from_group("guardia")
		g.free()

func _quante() -> int:
	var vive := 0
	for g in root.get_tree().get_nodes_in_group("guardia"):
		if is_instance_valid(g) and not g.is_queued_for_deletion():
			vive += 1
	return vive
