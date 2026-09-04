extends CharacterBody2D
class_name Guardia
## La guardia dell'Esercito. Non e' una torretta: la selezioni col tasto
## sinistro e la mandi dove serve col destro. Parte come recluta scarsa e
## migliora solo se l'Esercito paga l'addestramento -- e i soldi sono del Governo.

var mondo: World
var vita: float
var selezionata := false:
	set(v):
		selezionata = v
		if _anello != null:
			_anello.visible = v

var _percorso: PackedVector2Array
var _cooldown := 0.0
var _barra: BarraVita
var _anello := Line2D.new()
var _livello_visto := -1
var _sprite: Sprite2D
var _meta_diretta := Vector2.INF
var _fra_ronde := 0.0
var _tempo := 0.0

func _ready() -> void:
	add_to_group("guardia")
	add_to_group("danneggiabile")
	collision_layer = 2
	collision_mask = 1

	_sprite = Sprite2D.new()
	var s := _sprite
	s.texture = load("res://assets/sprites.png")
	s.region_enabled = true
	s.region_rect = Rect2(3 * Balance.TILE, 0, Balance.TILE, Balance.TILE)  # elmo e lancia
	add_child(s)

	var forma := CircleShape2D.new()
	forma.radius = 5.0
	var cs := CollisionShape2D.new()
	cs.shape = forma
	add_child(cs)

	_anello.width = 1.0
	_anello.default_color = Color(1.0, 0.95, 0.4)
	for i in 17:
		_anello.add_point(Vector2.RIGHT.rotated(TAU * i / 16.0) * 9.0)
	_anello.visible = false
	add_child(_anello)

	Grafica.ombra(self, 5.0)
	_barra = BarraVita.new(20.0, 12.0)
	add_child(_barra)
	vita = vita_max()
	_livello_visto = GameState.livello_guardie
	_barra.aggiorna(1.0)

func vita_max() -> float:
	return Balance.GUARDIA_VITA[GameState.livello_guardie]

func attaccabile() -> bool:
	return vita > 0.0

func distanza(p: Vector2) -> float:
	return global_position.distance_to(p)

## Se A* non trova strada e' quasi sempre perche' il varco e' chiuso: le guardie
## ci passano lo stesso, quindi si va in linea retta e ci pensa la fisica.
func vai_a(punto: Vector2) -> void:
	if mondo == null:
		return
	_percorso = mondo.percorso(global_position, punto)
	_meta_diretta = punto if _percorso.is_empty() else Vector2.INF

func subisci(danno: float, _spinta := Vector2.ZERO) -> void:
	vita -= danno
	_barra.aggiorna(vita / vita_max())
	if vita <= 0.0:
		GameState.guardie_perse += 1
		Grafica.schizzo(get_parent(), global_position, Color(0.9, 0.3, 0.3), 9)
		remove_from_group("guardia")
		remove_from_group("danneggiabile")
		queue_free()

func _physics_process(delta: float) -> void:
	if not Rete.e_il_server():
		set_physics_process(false)
		return
	# un addestramento nuovo rimette in sesto anche chi e' gia' in servizio
	if _livello_visto != GameState.livello_guardie:
		_livello_visto = GameState.livello_guardie
		vita = vita_max()
		_barra.aggiorna(1.0)

	# Chi e' gia' a tiro si abbatte da fermi. Prima la guardia continuava a
	# seguire il percorso mentre sparava, finendo addosso allo zombie: a quel
	# punto perde, perche' il morso fa piu' danni di quanti ne regga.
	var preda := _piu_vicino()
	if preda != null:
		_percorso.clear()
		_meta_diretta = Vector2.INF

	if _percorso.size() > 1:
		var passo := _percorso[1]
		velocity = global_position.direction_to(passo) * Balance.GUARDIA_VELOCITA
		if global_position.distance_to(passo) < 3.0:
			_percorso.remove_at(0)
	elif _meta_diretta != Vector2.INF:
		velocity = global_position.direction_to(_meta_diretta) * Balance.GUARDIA_VELOCITA
		if global_position.distance_to(_meta_diretta) < 6.0:
			_meta_diretta = Vector2.INF
	else:
		velocity = Vector2.ZERO
		_percorso.clear()
	move_and_slide()
	_tempo += delta
	Grafica.passo(_sprite, velocity, _tempo)

	_cooldown -= delta
	if preda == null:
		_presidia(delta)
		return
	if _cooldown > 0.0:
		return
	_cooldown = Balance.GUARDIA_CADENZA[GameState.livello_guardie]
	GameState.colpi_sparati += 1
	Audio.suona("sparo", -20.0)
	var p := Proiettile.new()
	p.bersaglio = preda
	p.danno = Balance.PROIETTILE_DANNO[GameState.livello_guardie]
	p.global_position = global_position
	get_parent().add_child(p)

