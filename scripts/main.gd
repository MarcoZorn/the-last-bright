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
var _guardie: Node2D
var _fra_istantanee := 0.0
var _fantasmi: Fantasmi

func _ready() -> void:
	mondo = preload("res://scripts/world.gd").new()
	add_child(mondo)

	var barricate := Node2D.new()
	barricate.name = "Barricate"
	add_child(barricate)
	for gruppo in mondo.varchi:
		var b := Barricata.new()
		b.mondo = mondo
		b.celle.assign(gruppo)
		barricate.add_child(b)
	_vita_totale_barricate = mondo.varchi.size() * Balance.BARRICATA_VITA

	var quartieri := Node2D.new()
	quartieri.name = "Quartieri"
	add_child(quartieri)
	for tipo in mondo.edifici:
		for gruppo in mondo._raggruppa(mondo.edifici[tipo]):
			var e := Edificio.new()
			e.mondo = mondo
			e.tipo = tipo
			e.celle.assign(gruppo)
			quartieri.add_child(e)

	_zombie = Node2D.new()
	_zombie.name = "Zombie"
	add_child(_zombie)
	_guardie = Node2D.new()
	_guardie.name = "Guardie"
	add_child(_guardie)
	var guardie := _guardie

	var azioni := Azioni.new()
	azioni.mondo = mondo
	azioni.contenitore_guardie = guardie
	add_child(azioni)

	# le due fazioni che non stai giocando se la cavano da sole
	for f in 3:
		var ia := IAFazione.new()
		ia.fazione = f
		add_child(ia)

	var giocatori := Node2D.new()
	giocatori.name = "Giocatori"
	add_child(giocatori)
	# un generatore copre un contenitore solo, quindi ce ne vuole uno per tipo
	# ponytail: un sincronizzatore per zombie regge una LAN a tre. Se con
	# centocinquanta zombie la rete singhiozza, passare a un unico pacchetto di
	# posizioni spedito dal server a 12Hz.
	_genera_per(giocatori, "res://scenes/player.tscn")
	_genera_per(_zombie, "res://scenes/zombie.tscn")
	_genera_per(_guardie, "res://scenes/guardia.tscn")

	if Rete.online():
		# online i nodi non li replica Godot: li creiamo uguali su tutti,
		# uno per fazione presente nella stanza
		var viste := {}
		for id in Relay.fazioni:
			viste[Relay.fazioni[id]] = true
		for f in viste:
			_crea_leader(giocatori, 1, int(f), int(f) == Relay.mia_fazione)
	elif not Rete.in_rete:
		_crea_leader(giocatori, 1, GameState.fazione_giocatore)
	elif multiplayer.is_server():
		for id in Rete.fazioni:
			_crea_leader(giocatori, id, Rete.fazioni[id])

	_luce = CanvasModulate.new()
	_luce.color = Color.WHITE
	add_child(_luce)
	GameState.fase_cambiata.connect(_illumina)

	_fantasmi = Fantasmi.new()
	add_child(_fantasmi)

	add_child(preload("res://scripts/hud.gd").new())
	add_child(preload("res://scripts/tocco.gd").new())
	if GameState.tutorial:
		add_child(preload("res://scripts/tutorial.gd").new())

	if "--esercito" in OS.get_cmdline_user_args():
		GameState.fazione_giocatore = 2
		var mio_leader: Player = get_tree().get_first_node_in_group("mio")
		if mio_leader != null:
			mio_leader.fazione = 2
			mio_leader._vesti(2)
		for i in 4:
			Azioni.istanza._recluta(mondo.piazza_centro() + Vector2(randf_range(-40, 40), randf_range(-40, 40)))
	if Rete.online() and "--stanza-diag" in OS.get_cmdline_user_args():
		await get_tree().create_timer(10.0).timeout
		print("[online] giorno %d | morale %.0f | leader %d | ospito %s" % [
			GameState.giorno, GameState.morale,
			get_tree().get_nodes_in_group("player").size(), Rete.e_il_server()])
	if Rete.in_rete:
		print("[rete] partita avviata, sono %d, fazione %s" % [
			multiplayer.get_unique_id(), GameState.NOMI[GameState.fazione_giocatore]])
		await get_tree().create_timer(8.0).timeout
		print("[rete] leader %d | giorno %d | morale %.0f | denaro %.0f | fase %d" % [
			giocatori.get_child_count(), GameState.giorno, GameState.morale,
			GameState.denaro, GameState.fase])
	if "--shot" in OS.get_cmdline_user_args():
		_scatta_panoramica()

