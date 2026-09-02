extends CharacterBody2D
class_name Zombie
## Non insegue il giocatore: punta al cuore della citta'. Il pathfinding passa
## per forza dal ponte e dalle porte, perche' sono gli unici varchi nella
## griglia -- la pressione sulle difese emerge dalla mappa, non da codice.

var mondo: World
var vita: int = Balance.ZOMBIE_HP

var _percorso: PackedVector2Array
var _fra_ricalcoli := 0.0

func _ready() -> void:
	_fra_ricalcoli = randf() * Balance.PATH_REFRESH  # sfasa il costo su piu' frame

func _physics_process(delta: float) -> void:
	if mondo == null:
		return
	_fra_ricalcoli -= delta
	if _fra_ricalcoli <= 0.0:
		_fra_ricalcoli = Balance.PATH_REFRESH
		# ponytail: A* completo ogni 0.6s per zombie. Con >150 zombie passare a
		# un flow-field unico condiviso (l'obiettivo e' lo stesso per tutti).
		_percorso = mondo.percorso(global_position, mondo.piazza_centro())

	if _percorso.size() > 1:
		var passo := _percorso[1]
		velocity = global_position.direction_to(passo) * Balance.ZOMBIE_SPEED
		if global_position.distance_to(passo) < 3.0:
			_percorso.remove_at(0)
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	if global_position.distance_to(mondo.piazza_centro()) < Balance.TILE * 3:
		_sfonda()

## Uno zombie arrivato in piazza e' una falla nelle difese, non un nemico da menare.
func _sfonda() -> void:
	GameState.modifica("sicurezza", -Balance.ZOMBIE_DANNO_MURA)
	GameState.modifica("morale", -Balance.ZOMBIE_DANNO_MURA * 0.5)
	queue_free()
