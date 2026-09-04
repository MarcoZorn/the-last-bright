extends Control
## Schermata iniziale. Tutto e' un pulsante e non una scorciatoia da tastiera:
## su telefono la tastiera non c'e'. Le scorciatoie restano come comodita'.

const DESCRIZIONI := [
	"Vive di morale. Le tasse rendono in proporzione alla fede della gente:\nse il popolo e' a pezzi non incassa nessuno, nemmeno gli altri due.",
	"Vive di denaro e viveri. Paga tutto: riparazioni, guardie, addestramento.\nMa ogni misura impopolare regala morale alla Chiesa.",
	"Vive delle mura. E' l'unico che tiene in piedi la citta' di notte,\ne lo fa con soldi che non sono suoi.",
]

var _scelta := 0
var _bottoni_fazione: Array[Button] = []
var _descrizione := Label.new()
var _stato := Label.new()
var _codice := LineEdit.new()
var _riga_online := HBoxContainer.new()
var _gioca: Button
var _entra: Button

func _ready() -> void:
	var sfondo := ColorRect.new()
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	sfondo.color = Color(0.07, 0.08, 0.11)
	add_child(sfondo)

	var colonna := VBoxContainer.new()
	colonna.set_anchors_preset(Control.PRESET_FULL_RECT)
	colonna.offset_left = 40
	colonna.offset_right = -40
	colonna.offset_top = 26
	colonna.offset_bottom = -26
	colonna.add_theme_constant_override("separation", 10)
	add_child(colonna)

	colonna.add_child(_etichetta("THE LAST BRIGHT", 54, Color(1, 0.93, 0.72)))
	colonna.add_child(_etichetta(
		"Ponte Milvio, anno zero. Tre fazioni, un ponte, e la notte che arriva.",
		16, Color(0.7, 0.72, 0.8)))

	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 8)
	colonna.add_child(fila)
	for f in 3:
		var b := Button.new()
		b.text = GameState.NOMI[f].to_upper()
		b.custom_minimum_size = Vector2(150, 48)
		b.toggle_mode = true
		b.pressed.connect(_scegli.bind(f))
		fila.add_child(b)
		_bottoni_fazione.append(b)

	_descrizione.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_descrizione.add_theme_font_size_override("font_size", 14)
	_descrizione.custom_minimum_size = Vector2(0, 46)
	colonna.add_child(_descrizione)

	# il tutorial e' la prima cosa che si vede finche' non lo si e' fatto
	var fatto := GameState.tutorial_fatto()
	var impara := _bottone(colonna, "IMPARA A GIOCARE   (due minuti, guidato)", _tutorial)
	impara.custom_minimum_size = Vector2(0, 52)
	if not fatto:
		impara.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	_gioca = _bottone(colonna,
		("GIOCA DA SOLO   (le altre due fazioni le guida il computer)" if fatto
			else "salta e gioca subito"), _avvia)

	_riga_online.alignment = BoxContainer.ALIGNMENT_CENTER
	_riga_online.add_theme_constant_override("separation", 8)
	colonna.add_child(_riga_online)
	_codice.placeholder_text = "codice stanza (inventalo e passalo agli altri)"
	_codice.custom_minimum_size = Vector2(300, 44)
	_codice.max_length = 8
	_codice.text_submitted.connect(func(_t): _online())
	_riga_online.add_child(_codice)
	_entra = Button.new()
	_entra.text = "GIOCA ONLINE"
	_entra.custom_minimum_size = Vector2(170, 44)
	_entra.pressed.connect(_online)
	_riga_online.add_child(_entra)

	_stato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stato.add_theme_font_size_override("font_size", 14)
	colonna.add_child(_stato)

	colonna.add_child(_etichetta(
		"Reggi 10 giorni e hai vinto. Ma il nemico vero non e' fuori dalle mura:\n"
		+ "il potere si divide in cento punti fra voi tre, e chi scende troppo viene\n"
		+ "deposto -- e continua a giocare, dall'altra parte.", 13, Color(0.62, 0.64, 0.72)))

	Relay.cambiato.connect(_aggiorna)
	_scegli(0)
	if "--menu" in OS.get_cmdline_user_args():
		_scatta.call_deferred()
	elif "--tutorial" in OS.get_cmdline_user_args():
		_tutorial.call_deferred()
	elif "--shot" in OS.get_cmdline_user_args():
		_avvia.call_deferred()
	_da_riga_di_comando.call_deferred()

