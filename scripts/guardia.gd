extends Node2D
class_name Guardia
## Posto di guardia dell'Esercito. Non si muove: e' denaro convertito in raggio
## di sicurezza. Piazzarne troppi svuota le casse del Governo -- ed e' il punto.

var _cooldown := 0.0
var _tiro: Line2D

func _ready() -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/kenney/tiny-dungeon/Tilemap/tilemap_packed.png")
	s.region_enabled = true
	s.region_rect = Rect2(0, 128, Balance.TILE, Balance.TILE)  # cavaliere
	add_child(s)
	_tiro = Line2D.new()
	_tiro.width = 1.0
	_tiro.default_color = Color(1, 0.9, 0.4)
	add_child(_tiro)

func _process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown < Balance.GUARDIA_CADENZA - 0.12:
		_tiro.clear_points()
	if _cooldown > 0.0:
		return
	var preda := _piu_vicino()
	if preda == null:
		return
	_cooldown = Balance.GUARDIA_CADENZA
	_tiro.clear_points()
	_tiro.add_point(Vector2.ZERO)
	_tiro.add_point(to_local(preda.global_position))
	GameState.zombie_uccisi += 1
	preda.queue_free()

func _piu_vicino() -> Node2D:
	var migliore: Node2D = null
	var d_min := Balance.GUARDIA_RAGGIO
	for z in get_tree().get_nodes_in_group("zombie"):
		var d := global_position.distance_to(z.global_position)
		if d < d_min:
			d_min = d
			migliore = z
	return migliore
