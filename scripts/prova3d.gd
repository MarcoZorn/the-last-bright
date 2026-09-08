extends Node3D
## Scena di prova del 3D: monta il blockout e ti ci mette dentro.
## `godot --path . res://scenes3d/prova.tscn`

func _ready() -> void:
	var mondo := Mondo3D.new()
	add_child(mondo)
	await get_tree().process_frame
	var p := Player3D.new()
	p.position = mondo.centro_mondo() + Vector3(0, 2, 0)
	add_child(p)

	var aiuto := Label.new()
	aiuto.text = "WASD muovi   mouse guarda   SHIFT corri   ESC libera il mouse"
	aiuto.position = Vector2(14, 14)
	var strato := CanvasLayer.new()
	strato.add_child(aiuto)
	add_child(strato)

	if "--dallalto" in OS.get_cmdline_user_args():
		# camera fissa a volo d'uccello: se qui la citta' non si vede, il problema
		# non e' l'inquadratura del giocatore ma la geometria
		var occhio := Camera3D.new()
		occhio.far = 2000.0
		add_child(occhio)
		# look_at va chiamato DOPO l'ingresso nell'albero: prima lavora su una
		# trasformata globale che non esiste ancora e non ha alcun effetto
		occhio.position = mondo.centro_mondo() + Vector3(0, 190, 190)
		occhio.look_at(mondo.centro_mondo(), Vector3.UP)
		occhio.current = true
		await get_tree().create_timer(2.0).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/tlb3d.png")
		get_tree().quit()
		return

	if "--terra" in OS.get_cmdline_user_args():
		# camera semplice a livello d'uomo, senza braccio elastico: isola se il
		# problema e' il braccio o la scena
		p.position = mondo.centro_mondo() + Vector3(0, 1, 40)
		var occhio := Camera3D.new()
		occhio.far = 900.0
		add_child(occhio)
		occhio.position = mondo.centro_mondo() + Vector3(0, 6, 52)
		occhio.look_at(mondo.centro_mondo() + Vector3(0, 3, 0), Vector3.UP)
		occhio.current = true
		await get_tree().create_timer(2.0).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/tlb3d.png")
		get_tree().quit()
		return

	if "--shot3d" in OS.get_cmdline_user_args():
		# una posa che inquadri la piazza, non i piedi del personaggio
		p.position = mondo.centro_mondo() + Vector3(0, 2, 34)
		p._giro = PI
		p._inclinazione = -0.30
		await get_tree().create_timer(2.5).timeout
		get_viewport().get_texture().get_image().save_png("/tmp/tlb3d.png")
		get_tree().quit()
