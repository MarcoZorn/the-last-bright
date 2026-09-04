extends Node
## godot --headless res://tools/test_guardia.tscn
## Il test piu' piccolo che dice se le difese funzionano: una guardia, uno
## zombie a tiro, e dopo qualche secondo lo zombie deve essere morto.
## Cinque simulazioni di fila hanno detto "0% ammazzati" senza spiegare perche':
## questo lo isola.

const SCENA_ZOMBIE := preload("res://scenes/zombie.tscn")

var mondo: World
var guardia: Guardia
var zombie: Zombie
var _passato := 0.0

func _ready() -> void:
	mondo = load("res://scripts/world.gd").new()
	add_child(mondo)
	var contenitore := Node2D.new()
	add_child(contenitore)

	guardia = load("res://scenes/guardia.tscn").instantiate()
	guardia.mondo = mondo
	guardia.position = mondo.piazza_centro()
	contenitore.add_child(guardia)

	# la barricata deve esistere, altrimenti il presidio non ha dove andare
	for gruppo in mondo.varchi:
		var b := Barricata.new()
		b.mondo = mondo
		b.celle.assign(gruppo)
		add_child(b)

	# lo zombie NON e' a tiro: sta a un varco, come nella partita vera.
	# La guardia deve arrivarci da sola.
	var varco: Barricata = get_tree().get_nodes_in_group("barricata")[0]
	zombie = SCENA_ZOMBIE.instantiate()
	zombie.mondo = mondo
	zombie.position = varco.centro_varco() + Vector2(0, -22)
	contenitore.add_child(zombie)

	print("   guardia in piazza, zombie a un varco a %.0f px. Raggio %.0f." % [
		guardia.position.distance_to(zombie.position), Balance.GUARDIA_RAGGIO[0]])

var _prossimo_avviso := 5.0

func _physics_process(delta: float) -> void:
	_passato += delta
	if _passato > _prossimo_avviso and is_instance_valid(zombie):
		_prossimo_avviso += 5.0
		print("   %2.0fs: guardia a %.0f px dallo zombie, vita zombie %.1f" % [
			_passato, guardia.position.distance_to(zombie.position), zombie.vita])
	if _passato < 30.0:
		return
	var vivo := is_instance_valid(zombie) and not zombie.is_queued_for_deletion()
	print("   dopo 30s: zombie %s | uccisi %d | vita residua %.1f" % [
		"VIVO" if vivo else "morto", GameState.zombie_uccisi,
		zombie.vita if is_instance_valid(zombie) else 0.0])
	assert(GameState.zombie_uccisi > 0, "una guardia deve raggiungere il varco e ammazzare lo zombie in trenta secondi")
	print("OK guardia: raggiunge il varco e uccide")
	get_tree().quit()
