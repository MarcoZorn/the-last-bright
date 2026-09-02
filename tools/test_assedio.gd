extends SceneTree
## godot --headless --script res://tools/test_assedio.gd
## Verifica la meccanica su cui poggia tutto l'assedio: finche' le barricate
## reggono NON deve esistere una strada verso la piazza; quando cadono deve
## aprirsi da sola; riparandole deve richiudersi. Se questo si rompe, gli zombie
## smettono di assediare e il gioco sembra funzionare lo stesso.

## Il test gira al primo frame, non in _initialize: prima che il main loop
## parta i nodi aggiunti non ricevono _ready.
func _process(_delta: float) -> bool:
	var mondo: World = load("res://scripts/world.gd").new()
	root.add_child(mondo)
	var barricate: Array[Barricata] = []
	for gruppo in mondo.varchi:
		var b := Barricata.new()
		b.mondo = mondo
		b.celle.assign(gruppo)
		root.add_child(b)
		barricate.append(b)
	print("varchi: %d" % barricate.size())

	var spawn: Vector2 = mondo.centro(mondo.spawn_zombie[0])
	var piazza: Vector2 = mondo.piazza_centro()

	assert(mondo.percorso(spawn, piazza).is_empty(), "barricate in piedi: non deve esistere un percorso")
	for b in barricate:
		b.danneggia(Balance.BARRICATA_VITA)
	assert(not mondo.percorso(spawn, piazza).is_empty(), "barricate cadute: il percorso deve aprirsi")
	for b in barricate:
		b.ripara(Balance.BARRICATA_VITA)
	assert(mondo.percorso(spawn, piazza).is_empty(), "barricate riparate: il percorso deve richiudersi")

	print("OK assedio")
	return true
