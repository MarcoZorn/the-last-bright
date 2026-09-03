extends Node2D
## Monta la scena e guida il ciclo giorno/notte.
## Giorno: incassi, ripari, recluti, complotti. Notte: reggi.

const PLAYER := preload("res://scenes/player.tscn")
const ZOMBIE := preload("res://scenes/zombie.tscn")

var mondo: World
var _zombie: Node2D
var _da_spawnare := 0
var _prossimo_spawn := 0.0
var _vita_totale_barricate := 0.0
var _luce: CanvasModulate

func _ready() -> void:
	mondo = preload("res://scripts/world.gd").new()
	add_child(mondo)

	var barricate := Node2D.new()
	add_child(barricate)
	for gruppo in mondo.varchi:
		var b := Barricata.new()
		b.mondo = mondo
		b.celle.assign(gruppo)
		barricate.add_child(b)
	_vita_totale_barricate = mondo.varchi.size() * Balance.BARRICATA_VITA

	var quartieri := Node2D.new()
	add_child(quartieri)
	for tipo in mondo.edifici:
		for gruppo in mondo._raggruppa(mondo.edifici[tipo]):
			var e := Edificio.new()
			e.mondo = mondo
			e.tipo = tipo
			e.celle.assign(gruppo)
			quartieri.add_child(e)

	_zombie = Node2D.new()
	add_child(_zombie)
	var guardie := Node2D.new()
	add_child(guardie)

	var azioni := Azioni.new()
	azioni.mondo = mondo
	azioni.contenitore_guardie = guardie
	add_child(azioni)

	# le due fazioni che non stai giocando se la cavano da sole
	for f in 3:
		var ia := IAFazione.new()
		ia.fazione = f
		add_child(ia)

	var p: Player = PLAYER.instantiate()
	p.fazione = GameState.fazione_giocatore
	p.global_position = mondo.piazza_centro()
	p.mondo = mondo
	p.guardie = guardie
	add_child(p)

	_luce = CanvasModulate.new()
	_luce.color = Color.WHITE
	add_child(_luce)
	GameState.fase_cambiata.connect(_illumina)

	add_child(preload("res://scripts/hud.gd").new())

	if "--esercito" in OS.get_cmdline_user_args():
		GameState.fazione_giocatore = 2
		p.fazione = 2
		for i in 4:
			Azioni.istanza._recluta(mondo.piazza_centro() + Vector2(randf_range(-40, 40), randf_range(-40, 40)))
	if "--shot" in OS.get_cmdline_user_args():
		_scatta_panoramica()

## Selezione e ordini alle guardie: sinistro seleziona, destro manda.
func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventMouseButton and evento.pressed):
		return
	var punto := get_global_mouse_position()
	if evento.button_index == MOUSE_BUTTON_LEFT:
		var scelta: Guardia = null
		var d_min := 14.0
		for g in get_tree().get_nodes_in_group("guardia"):
			var d: float = g.global_position.distance_to(punto)
			if d < d_min:
				d_min = d
				scelta = g
		for g in get_tree().get_nodes_in_group("guardia"):
			g.selezionata = (g == scelta)
		if scelta != null:
			Audio.suona("selezione", -14.0)
	elif evento.button_index == MOUSE_BUTTON_RIGHT:
		for g in get_tree().get_nodes_in_group("guardia"):
			if g.selezionata:
				g.vai_a(punto)

## La notte deve sembrare notte, non un giorno con piu' zombie.
func _illumina(nuova: GameState.Fase) -> void:
	Audio.suona("notte" if nuova == GameState.Fase.NOTTE else "alba", -4.0)
	var colore := Color.WHITE if nuova == GameState.Fase.GIORNO else Color(0.44, 0.47, 0.58)
	create_tween().tween_property(_luce, "color", colore, 2.5)

func _process(delta: float) -> void:
	if GameState.finita:
		if Input.is_action_just_pressed("ricomincia"):
			GameState.ripristina()
			get_tree().reload_current_scene()
		elif Input.is_action_just_pressed("ui_cancel"):
			GameState.ripristina()
			get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	GameState.tempo_fase += delta
	_aggiorna_sicurezza()
	if get_tree().get_nodes_in_group("edificio").all(func(e): return not e.in_piedi):
		GameState.finita = true
	if GameState.fase == GameState.Fase.GIORNO:
		if GameState.tempo_fase >= Balance.giorno_durata(GameState.giorno):
			_inizia_notte()
	else:
		_notte(delta)

