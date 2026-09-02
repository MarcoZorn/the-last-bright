extends Node2D
class_name BarraVita
## Barra di vita riutilizzabile: la usano barricate, guardie ed edifici.
## Un solo posto da sistemare quando vorremo che sia piu' bella.

var _sfondo := ColorRect.new()
var _pieno := ColorRect.new()
var _larghezza := 30.0

func _init(larghezza: float = 30.0, sopra: float = 14.0) -> void:
	_larghezza = larghezza
	position = Vector2(-larghezza * 0.5, -sopra)

func _ready() -> void:
	_sfondo.color = Color(0, 0, 0, 0.6)
	_sfondo.size = Vector2(_larghezza, 4)
	add_child(_sfondo)
	_pieno.size = Vector2(_larghezza - 2, 2)
	_pieno.position = Vector2(1, 1)
	add_child(_pieno)

func aggiorna(quota: float) -> void:
	quota = clampf(quota, 0.0, 1.0)
	_pieno.size.x = (_larghezza - 2) * quota
	_pieno.color = Color(1.0 - quota * 0.85, 0.2 + 0.65 * quota, 0.2)
