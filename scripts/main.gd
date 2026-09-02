extends Node2D
## Monta la scena e guida le ondate. Per ora single-player: controlli un solo
## leader e guardi la citta' reggere o cedere.

const PLAYER := preload("res://scenes/player.tscn")
const ZOMBIE := preload("res://scenes/zombie.tscn")

var mondo: World
var _zombie: Node2D

func _ready() -> void:
	mondo = preload("res://scripts/world.gd").new()
	add_child(mondo)

	_zombie = Node2D.new()
	add_child(_zombie)

	var p: Player = PLAYER.instantiate()
	p.global_position = mondo.piazza_centro()
	add_child(p)

	add_child(preload("res://scripts/hud.gd").new())

	var t := Timer.new()
	t.wait_time = Balance.ONDATA_INTERVALLO
	t.timeout.connect(_ondata)
	add_child(t)
	t.start()
	_ondata()

	if "--shot" in OS.get_cmdline_user_args():
		_scatta_panoramica()

func _ondata() -> void:
	if _zombie.get_child_count() >= Balance.ZOMBIE_MAX:
		return
	for cella in mondo.spawn_zombie:
		for i in Balance.ONDATA_QUANTITA:
			var z: Zombie = ZOMBIE.instantiate()
			z.mondo = mondo
			z.global_position = mondo.centro(cella) + Vector2(randf_range(-24, 24), randf_range(-16, 16))
			_zombie.add_child(z)

## Debug: `godot -- --shot` salva una panoramica della mappa e esce.
## Serve a verificare mappa e tile senza doverci giocare.
func _scatta_panoramica() -> void:
	var cam := Camera2D.new()
	cam.zoom = Vector2(0.82, 0.82)
	cam.global_position = mondo.centro(Vector2i(mondo.larghezza / 2, mondo.altezza / 2))
	add_child(cam)
	cam.make_current()
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/lastbright_shot.png")
	get_tree().quit()
