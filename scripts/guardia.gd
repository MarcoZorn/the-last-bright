extends CharacterBody2D
class_name Guardia
## La guardia dell'Esercito. Non e' una torretta: la selezioni col tasto
## sinistro e la mandi dove serve col destro. Se la lasci scoperta muore.

var mondo: World
var vita: float = Balance.GUARDIA_VITA
var selezionata := false:
	set(v):
		selezionata = v
		_anello.visible = v

var _percorso: PackedVector2Array
var _cooldown := 0.0
var _barra: BarraVita
var _anello := Line2D.new()

func _ready() -> void:
	add_to_group("guardia")
	add_to_group("danneggiabile")
	collision_layer = 2
	collision_mask = 1

	var s := Sprite2D.new()
	s.texture = load("res://assets/kenney/tiny-dungeon/Tilemap/tilemap_packed.png")
	s.region_enabled = true
	s.region_rect = Rect2(0, 128, Balance.TILE, Balance.TILE)  # cavaliere
	add_child(s)

	var forma := CircleShape2D.new()
	forma.radius = 5.0
	var cs := CollisionShape2D.new()
	cs.shape = forma
	add_child(cs)

	_anello.width = 1.0
	_anello.default_color = Color(1.0, 0.95, 0.4)
	for i in 17:
		_anello.add_point(Vector2.RIGHT.rotated(TAU * i / 16.0) * 9.0)
	_anello.visible = false
	add_child(_anello)

	_barra = BarraVita.new(20.0, 12.0)
	add_child(_barra)
	_barra.aggiorna(1.0)

func attaccabile() -> bool:
	return vita > 0.0

func distanza(p: Vector2) -> float:
	return global_position.distance_to(p)

func vai_a(punto: Vector2) -> void:
	if mondo != null:
		_percorso = mondo.percorso(global_position, punto)

func subisci(danno: float, _spinta := Vector2.ZERO) -> void:
	vita -= danno
	_barra.aggiorna(vita / Balance.GUARDIA_VITA)
	if vita <= 0.0:
		queue_free()

func _physics_process(delta: float) -> void:
	if _percorso.size() > 1:
		var passo := _percorso[1]
		velocity = global_position.direction_to(passo) * Balance.GUARDIA_VELOCITA
		if global_position.distance_to(passo) < 3.0:
			_percorso.remove_at(0)
	else:
		velocity = Vector2.ZERO
		_percorso.clear()
	move_and_slide()

	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var preda := _piu_vicino()
	if preda == null:
		return
	_cooldown = Balance.GUARDIA_CADENZA
	var p := Proiettile.new()
	p.bersaglio = preda
	p.global_position = global_position
	get_parent().add_child(p)

func _piu_vicino() -> Node2D:
	var migliore: Node2D = null
	var d_min := Balance.GUARDIA_RAGGIO
	for z in get_tree().get_nodes_in_group("zombie"):
		var d := global_position.distance_to(z.global_position)
		if d < d_min:
			d_min = d
			migliore = z
	return migliore
