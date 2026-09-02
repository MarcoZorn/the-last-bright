extends CanvasLayer
## HUD di debug. Non e' l'interfaccia definitiva: serve a capire cosa sta
## succedendo mentre proviamo le meccaniche.

var _stato := Label.new()
var _banner := Label.new()
var _vita := ColorRect.new()

func _ready() -> void:
	var pannello := PanelContainer.new()
	pannello.position = Vector2(12, 12)
	pannello.add_child(_stato)
	add_child(pannello)

	var telaio := Control.new()
	telaio.set_anchors_preset(Control.PRESET_FULL_RECT)
	telaio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(telaio)

	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 46)
	_banner.modulate.a = 0.0
	telaio.add_child(_banner)

	# ancorato in basso a sinistra: il pannello di stato sopra cambia altezza
	var piede := Control.new()
	piede.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	piede.mouse_filter = Control.MOUSE_FILTER_IGNORE
	telaio.add_child(piede)

	var sfondo_vita := ColorRect.new()
	sfondo_vita.color = Color(0, 0, 0, 0.6)
	sfondo_vita.position = Vector2(12, -56)
	sfondo_vita.size = Vector2(182, 12)
	piede.add_child(sfondo_vita)
	_vita.position = Vector2(14, -54)
	_vita.size = Vector2(178, 8)
	piede.add_child(_vita)

	var comandi := Label.new()
	comandi.text = "WASD muovi   SPAZIO attacca   E ripara (%d)   Q guardia (%d)   click sx seleziona, dx manda" % [Balance.RIPARA_COSTO, Balance.GUARDIA_COSTO]
	comandi.add_theme_font_size_override("font_size", 12)
	comandi.position = Vector2(12, -34)
	piede.add_child(comandi)

	GameState.fase_cambiata.connect(_annuncia)

func _process(_d: float) -> void:
	var fase := "GIORNO" if GameState.fase == GameState.Fase.GIORNO else "NOTTE"
	var resto := ""
	if GameState.fase == GameState.Fase.GIORNO:
		resto = "  (notte fra %ds)" % ceili(Balance.GIORNO_DURATA - GameState.tempo_fase)
	_stato.text = ("  Giorno %d - %s%s\n\n" % [GameState.giorno, fase, resto]
		+ "  Morale (Chiesa)      %5.1f\n" % GameState.morale
		+ "  Denaro (Governo)     %5.1f\n" % GameState.denaro
		+ "  Sicurezza (mura)     %5.1f\n" % GameState.sicurezza
		+ "  Popolazione           %4d\n" % GameState.popolazione
		+ "  Zombie uccisi         %4d\n" % GameState.zombie_uccisi
		+ ("\n  --- LA CITTA' E' CADUTA ---\n" if GameState.finita else ""))

	var g: Player = get_tree().get_first_node_in_group("player")
	if g != null:
		var quota: float = g.vita / Balance.PLAYER_VITA
		_vita.size.x = 178.0 * quota
		_vita.color = Color(1.0 - quota * 0.8, 0.2 + 0.6 * quota, 0.25)
		if g.a_terra:
			_banner.text = "SEI A TERRA"
			_banner.modulate.a = 0.85

func _annuncia(nuova: GameState.Fase) -> void:
	_banner.text = "NOTTE %d" % GameState.giorno if nuova == GameState.Fase.NOTTE else "ALBA - GIORNO %d" % GameState.giorno
	_banner.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_property(_banner, "modulate:a", 0.0, 1.0)
