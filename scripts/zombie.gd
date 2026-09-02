extends CharacterBody2D
class_name Zombie
## Non insegue il giocatore: punta al cuore della citta'. Se esiste un percorso
## verso la piazza lo prende; se non esiste vuol dire che le barricate reggono,
## quindi va a picchiare quella piu' vicina. Appena una cade, tutti gli altri
## si accorgono da soli che c'e' una strada aperta: la pressione sulle difese
## emerge dalla mappa, non da codice che la simula.

var mondo: World

var _percorso: PackedVector2Array
var _bersaglio: Barricata
var _fra_ricalcoli := 0.0

func _ready() -> void:
	add_to_group("zombie")
	_fra_ricalcoli = randf() * Balance.PATH_REFRESH  # sfasa il costo su piu' frame

func _physics_process(delta: float) -> void:
	if mondo == null:
		return
	_fra_ricalcoli -= delta
	if _fra_ricalcoli <= 0.0:
		_fra_ricalcoli = Balance.PATH_REFRESH
		_ripianifica()

	if _bersaglio != null and _bersaglio.distanza(global_position) < Balance.TILE * 1.4:
		velocity = Vector2.ZERO
		_bersaglio.danneggia(Balance.BARRICATA_DANNO * delta)
	elif _percorso.size() > 1:
		var passo := _percorso[1]
		velocity = global_position.direction_to(passo) * Balance.ZOMBIE_SPEED
		if global_position.distance_to(passo) < 3.0:
			_percorso.remove_at(0)
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	if global_position.distance_to(mondo.piazza_centro()) < Balance.TILE * 3:
		_dilaga()

func _ripianifica() -> void:
	# ponytail: A* completo ogni 0.6s per zombie. Oltre ~150 zombie conviene un
	# flow-field unico condiviso, visto che l'obiettivo e' lo stesso per tutti.
	_percorso = mondo.percorso(global_position, mondo.piazza_centro())
	if not _percorso.is_empty():
		_bersaglio = null
		return
	_bersaglio = _barricata_piu_vicina()
	if _bersaglio != null:
		_percorso = mondo.percorso(global_position, _bersaglio.punto_approccio(global_position))

func _barricata_piu_vicina() -> Barricata:
	var migliore: Barricata = null
	var d_min := INF
	for b in get_tree().get_nodes_in_group("barricata"):
		if not b.in_piedi:
			continue
		var d: float = b.distanza(global_position)
		if d < d_min:
			d_min = d
			migliore = b
	return migliore

func _dilaga() -> void:
	GameState.perdi_abitanti(Balance.ABITANTI_PERSI_PER_ZOMBIE)
	queue_free()