## spawn_path va calcolato DOPO l'ingresso nell'albero: prima i due nodi non
## hanno ancora un antenato comune e Godot non sa risolvere il percorso.
func _genera_per(contenitore: Node2D, scena: String) -> void:
	var g := MultiplayerSpawner.new()
	g.add_spawnable_scene(scena)
	add_child(g)
	g.spawn_path = g.get_path_to(contenitore)

func _crea_leader(dove: Node2D, peer: int, fazione: int, mio := true) -> void:
	var p: Player = PLAYER.instantiate()
	p.comando_locale = mio
	p.fazione = fazione
	p.name = "%d_%d" % [peer, fazione]
	p.mondo = mondo
	p.guardie = _guardie
	p.position = mondo.piazza_centro() + Vector2(randf_range(-24, 24), randf_range(-24, 24))
	dove.add_child(p, true)

## Barricate ed edifici nascono uguali su tutti i peer, dalla stessa mappa e
## nello stesso ordine: per tenerli allineati basta spedire le vite in fila,
## senza replicare i nodi.
func _vite(gruppo: String) -> PackedFloat32Array:
	var v := PackedFloat32Array()
	for n in get_tree().get_nodes_in_group(gruppo):
		v.append(n.vita)
	return v

@rpc("authority", "call_remote", "unreliable_ordered")
func _stato_strutture(varchi: PackedFloat32Array, poli: PackedFloat32Array) -> void:
	_applica_vite("barricata", varchi)
	_applica_vite("edificio", poli)

func _applica_vite(gruppo: String, vite: PackedFloat32Array) -> void:
	var nodi := get_tree().get_nodes_in_group(gruppo)
	if nodi.size() != vite.size():
		return   # scene ancora disallineate: si riprova al prossimo pacchetto
	for i in nodi.size():
		nodi[i].imposta_vita(vite[i])

## Chi non ospita non simula niente: prende l'istantanea e la disegna.
func _disegna_quello_che_arriva() -> void:
	var d := Relay.prendi_istantanea()
	if d.is_empty():
		return
	if d.has("s"):
		GameState.applica(d["s"])
	_fantasmi.aggiorna(d.get("z", []), d.get("g", []))
	_vite_da_rete("barricata", d.get("b", []))
	_vite_da_rete("edificio", d.get("e", []))
	for voce in d.get("p", []):
		var fazione := int(voce[0])
		if fazione == GameState.fazione_giocatore:
			continue          # il tuo leader lo muovi tu, non te lo detta la rete
		var altrui := _leader_di(fazione)
		if altrui != null:
			altrui.position = altrui.position.lerp(
				Vector2(float(voce[1]), float(voce[2])) / Relay.SCALA, 0.35)

## Chi ospita raccoglie posizioni e richieste d'azione degli altri.
func _comandi_dei_client() -> void:
	for messaggio in Relay.prendi_comandi():
		var c = JSON.parse_string(str(messaggio.get("c", "")))
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var fazione := int(c.get("f", -1))
		if fazione < 0 or fazione > 2:
			continue
		var leader := _leader_di(fazione)
		if leader != null and c.has("x"):
			leader.position = Vector2(float(c["x"]), float(c["y"])) / Relay.SCALA
		for id in c.get("a", []):
			var chi: int = GameState.Faction.RIBELLE if GameState.deposta == fazione else fazione
			Azioni.istanza.esegui(str(id), chi)

func _leader_di(fazione: int) -> Player:
	for g in get_tree().get_nodes_in_group("player"):
		if g.fazione == fazione:
			return g
	return null

func _vite_da_rete(gruppo: String, vite: Array) -> void:
	var nodi := get_tree().get_nodes_in_group(gruppo)
	if nodi.size() != vite.size():
		return
	for i in nodi.size():
		nodi[i].imposta_vita(float(vite[i]))

