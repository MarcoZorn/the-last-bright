extends CanvasLayer
## Interfaccia di gioco: risorse, potere delle tre fazioni, barra delle azioni,
## e le frecce che ti dicono quale muro sta cedendo mentre guardi da un'altra parte.

var _stato := Label.new()
var _potere := Label.new()
var _banner := Label.new()
var _vita := ColorRect.new()
var _barra_azioni := HBoxContainer.new()
var _fazione_mostrata := -99
var _annuncio := Label.new()

func _ready() -> void:
	var telaio := Control.new()
	telaio.set_anchors_preset(Control.PRESET_FULL_RECT)
	telaio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(telaio)

	var sinistra := PanelContainer.new()
	sinistra.position = Vector2(12, 12)
	sinistra.add_child(_stato)
	telaio.add_child(sinistra)

	var destra := PanelContainer.new()
	destra.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	destra.position = Vector2(-260, 12)
	destra.add_child(_potere)
	telaio.add_child(destra)

	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 46)
	_banner.modulate.a = 0.0
	telaio.add_child(_banner)

	_annuncio.set_anchors_preset(Control.PRESET_FULL_RECT)
	_annuncio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_annuncio.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_annuncio.add_theme_font_size_override("font_size", 18)
	_annuncio.offset_top = 94
	_annuncio.modulate.a = 0.0
	telaio.add_child(_annuncio)

	var piede := Control.new()
	piede.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	piede.mouse_filter = Control.MOUSE_FILTER_IGNORE
	telaio.add_child(piede)

	var sfondo_vita := ColorRect.new()
	sfondo_vita.color = Color(0, 0, 0, 0.6)
	sfondo_vita.position = Vector2(12, -34)
	sfondo_vita.size = Vector2(182, 12)
	piede.add_child(sfondo_vita)
	_vita.position = Vector2(14, -32)
	_vita.size = Vector2(178, 8)
	piede.add_child(_vita)

	var comandi := Label.new()
	comandi.text = "WASD  SPAZIO attacca  E ripara  Q recluta  click sx/dx guardie  1-6 azioni  F1/F2/F3 cambia fazione"
	comandi.add_theme_font_size_override("font_size", 11)
	comandi.position = Vector2(12, -18)
	piede.add_child(comandi)

	var centro_basso := Control.new()
	centro_basso.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	centro_basso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	telaio.add_child(centro_basso)
	_barra_azioni.position = Vector2(-478, -110)
	_barra_azioni.add_theme_constant_override("separation", 6)
	centro_basso.add_child(_barra_azioni)

	telaio.add_child(Frecce.new())

	GameState.fase_cambiata.connect(_annuncia_fase)
	GameState.annuncio.connect(_annuncia)

func _process(_d: float) -> void:
	_aggiorna_stato()
	_aggiorna_potere()
	_aggiorna_azioni()
	var g: Player = get_tree().get_first_node_in_group("player")
	if g != null:
		var quota: float = g.vita / Balance.PLAYER_VITA
		_vita.size.x = 178.0 * quota
		_vita.color = Color(1.0 - quota * 0.8, 0.2 + 0.6 * quota, 0.25)
	if GameState.finita:
		_banner.text = "HAI RETTO %d GIORNI" % Balance.GIORNI_PER_VINCERE if GameState.vinta else "LA CITTA' E' CADUTA"
		_banner.modulate.a = 0.95

func _aggiorna_stato() -> void:
	var nome_fase := "GIORNO" if GameState.fase == GameState.Fase.GIORNO else "NOTTE"
	var resto := ""
	if GameState.fase == GameState.Fase.GIORNO:
		resto = "  (notte fra %ds)" % ceili(Balance.giorno_durata(GameState.giorno) - GameState.tempo_fase)
	var fronti: String = ", ".join(Balance.fronti(GameState.giorno))
	_stato.text = ("  Giorno %d - %s%s\n" % [GameState.giorno, nome_fase, resto]
		+ "  fronti aperti: %s\n\n" % fronti
		+ "  Morale       %6.1f\n" % GameState.morale
		+ "  Denaro       %6.1f\n" % GameState.denaro
		+ "  Viveri       %6.1f\n" % GameState.viveri
		+ "  Mura         %6.1f\n" % GameState.sicurezza
		+ "  Popolazione   %5d\n" % GameState.popolazione
		+ "  Zombie uccisi %5d\n" % GameState.zombie_uccisi
		+ "  Guardie liv.  %5d\n" % GameState.livello_guardie
		+ "  Stipendi/alba %5.0f\n" % GameState.stipendi_dovuti()
		+ ("  Spedizioni in corso %d\n" % Spedizione.in_corso if Spedizione.in_corso > 0 else ""))

