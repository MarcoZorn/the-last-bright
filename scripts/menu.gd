extends Control
## Schermata iniziale: scegli chi sei, e se giocare da solo o in tre.

const DESCRIZIONI := [
	"Vive di morale. Le tasse rendono in proporzione alla fede della gente:\n  se il popolo e' a pezzi, nessuno incassa -- nemmeno gli altri due.",
	"Vive di denaro e viveri. Paga tutto: riparazioni, guardie, addestramento.\n  Ma ogni misura impopolare regala morale alla Chiesa.",
	"Vive delle mura. E' l'unico che tiene in piedi la citta' di notte,\n  e lo fa con soldi che non sono suoi.",
]

var _scelta := 0
var _testo := Label.new()
var _indirizzo := LineEdit.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var sfondo := ColorRect.new()
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	sfondo.color = Color(0.07, 0.08, 0.11)
	add_child(sfondo)

	_titolo("THE LAST BRIGHT", 62, 40, Color(1, 0.93, 0.72))
	_titolo("Ponte Milvio, anno zero. Tre fazioni, un ponte, e la notte che arriva.",
		17, 114, Color(0.7, 0.72, 0.8))

	_testo.add_theme_font_size_override("font_size", 15)
	_testo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_testo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_testo.offset_top = 172
	add_child(_testo)

	_indirizzo.placeholder_text = "indirizzo dell'ospite (invio per connettersi)"
	_indirizzo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_indirizzo.position = Vector2(-170, 150)
	_indirizzo.custom_minimum_size = Vector2(340, 0)
	_indirizzo.visible = false
	_indirizzo.text_submitted.connect(_connetti)
	add_child(_indirizzo)

	Rete.lobby_cambiata.connect(_aggiorna)
	_aggiorna()
	if "--shot" in OS.get_cmdline_user_args():
		_avvia.call_deferred()   # cambiare scena dentro _ready non si puo' fare
	_da_riga_di_comando.call_deferred()

## Scorciatoie per provare la rete senza cliccare: utili anche a mano.
##   godot -- --ospita          apre la partita e aspetta
##   godot -- --unisciti=IP     si collega
func _da_riga_di_comando() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--ospita":
			Rete.ospita()
			_aggiorna()
		elif arg.begins_with("--avvia-fra="):
			await get_tree().create_timer(arg.split("=")[1].to_float()).timeout
			if multiplayer.is_server():
				Rete.avvia.rpc()
		elif arg.begins_with("--unisciti="):
			Rete.unisciti(arg.split("=")[1])
			_aggiorna()

func _titolo(testo: String, dim: int, alto: int, colore: Color) -> void:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", dim)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.offset_top = alto
	l.modulate = colore
	add_child(l)

func _process(_d: float) -> void:
	if _indirizzo.has_focus():
		return
	for f in 3:
		if Input.is_action_just_pressed("azione_%d" % (f + 1)) and not Rete.in_rete:
			_scelta = f
			_aggiorna()
	if Input.is_action_just_pressed("ospita") and not Rete.in_rete:
		Rete.ospita()
		_aggiorna()
	if Input.is_action_just_pressed("unisciti") and not Rete.in_rete:
		_indirizzo.visible = true
		_indirizzo.grab_focus()
	if Input.is_action_just_pressed("ui_cancel") and Rete.in_rete:
		Rete.chiudi()
	if Input.is_action_just_pressed("ui_accept"):
		if not Rete.in_rete:
			_avvia()
		elif multiplayer.is_server():
			Rete.avvia.rpc()

func _connetti(testo: String) -> void:
	_indirizzo.visible = false
	_indirizzo.release_focus()
	Rete.unisciti(testo.strip_edges())
	_aggiorna()

func _avvia() -> void:
	GameState.ripristina()
	GameState.fazione_giocatore = _scelta
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _aggiorna() -> void:
	if Rete.in_rete:
		_testo.text = _lobby()
		return
	var righe := "Scegli chi vuoi essere:\n\n"
	for f in 3:
		righe += "%s  [%d]  %s\n%s\n\n" % [
			">" if f == _scelta else " ", f + 1, GameState.NOMI[f].to_upper(), DESCRIZIONI[f]]
	righe += "\nINVIO gioca da solo (le altre due fazioni le guida il computer)\n"
	righe += "O    ospita una partita in tre        U  unisciti a una partita\n"
	righe += "H    in gioco, apre il manuale\n\n"
	righe += "Reggi 10 giorni e hai vinto. Ma il nemico vero non e' fuori dalle mura:\n"
	righe += "il potere si divide in cento punti fra voi tre, e chi scende troppo\n"
	righe += "viene deposto -- e continua a giocare, dall'altra parte."
	if Rete.errore != "":
		righe += "\n\n%s" % Rete.errore
	_testo.text = righe

func _lobby() -> String:
	var righe := "SALA D'ATTESA\n\n"
	for id in Rete.fazioni:
		var chi := "tu" if id == multiplayer.get_unique_id() else "peer %d" % id
		righe += "  %-9s  %s\n" % [GameState.NOMI[Rete.fazioni[id]], chi]
	for i in range(Rete.fazioni.size(), 3):
		righe += "  %-9s  (in attesa)\n" % "-"
	righe += "\n"
	if multiplayer.is_server():
		righe += "Sei tu l'ospite. Gli altri si collegano al tuo indirizzo.\n"
		righe += "INVIO comincia (anche in due o da solo)   ESC annulla\n"
		righe += "\nIndirizzi di questa macchina:\n"
		for ind in IP.get_local_addresses():
			if ind.count(".") == 3 and not ind.begins_with("127."):
				righe += "  %s\n" % ind
	else:
		righe += "Aspetti che l'ospite cominci.   ESC per staccarti\n"
	return righe