## Selezione e ordini alle guardie: sinistro seleziona, destro manda.
func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventMouseButton and evento.pressed):
		return
	var mio: Player = get_tree().get_first_node_in_group("mio")
	if mio == null or not mio.is_multiplayer_authority():
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
	if Rete.online():
		if Rete.e_il_server():
			_comandi_dei_client()
		else:
			_disegna_quello_che_arriva()
			return
	# in rete la partita gira in un posto solo: i client disegnano quello che
	# ricevono, altrimenti tre simulazioni divergerebbero in pochi secondi
	if not Rete.e_il_server():
		return
	if Rete.in_rete:
		_fra_istantanee -= delta
		if _fra_istantanee <= 0.0:
			_fra_istantanee = 0.25
			GameState.applica.rpc(GameState.istantanea())
			_stato_strutture.rpc(_vite("barricata"), _vite("edificio"))
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
	var poli := get_tree().get_nodes_in_group("edificio")
	if not poli.is_empty() and poli.all(func(e): return not e.in_piedi):
		GameState.finita = true
	if GameState.tutorial and not GameState.tutorial_notte:
		GameState.tempo_fase = 0.0
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
	var vivi := get_tree().get_nodes_in_group("zombie").size()
	if _da_spawnare > 0 and _prossimo_spawn <= 0.0 and vivi < Balance.ZOMBIE_MAX:
		_prossimo_spawn = Balance.SPAWN_RITMO
		_da_spawnare -= 1
		_genera()
	var ripulita: bool = _da_spawnare == 0 and vivi == 0
	if ripulita:
		GameState.cambia_fase(GameState.Fase.GIORNO)
	elif GameState.tempo_fase > Balance.notte_durata(GameState.giorno):
		_alba_brucia()

## Il sole sorge comunque. Quelli ancora in giro non sopravvivono alla luce.
func _alba_brucia() -> void:
	var rimasti := get_tree().get_nodes_in_group("zombie")
	# L'alba non e' un pulsante che azzera il tabellone: l'ondata che non hai
	# ammazzato ti e' costata gente. Chi era entrato costa il doppio di chi
	# stava ancora premendo da fuori.
	var dentro := rimasti.filter(func(z): return mondo.dentro_le_mura.has_point(z.global_position))
	var persi: int = dentro.size() * Balance.ABITANTI_PERSI_DENTRO \
		+ (rimasti.size() - dentro.size()) * Balance.ABITANTI_PERSI_FUORI
	if persi > 0:
		GameState.perdi_abitanti(persi)
	if "--diag" in OS.get_cmdline_user_args():
		var celle_g := []
		for g in get_tree().get_nodes_in_group("guardia"):
			celle_g.append(mondo.a_cella(g.global_position))
		var dove := {}
		for z in rimasti:
			var ch := mondo.carattere(mondo.a_cella(z.global_position))
			var stato := "cammina"
			if z.velocity.length() < 2.0:
				stato = "morde" if z._preda_a_portata() != null else "FERMO-SENZA-MOTIVO"
			var chiave := "%s:%s" % [ch, stato]
			dove[chiave] = int(dove.get(chiave, 0)) + 1
		print("[diag] alba %d | guardie %s | zombie per casella: %s" % [
			GameState.giorno, celle_g.size(), dove])
	GameState.zombie_bruciati += rimasti.size()
	for z in rimasti:
		z.brucia()
	_da_spawnare = 0
	if not rimasti.is_empty():
		GameState.annuncio.emit("L'alba ne brucia %d, ma sono costati %d abitanti" % [rimasti.size(), persi], Color(1, 0.6, 0.35))
	GameState.cambia_fase(GameState.Fase.GIORNO)

## Usata dal tutorial: qualche zombie subito addosso, senza aspettare l'ondata.
func genera_vicino(dove: Vector2, quanti: int) -> void:
	for i in quanti:
		var z: Zombie = ZOMBIE.instantiate()
		z.mondo = mondo
		var poli := get_tree().get_nodes_in_group("edificio").filter(func(e): return e.in_piedi)
		if not poli.is_empty():
			z.edificio_bersaglio = poli.pick_random()
		z.position = dove + Vector2.RIGHT.rotated(TAU * i / float(quanti)) * 70.0
		_zombie.add_child(z, true)

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
	_zombie.add_child(z, true)   # nome leggibile: i nomi riservati non si replicano

## Debug: `godot -- --shot` salva una panoramica della mappa e esce.
func _scatta_panoramica() -> void:
	var cam := Camera2D.new()
	cam.zoom = Vector2(0.82, 0.82)
	cam.global_position = mondo.centro(Vector2i(mondo.larghezza / 2, mondo.altezza / 2))
	add_child(cam)
	cam.make_current()
	if "--fine" in OS.get_cmdline_user_args():
		GameState.giorno = 7
		GameState.popolazione = 0
		GameState.viveri = 12.0
		GameState.sicurezza = 22.0
		GameState.zombie_uccisi = 9
		GameState.zombie_bruciati = 84
		GameState.deposta = 1
		GameState.finita = true
	if "--notte" in OS.get_cmdline_user_args():
		GameState.giorno = 6
		_inizia_notte()
		for i in 60:
			_notte(Balance.SPAWN_RITMO)
	await get_tree().create_timer(18.0 if "--notte" in OS.get_cmdline_user_args() else 2.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/lastbright_shot.png")
	get_tree().quit()
