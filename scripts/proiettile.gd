extends Node2D
class_name Proiettile
## Colpo di una guardia. Insegue il bersaglio invece di volare dritto: a questa
## scala un proiettile balistico manca troppo e sembra rotto.

var bersaglio: Node2D
var danno: float = Balance.PROIETTILE_DANNO[0]

func _ready() -> void:
	var c := ColorRect.new()
	c.color = Color(1.0, 0.92, 0.55)
	c.size = Vector2(3, 3)
	c.position = Vector2(-1.5, -1.5)
	add_child(c)

func _process(delta: float) -> void:
	if not is_instance_valid(bersaglio):
		queue_free()
		return
	var verso := global_position.direction_to(bersaglio.global_position)
	global_position += verso * Balance.PROIETTILE_VELOCITA * delta
	if global_position.distance_to(bersaglio.global_position) < 5.0:
		bersaglio.subisci(danno, verso)
		queue_free()
