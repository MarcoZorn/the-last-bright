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
var _ultima_posizione := Vector2.ZERO

## Il gruppo dei bersagli veniva interrogato da ogni zombie a ogni frame fisico:
## con cento zombie sono seimila query al secondo. Lo si legge una volta a frame.
static var _prede_frame := -1
static var _prede: Array = []
var _fermo_da := 0.0

var _barra: BarraVita

func _ready() -> void:
	add_to_group("zombie")
	_fra_ricalcoli = randf() * Balance.PATH_REFRESH  # sfasa il costo su piu' frame
	# ogni notte quelli che arrivano sono piu' duri di quelli di ieri
	vita_max = Balance.zombie_vita(GameState.giorno)
	vita = vita_max
	velocita = Balance.zombie_velocita(GameState.giorno)
	Grafica.ombra(self, 4.5)
	# tre varianti disegnate a mano invece di una sola tinta a caso: da lontano
	# l'ondata non sembra un plotone di cloni
	var sprite: Sprite2D = $Sprite2D
	sprite.region_rect = Rect2((4 + randi() % 3) * Balance.TILE, 0, Balance.TILE, Balance.TILE)
	scale = Vector2.ONE * randf_range(0.9, 1.1)
	velocita *= randf_range(0.9, 1.1)
	_barra = BarraVita.new(12.0, 10.0)
	add_child(_barra)
	_barra.visible = false

func _physics_process(delta: float) -> void:
	# su un client lo zombie e' solo un disegno che si muove: pensare in tre
	# posti diversi farebbe divergere le partite e triplicherebbe il costo di A*
	if not Rete.e_il_server():
		set_physics_process(false)
		return
	if mondo == null:
		return
	_fra_ricalcoli -= delta
	if _fra_ricalcoli <= 0.0:
		_fra_ricalcoli = Balance.PATH_REFRESH
		_ripianifica()

	$Sprite2D.position = Vector2.ZERO   # lo scatto del morso vale un frame solo
	var preda := _preda_a_portata()
	if preda != null:
		velocity = Vector2.ZERO
		preda.subisci(_danno_contro(preda) * delta)
		if not (preda is Player or preda is Guardia):
			Audio.suona("morso_mura", -18.0)
		_morde(preda, delta)
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
	_sblocca(delta)

## Un incastro fra due muri o fra dieci zombie ammassati non deve congelare la
## partita: se non ci si muove da un po', si ripianifica e si prende una spinta.
func _sblocca(delta: float) -> void:
	if global_position.distance_to(_ultima_posizione) > 2.0:
		_ultima_posizione = global_position
		_fermo_da = 0.0
		return
	_fermo_da += delta
	if _fermo_da < 3.0:
		return
	_fermo_da = 0.0
	_ultima_posizione = global_position
	_percorso.clear()
	_fra_ricalcoli = 0.0
	_spinta = Vector2.RIGHT.rotated(randf() * TAU) * Balance.SPINTA_COLPO

## Mordono qualunque cosa gli capiti a tiro: muri, guardie, leader, edifici.
func _preda_a_portata() -> Node2D:
	var frame := Engine.get_physics_frames()
	if frame != _prede_frame:
		_prede_frame = frame
		_prede = get_tree().get_nodes_in_group("danneggiabile")
	var migliore: Node2D = null
	var d_min := Balance.TILE * 1.4
	for n in _prede:
		if not is_instance_valid(n) or not n.attaccabile():
			continue
		var d: float = n.distanza(global_position)
		if d < d_min:
			d_min = d
			migliore = n
	return migliore

## Uno zombie che morde stava immobile come uno bloccato: si vedeva solo la
## barra della barricata scendere. Adesso si sporge a scatti verso quello che
## sta mangiando, cosi' un assedio si distingue da un difetto.
func _morde(preda: Node2D, delta: float) -> void:
	_tempo += delta
	var verso := global_position.direction_to(
		preda.global_position if preda is Player or preda is Guardia
		else global_position + Vector2(0, -1))
	if preda.has_method("distanza"):
		verso = global_position.direction_to(_verso_preda(preda))
	$Sprite2D.position = verso * (2.5 + 2.5 * sin(_tempo * 9.0))

func _verso_preda(preda: Node2D) -> Vector2:
	if preda is Barricata:
		return preda.centro_varco()
	return preda.global_position

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
	$Sprite2D.modulate = Color(1.6, 0.7, 0.7)
	create_tween().tween_property($Sprite2D, "modulate", Color.WHITE, 0.15)
	if vita <= 0.0:
		_muori()

## L'alba: chi e' rimasto fuori brucia. Non conta come uccisione, non e' merito
## di nessuno.
func brucia() -> void:
	Grafica.schizzo(get_parent(), global_position, Color(1, 0.75, 0.35), 5)
	remove_from_group("zombie")
	queue_free()

func _muori() -> void:
	GameState.zombie_uccisi += 1
	Grafica.schizzo(get_parent(), global_position, Color(0.45, 0.8, 0.35), 8)
	Audio.suona("morte", -12.0)
	remove_from_group("zombie")
	set_physics_process(false)
	var t := create_tween()
	t.set_parallel()
	t.tween_property(self, "scale", Vector2(0.2, 0.2), 0.18)
	t.tween_property(self, "modulate:a", 0.0, 0.18)
	t.chain().tween_callback(queue_free)