## La sicurezza dell'Esercito non e' un numero libero: e' lo stato reale delle
## mura. Non si puo' barare sul proprio indicatore.
func _aggiorna_sicurezza() -> void:
	var somma := 0.0
	for b in get_tree().get_nodes_in_group("barricata"):
		somma += b.vita
	GameState.sicurezza = 100.0 * somma / maxf(_vita_totale_barricate, 1.0)

func _inizia_notte() -> void:
	_da_spawnare = Balance.ONDATA_BASE + Balance.ONDATA_CRESCITA * (GameState.giorno - 1)
	_prossimo_spawn = 0.0
	GameState.cambia_fase(GameState.Fase.NOTTE)

func _notte(delta: float) -> void:
	_prossimo_spawn -= delta
	if _da_spawnare > 0 and _prossimo_spawn <= 0.0 and _zombie.get_child_count() < Balance.ZOMBIE_MAX:
		_prossimo_spawn = Balance.SPAWN_RITMO
		_da_spawnare -= 1
		_genera()
	var ripulita: bool = _da_spawnare == 0 and _zombie.get_child_count() == 0
	if ripulita:
		GameState.cambia_fase(GameState.Fase.GIORNO)
	elif GameState.tempo_fase > Balance.notte_durata(GameState.giorno):
		_alba_brucia()

## Il sole sorge comunque. Quelli ancora in giro non sopravvivono alla luce.
func _alba_brucia() -> void:
	var rimasti := get_tree().get_nodes_in_group("zombie")
	# ogni zombie ancora dentro le mura all'alba si e' preso qualcuno: senza
	# questo, "scappa e aspetta il sole" era una strategia vincente gratuita
	if not rimasti.is_empty():
		GameState.perdi_abitanti(rimasti.size() * Balance.ABITANTI_PERSI_PER_ZOMBIE)
	for z in rimasti:
		z.brucia()
	_da_spawnare = 0
	if not rimasti.is_empty():
		GameState.annuncio.emit("L'alba ne brucia %d" % rimasti.size(), Color(1, 0.85, 0.4))
	GameState.cambia_fase(GameState.Fase.GIORNO)

func _genera() -> void:
	# i primi giorni arrivano solo dal ponte; poi la citta' si scopre circondata
	var aperti: Array = []
	for lato in Balance.fronti(GameState.giorno):
		aperti.append_array(mondo.fronti[lato])
	if aperti.is_empty():
		aperti = mondo.spawn_zombie
	var cella: Vector2i = aperti.pick_random()

	var z: Zombie = ZOMBIE.instantiate()
	z.mondo = mondo
	# ogni zombie ha un obiettivo preciso: cosi' l'ondata si divide sui tre poli
	# invece di ammassarsi tutta sulla stessa porta
	var poli := get_tree().get_nodes_in_group("edificio").filter(func(e): return e.in_piedi)
	if not poli.is_empty():
		z.edificio_bersaglio = poli.pick_random()
	z.global_position = mondo.centro(cella) + Vector2(randf_range(-16, 16), randf_range(-12, 12))
	_zombie.add_child(z)

## Debug: `godot -- --shot` salva una panoramica della mappa e esce.
func _scatta_panoramica() -> void:
	var cam := Camera2D.new()
	cam.zoom = Vector2(0.82, 0.82)
	cam.global_position = mondo.centro(Vector2i(mondo.larghezza / 2, mondo.altezza / 2))
	add_child(cam)
	cam.make_current()
	if "--notte" in OS.get_cmdline_user_args():
		GameState.giorno = 6
		_inizia_notte()
		for i in 60:
			_notte(Balance.SPAWN_RITMO)
	await get_tree().create_timer(18.0 if "--notte" in OS.get_cmdline_user_args() else 2.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/lastbright_shot.png")
	get_tree().quit()