## Senza questo le guardie restavano dove le avevi reclutate -- in piazza, a
## duecento pixel dai combattimenti -- e in cinque partite simulate non hanno
## ucciso un solo zombie. Adesso, se nessuno ha dato ordini e non c'e' nessuno a
## tiro, vanno da sole al varco che sta cedendo.
## ponytail: un ordine del giocatore vale finche' non e' arrivata; poi riprende
## il presidio. Se servira' tenerle inchiodate a un posto, aggiungere un ordine
## "resta qui" invece di complicare questa.
func _presidia(delta: float) -> void:
	if not _percorso.is_empty() or _meta_diretta != Vector2.INF:
		return
	_fra_ronde -= delta
	if _fra_ronde > 0.0:
		return
	_fra_ronde = 2.0

	# 1. chi e' gia' dentro viene prima di tutto. Prima le guardie difendevano
	#    i varchi ancora in piedi e ignoravano il buco da cui passavano davvero.
	var intruso := _intruso_piu_vicino()
	if intruso != null:
		vai_a(intruso.global_position)
		return

	# 2. altrimenti il varco che sta cedendo, o il piu' vicino ancora in piedi
	# Solo le porte della citta'. Il checkpoint del ponte sta oltre il fiume: con
	# il vecchio bonus da 600px le guardie ci andavano SEMPRE, e passavano la
	# notte a camminare avanti e indietro senza sparare un colpo.
	var citta: Rect2 = mondo.dentro_le_mura.grow(Balance.TILE * 2.0)
	var meta: Barricata = null
	var d_min := INF
	for b in get_tree().get_nodes_in_group("barricata"):
		if not b.in_piedi or not citta.has_point(b.centro_varco()):
			continue
		# preferisci quello sotto attacco, ma non a costo di attraversare la citta'
		var d: float = b.distanza(global_position) - (150.0 if b.sotto_attacco > 0.0 else 0.0)
		if d < d_min:
			d_min = d
			meta = b
	# addosso al muro, non "a portata": lo zombie morde dall'altro lato a 22px
	if meta != null and meta.distanza(global_position) > Balance.TILE * 1.2:
		vai_a(meta.punto_approccio(global_position))

func _intruso_piu_vicino() -> Node2D:
	if mondo == null:
		return null
	var migliore: Node2D = null
	var d_min := INF
	for z in get_tree().get_nodes_in_group("zombie"):
		if not mondo.dentro_le_mura.has_point(z.global_position):
			continue
		var d: float = global_position.distance_to(z.global_position)
		if d < d_min:
			d_min = d
			migliore = z
	return migliore

func _piu_vicino() -> Node2D:
	var migliore: Node2D = null
	var d_min: float = Balance.GUARDIA_RAGGIO[GameState.livello_guardie]
	for z in get_tree().get_nodes_in_group("zombie"):
		var d := global_position.distance_to(z.global_position)
		if d < d_min:
			d_min = d
			migliore = z
	return migliore
