extends Control
## Schermata iniziale. Serve a due cose: scegliere la fazione e capire in
## trenta secondi che gioco e'.

const DESCRIZIONI := [
	"Vive di morale. Le tasse rendono in proporzione alla fede della gente:\n  se il popolo e' a pezzi, nessuno incassa. Predica, guida le processioni,\n  e quando serve scomunica chi comanda troppo.",
	"Vive di denaro e viveri. Paga tutto: riparazioni, guardie, addestramento.\n  Tassa, raziona, e legifera per prendersi consenso -- ma ogni misura\n  impopolare regala morale alla Chiesa.",
	"Vive delle mura. Ripara, recluta, addestra. E' l'unico che tiene in piedi\n  la citta' di notte, ma le guardie le paga con soldi che non sono suoi:\n  ogni reclutamento e' una trattativa col Governo.",
]

var _scelta := 0
var _testo := Label.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var sfondo := ColorRect.new()
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	sfondo.color = Color(0.07, 0.08, 0.11)
	add_child(sfondo)

	var titolo := Label.new()
	titolo.text = "THE LAST BRIGHT"
	titolo.add_theme_font_size_override("font_size", 62)
	titolo.set_anchors_preset(Control.PRESET_FULL_RECT)
	titolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titolo.offset_top = 48
	titolo.modulate = Color(1, 0.93, 0.72)
	add_child(titolo)

	var sottotitolo := Label.new()
	sottotitolo.text = "Ponte Milvio, anno zero. Tre fazioni, un ponte, e la notte che arriva."
	sottotitolo.add_theme_font_size_override("font_size", 17)
	sottotitolo.set_anchors_preset(Control.PRESET_FULL_RECT)
	sottotitolo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sottotitolo.offset_top = 122
	sottotitolo.modulate = Color(0.7, 0.72, 0.8)
	add_child(sottotitolo)

	_testo.add_theme_font_size_override("font_size", 15)
	_testo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_testo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_testo.offset_top = 190
	add_child(_testo)
	_aggiorna()
	# le panoramiche di debug devono saltare il menu
	if "--shot" in OS.get_cmdline_user_args():
		_avvia.call_deferred()   # cambiare scena dentro _ready non si puo' fare

func _process(_d: float) -> void:
	for f in 3:
		if Input.is_action_just_pressed("azione_%d" % (f + 1)):
			_scelta = f
			_aggiorna()
	if Input.is_action_just_pressed("ui_accept"):
		_avvia()

func _avvia() -> void:
	GameState.ripristina()
	GameState.fazione_giocatore = _scelta
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _aggiorna() -> void:
	var righe := "Scegli chi vuoi essere:\n\n"
	for f in 3:
		var segno := ">" if f == _scelta else " "
		righe += "%s  [%d]  %s\n%s\n\n" % [segno, f + 1, GameState.NOMI[f].to_upper(), DESCRIZIONI[f]]
	righe += "\nINVIO per cominciare       H in partita per il manuale\n\n"
	righe += "Reggi 10 giorni e hai vinto. Ma il nemico vero non e' fuori dalle mura:\n"
	righe += "il potere si divide in cento punti fra voi tre, e chi scende troppo\n"
	righe += "viene deposto -- e continua a giocare, dall'altra parte."
	_testo.text = righe
