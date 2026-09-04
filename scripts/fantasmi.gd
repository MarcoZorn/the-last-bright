extends Node2D
class_name Fantasmi
## Disegna zombie e guardie che vivono sul computer di chi ospita.
## Su un client non esistono come entita': sono posizioni che arrivano dalla
## rete. Un pozzo di sprite riusati, invece di creare e distruggere nodi dieci
## volte al secondo.

const FOGLIO := preload("res://assets/sprites.png")

var _zombie: Array[Sprite2D] = []
var _guardie: Array[Sprite2D] = []

func aggiorna(posizioni_zombie: Array, posizioni_guardie: Array) -> void:
	_sistema(_zombie, posizioni_zombie.size() / 2, 4)
	for i in _zombie.size():
		var s := _zombie[i]
		var attivo: bool = i * 2 + 1 < posizioni_zombie.size()
		s.visible = attivo
		if attivo:
			# interpolazione: a ~8 pacchetti al secondo, saltare da un punto
			# all'altro si vede tutto
			var meta := Vector2(posizioni_zombie[i * 2], posizioni_zombie[i * 2 + 1])
			s.position = meta if s.position == Vector2.ZERO else s.position.lerp(meta, 0.35)
	_sistema(_guardie, posizioni_guardie.size(), 3)
	for i in _guardie.size():
		var s := _guardie[i]
		var attivo: bool = i < posizioni_guardie.size()
		s.visible = attivo
		if attivo:
			var meta := Vector2(posizioni_guardie[i][0], posizioni_guardie[i][1])
			s.position = meta if s.position == Vector2.ZERO else s.position.lerp(meta, 0.35)

func _sistema(pozzo: Array[Sprite2D], quanti: int, colonna: int) -> void:
	while pozzo.size() < quanti:
		var s := Sprite2D.new()
		s.texture = FOGLIO
		s.region_enabled = true
		var c: int = colonna if colonna == 3 else colonna + (pozzo.size() % 3)
		s.region_rect = Rect2(c * Balance.TILE, 0, Balance.TILE, Balance.TILE)
		add_child(s)
		pozzo.append(s)
