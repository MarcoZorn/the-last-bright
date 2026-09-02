extends CharacterBody2D
class_name Guardia
## La guardia dell'Esercito. Non e' una torretta: la selezioni col tasto
## sinistro e la mandi dove serve col destro. Parte come recluta scarsa e
## migliora solo se l'Esercito paga l'addestramento -- e i soldi sono del Governo.

var mondo: World
var vita: float
var selezionata := false:
	set(v):
		selezionata = v
		if _anello != null:
			_anello.visible = v

var _percorso: PackedVector2Array
var _cooldown := 0.0
var _barra: BarraVita
var _anello := Line2D.new()
var _livello_visto := -1
var _sprite: Sprite2D
var _meta_diretta := Vector2.INF
var _tempo := 0.0

func _ready() -> void:
	add_to_group("guardia")
	add_to_group("danneggiabile")
	collision_layer = 2
	collision_mask = 1

	_sprite = Sprite2D.new()
	var s := _sprite
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

	Grafica.ombra(self, 5.0)
	_barra = BarraVita.new(20.0, 12.0)
	add_child(_barra)
	vita = vita_max()
	_livello_visto = GameState.livello_guardie
	_barra.aggiorna(1.0)

func vita_max() -> float:
	return Balance.GUARDIA_VITA[GameState.livello_guardie]

func attaccabile() -> bool:
	return vita > 0.0

func distanza(p: Vector2) -> float:
	return global_position.distance_to(p)

## Se A* non trova strada e' quasi sempre perche' il varco e' chiuso: le guardie
## ci passano lo stesso, quindi si va in linea retta e ci pensa la fisica.
func vai_a(punto: Vector2) -> void:
	if mondo == null:
		return
	_percorso = mondo.percorso(global_position, punto)
	_meta_diretta = punto if _percorso.is_empty() else Vector2.INF

func subisci(danno: float, _spinta := Vector2.ZERO) -> void:
	vita -= danno
	_barra.aggiorna(vita / vita_max())
	if vita <= 0.0:
		Grafica.schizzo(get_parent(), global_position, Color(0.9, 0.3, 0.3), 9)
		queue_free()

func _physics_process(delta: float) -> void:
	# un addestramento nuovo rimette in sesto anche chi e' gia' in servizio
	if _livello_visto != GameState.livello_guardie:
		_livello_visto = GameState.livello_guardie
		vita = vita_max()
		_barra.aggiorna(1.0)

	if _percorso.size() > 1:
		var passo := _percorso[1]
		velocity = global_position.direction_to(passo) * Balance.GUARDIA_VELOCITA
		if global_position.distance_to(passo) < 3.0:
			_percorso.remove_at(0)
	elif _meta_diretta != Vector2.INF:
		velocity = global_position.direction_to(_meta_diretta) * Balance.GUARDIA_VELOCITA
		if global_position.distance_to(_meta_diretta) < 6.0:
			_meta_diretta = Vector2.INF
	else:
		velocity = Vector2.ZERO
		_percorso.clear()
	move_and_slide()
	_tempo += delta
	Grafica.passo(_sprite, velocity, _tempo)

	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var preda := _piu_vicino()
	if preda == null:
		return
	_cooldown = Balance.GUARDIA_CADENZA[GameState.livello_guardie]
	var p := Proiettile.new()
	p.bersaglio = preda
	p.danno = Balance.PROIETTILE_DANNO[GameState.livello_guardie]
	p.global_position = global_position
	get_parent().add_child(p)

func _piu_vicino() -> Node2D:
	var migliore: Node2D = null
	var d_min: float = Balance.GUARDIA_RAGGIO[GameState.livello_guardie]
	for z in get_tree().get_nodes_in_group("zombie"):
		var d := global_position.distance_to(z.global_position)
		if d < d_min:
			d_min = d
			migliore = z
	return migliore