## Solo per controllare l'impaginazione senza aprire il gioco.
func _scatta() -> void:
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/lastbright_shot.png")
	get_tree().quit()

func _etichetta(testo: String, dim: int, colore: Color) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", dim)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.modulate = colore
	return l

func _bottone(dove: Node, testo: String, azione: Callable) -> Button:
	var b := Button.new()
	b.text = testo
	b.custom_minimum_size = Vector2(0, 46)
	b.pressed.connect(azione)
	dove.add_child(b)
	return b

func _scegli(f: int) -> void:
	_scelta = f
	for i in _bottoni_fazione.size():
		_bottoni_fazione[i].button_pressed = (i == f)
	_descrizione.text = DESCRIZIONI[f]

func _online() -> void:
	var c := _codice.text.strip_edges()
	if c.length() < 4:
		_stato.text = "Serve un codice di almeno quattro caratteri."
		return
	_stato.text = "Mi collego alla stanza %s..." % c.to_upper()
	Relay.entra(c)

func _aggiorna() -> void:
	if not Relay.collegato:
		if Relay.errore != "":
			_stato.text = Relay.errore
		return
	# chi non ospita entra in partita da solo, appena l'ospite comincia
	if Relay.partita_in_corso and not Relay.ospito:
		_avvia_online()
		return
	var righe := "Stanza %s -- sei %s%s\n" % [
		Relay.stanza, GameState.NOMI[Relay.mia_fazione],
		"  (ospiti tu: la partita gira sul tuo computer)" if Relay.ospito else ""]
	righe += "In sala: %d su 3.  " % Relay.fazioni.size()
	righe += "Premi COMINCIA quando siete pronti." if Relay.ospito else "Aspetti che l'ospite cominci."
	_stato.text = righe
	_gioca.text = "COMINCIA LA PARTITA" if Relay.ospito else "in attesa dell'ospite..."
	_gioca.disabled = not Relay.ospito
	for b in _bottoni_fazione:
		b.disabled = true        # online la fazione la assegna la stanza
	_entra.disabled = true
	_codice.editable = false

func _tutorial() -> void:
	GameState.ripristina()
	GameState.fazione_giocatore = _scelta
	GameState.tutorial = true
	GameState.tutorial_notte = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _avvia() -> void:
	GameState.tutorial = false
	if Relay.collegato:
		_avvia_online()
		return
	GameState.ripristina()
	GameState.fazione_giocatore = _scelta
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _avvia_online() -> void:
	GameState.ripristina()
	GameState.fazione_giocatore = Relay.mia_fazione
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _process(_d: float) -> void:
	if _codice.has_focus() or Relay.collegato:
		return
	for f in 3:
		if Input.is_action_just_pressed("azione_%d" % (f + 1)):
			_scegli(f)
	if Input.is_action_just_pressed("ui_accept"):
		_avvia()

## godot -- --ospita / --unisciti=IP restano per la rete locale e per i test
func _da_riga_di_comando() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--ospita":
			Rete.ospita()
		elif arg.begins_with("--avvia-fra="):
			await get_tree().create_timer(arg.split("=")[1].to_float()).timeout
			if multiplayer.is_server():
				Rete.avvia.rpc()
		elif arg.begins_with("--unisciti="):
			Rete.unisciti(arg.split("=")[1])
		elif arg.begins_with("--stanza="):
			# prova del multiplayer online senza browser
			Relay.entra(arg.split("=")[1])
			await get_tree().create_timer(4.0).timeout
			print("[online] id=%s fazione=%s ospito=%s in sala=%d" % [
				Relay.mio_id.substr(0, 6), GameState.NOMI[Relay.mia_fazione],
				Relay.ospito, Relay.fazioni.size()])
			if Relay.ospito or Relay.partita_in_corso:
				_avvia_online()
