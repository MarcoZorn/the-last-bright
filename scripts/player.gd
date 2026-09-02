extends CharacterBody2D
class_name Player
## Il leader di una fazione sulla mappa.
## is_multiplayer_authority() e' gia' qui apposta: quando aggiungeremo la rete
## questo file non cambia, cambia solo chi detiene l'autorita'.

## 0 Chiesa, 1 Governo, 2 Esercito
@export_enum("Chiesa", "Governo", "Esercito") var fazione: int = 0

const SPRITE_FAZIONE := [Vector2i(0, 7), Vector2i(4, 8), Vector2i(0, 8)]
const PORTATA_RIPARAZIONE := Balance.TILE * 2.5

var mondo: World
var guardie: Node2D
var vita: float = Balance.PLAYER_VITA
var a_terra := false

var _direzione := Vector2.DOWN
var _cooldown := 0.0
var _rialzo := 0.0

func _ready() -> void:
	add_to_group("player")
	add_to_group("danneggiabile")
	var c: Vector2i = SPRITE_FAZIONE[fazione]
	$Sprite2D.region_rect = Rect2(c.x * Balance.TILE, c.y * Balance.TILE, Balance.TILE, Balance.TILE)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if a_terra:
		_rialzo -= delta
		if _rialzo <= 0.0:
			_rialzati()
		return

	_cooldown -= delta
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		_direzione = dir
	velocity = dir * Balance.PLAYER_SPEED
	move_and_slide()

	if Input.is_action_pressed("attacca") and _cooldown <= 0.0:
		_attacca()
	if Input.is_action_just_pressed("ripara"):
		_ripara()
	if Input.is_action_just_pressed("costruisci"):
		_costruisci()

## Fendente frontale: colpisce tutto quello che hai davanti entro il raggio.
## Un leader non e' un soldato -- serve a toglierti dai guai, non a reggere
## un'ondata da solo. Per quello ci sono i posti di guardia.
func _attacca() -> void:
	_cooldown = Balance.ATTACCO_CADENZA
	_mostra_fendente()
	for z in get_tree().get_nodes_in_group("zombie"):
		if global_position.distance_to(z.global_position) > Balance.ATTACCO_RAGGIO:
			continue
		if _direzione.normalized().dot(global_position.direction_to(z.global_position)) < 0.15:
			continue
		z.subisci(Balance.ATTACCO_DANNO, global_position.direction_to(z.global_position))

func attaccabile() -> bool:
	return not a_terra

func distanza(p: Vector2) -> float:
	return global_position.distance_to(p)

func subisci(quanto: float, _spinta := Vector2.ZERO) -> void:
	if a_terra:
		return
	vita -= quanto
	if vita <= 0.0:
		_cadi()

func _cadi() -> void:
	a_terra = true
	vita = 0.0
	_rialzo = Balance.RIANIMAZIONE
	rotation = PI * 0.5
	modulate = Color(0.55, 0.55, 0.6)
	# un leader non viene eliminato: viene trascinato via. Ma la citta' lo vede.
	GameState.modifica("morale", -Balance.MORALE_PER_CADUTA)

func _rialzati() -> void:
	a_terra = false
	vita = Balance.PLAYER_VITA
	rotation = 0.0
	modulate = Color.WHITE
	if mondo != null:
		global_position = mondo.piazza_centro()

func _mostra_fendente() -> void:
	var arco := Line2D.new()
	arco.width = 2.5
	arco.default_color = Color(1.0, 0.98, 0.8)
	var base := _direzione.angle()
	for i in 9:
		arco.add_point(Vector2.RIGHT.rotated(base - 0.6 + i * 0.15) * Balance.ATTACCO_RAGGIO * 0.8)
	add_child(arco)
	var t := create_tween()
	t.tween_property(arco, "modulate:a", 0.0, 0.22)
	t.tween_callback(arco.queue_free)

func _ripara() -> void:
	if GameState.denaro < Balance.RIPARA_COSTO:
		return
	for b in get_tree().get_nodes_in_group("barricata"):
		if b.distanza(global_position) < PORTATA_RIPARAZIONE and b.vita < Balance.BARRICATA_VITA:
			b.ripara(Balance.RIPARA_QUANTITA)
			GameState.modifica("denaro", -Balance.RIPARA_COSTO)
			return

func _costruisci() -> void:
	if GameState.denaro < Balance.GUARDIA_COSTO or mondo == null:
		return
	if mondo.bloccato(mondo.a_cella(global_position)):
		return
	var g := Guardia.new()
	g.mondo = mondo
	g.global_position = mondo.centro(mondo.a_cella(global_position))
	guardie.add_child(g)
	GameState.modifica("denaro", -Balance.GUARDIA_COSTO)