func _aggiorna_potere() -> void:
	var righe := "  POTERE\n"
	for f in 3:
		var tacche := int(round(GameState.potere[f] / 5.0))
		var marchio := ""
		if GameState.deposta == f:
			marchio = " [DEPOSTA]"
		if GameState.fazione_giocatore == f:
			marchio += " <- tu"
		righe += "  %-9s %s %4.1f%s\n" % [GameState.NOMI[f], "|".repeat(tacche), GameState.potere[f], marchio]
	if GameState.deposta >= 0:
		righe += "\n  %s trama nell'ombra\n" % GameState.NOMI[GameState.deposta]
	_potere.text = righe

## La barra si ricostruisce solo quando cambia la fazione che stai giocando:
## se la ricostruissi ogni frame, i pulsanti sfarfallerebbero.
func _aggiorna_azioni() -> void:
	var mia := GameState.fazione_effettiva()
	if mia != _fazione_mostrata:
		_fazione_mostrata = mia
		for c in _barra_azioni.get_children():
			c.queue_free()
		var elenco := Azioni.istanza.per_fazione(mia)
		for i in mini(elenco.size(), 6):
			var scatola := PanelContainer.new()
			var testo := Label.new()
			testo.name = "testo"
			testo.add_theme_font_size_override("font_size", 11)
			testo.custom_minimum_size = Vector2(150, 58)
			testo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			scatola.add_child(testo)
			_barra_azioni.add_child(scatola)

	var elenco2 := Azioni.istanza.per_fazione(mia)
	for i in _barra_azioni.get_child_count():
		var a: Dictionary = elenco2[i]
		var testo: Label = _barra_azioni.get_child(i).get_node("testo")
		var quota := Azioni.istanza.quota_ricarica(a["id"])
		var coda := ""
		if quota > 0.0:
			coda = "  %.0fs" % (quota * a["ricarica"])
		elif a["id"] == "addestramento":
			coda = "  %d$" % int(GameState.costo_addestramento())
		testo.text = "[%d] %s%s\n%s" % [i + 1, a["nome"], coda, a["desc"]]
		testo.modulate = Color.WHITE if Azioni.istanza.eseguibile(a["id"]) else Color(0.5, 0.5, 0.55)

func _annuncia_fase(nuova: GameState.Fase) -> void:
	_banner.text = "NOTTE %d" % GameState.giorno if nuova == GameState.Fase.NOTTE else "ALBA - GIORNO %d" % GameState.giorno
	_banner.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.4)
	t.tween_property(_banner, "modulate:a", 0.0, 0.9)

func _annuncia(testo: String, colore: Color) -> void:
	_annuncio.text = testo
	_annuncio.modulate = colore
	_annuncio.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_property(_annuncio, "modulate:a", 0.0, 0.8)

## Frecce d'allarme: la mappa e' piu' grande dello schermo, senza queste ti
## accorgi che una porta sta cedendo solo quando e' gia' caduta.
class Frecce extends Control:
	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var schermo := get_viewport_rect().size
		var trasf := get_viewport().get_canvas_transform()
		var bordo := Rect2(Vector2(46, 46), schermo - Vector2(92, 92))
		var pulsa := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.008)
		for b in get_tree().get_nodes_in_group("barricata"):
			if b.sotto_attacco <= 0.0:
				continue
			var p: Vector2 = trasf * b.centro_varco()
			var verso := (p - schermo * 0.5).normalized()
			if not bordo.has_point(p):
				p = p.clamp(bordo.position, bordo.position + bordo.size)
			_freccia(p, verso, Color(1, 0.25, 0.2, pulsa))

	func _freccia(dove: Vector2, verso: Vector2, colore: Color) -> void:
		var a := verso.angle()
		var punte := PackedVector2Array([
			dove + Vector2(11, 0).rotated(a),
			dove + Vector2(-7, 7).rotated(a),
			dove + Vector2(-7, -7).rotated(a)])
		draw_colored_polygon(punte, colore)
