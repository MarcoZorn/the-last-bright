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

func _ready() -> void:
	var c: Vector2i = SPRITE_FAZIONE[fazione]
	$Sprite2D.region_rect = Rect2(c.x * Balance.TILE, c.y * Balance.TILE, Balance.TILE, Balance.TILE)

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * Balance.PLAYER_SPEED
	move_and_slide()
	if Input.is_action_just_pressed("ripara"):
		_ripara()
	if Input.is_action_just_pressed("costruisci"):
		_costruisci()

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
	g.global_position = mondo.centro(mondo.a_cella(global_position))
	guardie.add_child(g)
	GameState.modifica("denaro", -Balance.GUARDIA_COSTO)
