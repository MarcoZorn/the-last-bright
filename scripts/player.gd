extends CharacterBody2D
class_name Player
## Il leader di una fazione sulla mappa.
## is_multiplayer_authority() e' gia' qui apposta: quando aggiungeremo la rete
## questo file non cambia, cambia solo chi detiene l'autorita'.

## 0 Chiesa, 1 Governo, 2 Esercito
@export_enum("Chiesa", "Governo", "Esercito") var fazione: int = 0

const SPRITE_FAZIONE := [Vector2i(0, 7), Vector2i(4, 8), Vector2i(0, 8)]

func _ready() -> void:
	var s: Sprite2D = $Sprite2D
	var c: Vector2i = SPRITE_FAZIONE[fazione]
	s.region_rect = Rect2(c.x * Balance.TILE, c.y * Balance.TILE, Balance.TILE, Balance.TILE)

func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * Balance.PLAYER_SPEED
	move_and_slide()
