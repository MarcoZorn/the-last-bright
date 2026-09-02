extends CharacterBody2D
class_name Zombie
## Non insegue il giocatore: punta all'edificio che gli e' stato assegnato.
## Se esiste un percorso lo prende; se non esiste vuol dire che qualcosa lo
## blocca, quindi va a picchiare la barricata piu' vicina. Appena una cade,
## tutti gli altri si accorgono da soli che c'e' una strada aperta: l'assedio
## emerge dalla mappa, non da codice che lo simula.

var mondo: World
var vita: float
var vita_max: float
var velocita: float
var edificio_bersaglio: Edificio

var _percorso: PackedVector2Array
var _barricata: Barricata
var _fra_ricalcoli := 0.0
var _spinta := Vector2.ZERO
var _tempo := 0.0

var _barra: BarraVita

func _ready() -> void:
	add_to_group("zombie")
	_fra_ricalcoli = randf() * Balance.PATH_REFRESH  # sfasa il costo su piu' frame
	# ogni notte quelli che arrivano sono piu' duri di quelli di ieri
	vita_max = Balance.zombie_vita(GameState.giorno)
	vita = vita_max
	velocita = Balance.zombie_velocita(GameState.giorno)
	Grafica.ombra(self, 4.5)
	# ogni zombie e' un po' diverso dagli altri: senza, l'ondata sembra un plotone
	var sprite: Sprite2D = $Sprite2D
	sprite.modulate = Color(randf_range(0.5, 0.75), randf_range(0.85, 1.0), randf_range(0.5, 0.7))
	scale = Vector2.ONE * randf_range(0.88, 1.12)
	velocita *= randf_range(0.9, 1.1)
	_barra = BarraVita.new(12.0, 10.0)
	add_child(_barra)
	_barra.visible = false

func _physics_process(delta: float) -> void:
	if mondo == null:
		return
	_fra_ricalcoli -= delta
	if _fra_ricalcoli <= 0.0:
		_fra_ricalcoli = Balance.PATH_REFRESH
		_ripianifica()

	var preda := _preda_a_portata()
	if preda != null:
		velocity = Vector2.ZERO
		preda.subisci(_danno_contro(preda) * delta)
	elif _percorso.size() > 1:
		var passo := _percorso[1]
		velocity = global_position.direction_to(passo) * velocita
		if global_position.distance_to(passo) < 3.0:
			_percorso.remove_at(0)
	else:
		velocity = Vector2.ZERO

	velocity += _spinta
	_spinta = _spinta.lerp(Vector2.ZERO, minf(delta * 8.0, 1.0))
	move_and_slide()
	_tempo += delta
	Grafica.passo($Sprite2D, velocity, _tempo)

## Mordono qualunque cosa gli capiti a tiro: muri, guardie, leader, edifici.
func _preda_a_portata() -> Node2D:
	var migliore: Node2D = null
	var d_min := Balance.TILE * 1.4
	for n in get_tree().get_nodes_in_group("danneggiabile"):
		if not n.attaccabile():
			continue
		var d: float = n.distanza(global_position)
		if d < d_min:
			d_min = d
			migliore = n
	return migliore

func _danno_contro(preda: Node2D) -> float:
	if preda is Player:
		return Balance.zombie_danno(GameState.giorno)
	if preda is Guardia:
		return Balance.zombie_danno_guardia(GameState.giorno)
	return Balance.morso_mura(GameState.giorno)

func _ripianifica() -> void:
	# ponytail: A* completo ogni 0.6s per zombie. Oltre ~150 zombie conviene un
	# flow-field unico condiviso, visto che gli obiettivi sono solo tre.
	var meta: Vector2 = mondo.piazza_centro()
	if edificio_bersaglio != null and edificio_bersaglio.in_piedi:
		meta = edificio_bersaglio.punto_approccio(global_position)
	_percorso = mondo.percorso(global_position, meta)
	if not _percorso.is_empty():
		_barricata = null
		return
	_barricata = _barricata_piu_vicina()
	if _barricata != null:
		_percorso = mondo.percorso(global_position, _barricata.punto_approccio(global_position))

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

func subisci(danno: float, spinta := Vector2.ZERO) -> void:
	if vita <= 0.0:
		return
	vita -= danno
	_barra.visible = true
	_barra.aggiorna(vita / vita_max)
	_spinta = spinta.normalized() * Balance.SPINTA_COLPO
	DannoFluttuante.mostra(get_parent(), global_position, str(ceili(danno)), Color(1, 0.9, 0.5))
	var tinta: Color = $Sprite2D.modulate
	$Sprite2D.modulate = Color(1.0, 0.45, 0.45)
	create_tween().tween_property($Sprite2D, "modulate", tinta, 0.15)
	if vita <= 0.0:
		_muori()

func _muori() -> void:
	GameState.zombie_uccisi += 1
	Grafica.schizzo(get_parent(), global_position, Color(0.45, 0.8, 0.35), 8)
	remove_from_group("zombie")
	set_physics_process(false)
	var t := create_tween()
	t.set_parallel()
	t.tween_property(self, "scale", Vector2(0.2, 0.2), 0.18)
	t.tween_property(self, "modulate:a", 0.0, 0.18)
	t.chain().tween_callback(queue_free)
