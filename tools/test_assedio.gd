extends Node
## godot --headless res://tools/test_assedio.tscn
## Verifica la meccanica su cui poggia tutto l'assedio: finche' le barricate
## reggono NON deve esistere una strada verso la piazza; quando cadono deve
## aprirsi da sola; riparandole deve richiudersi. Se questo si rompe, gli zombie
## smettono di assediare e il gioco sembra funzionare lo stesso.
## Gira come scena e non con --script, cosi' gli autoload ci sono davvero.

func _ready() -> void:
	var mondo: World = load("res://scripts/world.gd").new()
	add_child(mondo)
	var barricate: Array[Barricata] = []
	for gruppo in mondo.varchi:
		var b := Barricata.new()
		b.mondo = mondo
		b.celle.assign(gruppo)
		add_child(b)
		barricate.append(b)
	assert(barricate.size() == 5, "cinque varchi: il ponte e le quattro porte")

	var spawn: Vector2 = mondo.centro(mondo.spawn_zombie[0])
	var piazza: Vector2 = mondo.piazza_centro()

	assert(mondo.percorso(spawn, piazza).is_empty(), "barricate in piedi: non deve esistere un percorso")
	for b in barricate:
		b.subisci(Balance.BARRICATA_VITA)
	assert(not mondo.percorso(spawn, piazza).is_empty(), "barricate cadute: il percorso deve aprirsi")
	for b in barricate:
		b.ripara(Balance.BARRICATA_VITA)
	assert(mondo.percorso(spawn, piazza).is_empty(), "barricate riparate: il percorso deve richiudersi")

	# il riquadro delle mura decide chi si e' portato via un abitante all'alba:
	# se fosse degenere la notte tornerebbe gratis senza che nessuno se ne accorga
	print("   mura=%s  piazza=%s dentro=%s  spawn=%s dentro=%s" % [
		mondo.dentro_le_mura, piazza, mondo.dentro_le_mura.has_point(piazza),
		spawn, mondo.dentro_le_mura.has_point(spawn)])
	assert(mondo.dentro_le_mura.get_area() > 0.0, "il riquadro delle mura e' vuoto")
	assert(mondo.dentro_le_mura.has_point(piazza), "la piazza deve stare dentro le mura")
	assert(not mondo.dentro_le_mura.has_point(spawn), "lo spawn a nord deve stare fuori")
	print("OK mura")

	print("OK assedio: %d varchi chiudono, cadono e si richiudono" % barricate.size())
	get_tree().quit()
