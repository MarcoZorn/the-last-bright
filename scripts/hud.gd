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
var _manuale := PanelContainer.new()

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

	_costruisci_manuale()
	telaio.add_child(_manuale)

	telaio.add_child(Minimappa.new())
	telaio.add_child(Frecce.new())

	GameState.fase_cambiata.connect(_annuncia_fase)
	GameState.annuncio.connect(_annuncia)

## Manuale richiamabile con H: chi prova il gioco per la prima volta non ha
## voglia di aprire un file di testo.
func _costruisci_manuale() -> void:
	_manuale.set_anchors_preset(Control.PRESET_CENTER)
	_manuale.position = Vector2(150, 60)
	_manuale.visible = false
	var t := Label.new()
	t.add_theme_font_size_override("font_size", 13)
	t.text = """  COME SI GIOCA                                    (H per chiudere)

  Governi una citta'-stato assediata insieme ad altre due fazioni.
  Di giorno decidi, di notte reggi. Reggi 10 giorni e hai vinto.

  MUOVERSI      WASD          SPAZIO fendente frontale
  MURA          E ripara la barricata piu' vicina
  GUARDIE       Q recluta   click sx seleziona   click dx mandala li'
  FAZIONE       1-6 le tue azioni     F1/F2/F3 cambi fazione (per provare)

  IL POTERE E' A SOMMA ZERO
  Chiesa, Governo ed Esercito si dividono 100 punti di legittimita'.
  All'alba chi ha prodotto risultati ne guadagna e li toglie agli altri:
  morale alto premia la Chiesa, casse piene il Governo, mura intatte
  l'Esercito. Chi scende sotto 12 viene DEPOSTO -- ma non e' eliminato:
  passa a giocare da ribelle, con azioni sue per riprendersi il consenso.
  Sopra 36 torna al potere, e ne butta fuori un altro al suo posto.

  I SOLDI FINISCONO
  Una guardia costa 35$, e l'addestramento raddoppia di prezzo a ogni
  livello. Il gettito dell'alba dipende dal morale, quindi una citta'
  demoralizzata e' anche una citta' povera. Se una guardia non ti serve
  piu' puoi congedarla (azione 4 dell'Esercito) e recuperare 20$.

  I VIVERI FINISCONO
  La citta' mangia ogni giorno. Se restate a zero la gente muore di fame.
  L'unico modo di farne entrare e' la SPEDIZIONE, che il 28% delle volte
  non torna.

  L'ASSEDIO
  Gli zombie non ti inseguono: puntano ai tre edifici. Finche' le barricate
  reggono non c'e' strada, quindi le sfondano. Appena una cede, tutti gli
  altri trovano il varco. Le frecce rosse ai bordi dello schermo ti dicono
  quale sta cedendo. I primi giorni arrivano solo dal ponte a nord; dal
  giorno 5 anche dai fianchi, dal 10 sei circondato."""
	_manuale.add_child(t)

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
		var esito := "HAI RETTO %d GIORNI" % Balance.GIORNI_PER_VINCERE if GameState.vinta else "LA CITTA' E' CADUTA"
		_banner.text = "%s\n\nR per ricominciare     ESC per il menu" % esito
		_banner.add_theme_font_size_override("font_size", 34)
		_banner.modulate.a = 0.95
	if Input.is_action_just_pressed("manuale"):
		_manuale.visible = not _manuale.visible

func _aggiorna_stato() -> void:
	var nome_fase := "GIORNO" if GameState.fase == GameState.Fase.GIORNO else "NOTTE"
	var resto := ""
	if GameState.fase == GameState.Fase.GIORNO:
		resto = "  (notte fra %ds)" % ceili(Balance.giorno_durata(GameState.giorno) - GameState.tempo_fase)
	else:
		resto = "  (alba fra %ds)" % maxi(ceili(Balance.notte_durata(GameState.giorno) - GameState.tempo_fase), 0)
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
		+ "  Gettito/alba  %5.0f\n" % GameState.gettito_atteso()
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


## Minimappa: la citta' non ci sta in uno schermo, e senza una vista d'insieme
## non si capisce mai da che parte si sta perdendo.
class Minimappa extends Control:
	const SCALA := 3.0

	var _mondo: World
	var _terreno: ImageTexture

	func _ready() -> void:
		# ancoraggio a tutto schermo e posizione calcolata in _draw: gli anchor
		# risolti in _ready dipendono da una dimensione del genitore che a quel
		# punto non c'e' ancora, e la minimappa finiva fuori schermo.
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mondo = get_tree().get_first_node_in_group("mondo")
		if _mondo != null:
			_disegna_terreno()

	## Il terreno non cambia mai: si disegna una volta sola in una texture,
	## invece di duemila rettangoli a ogni frame.
	func _disegna_terreno() -> void:
		var img := Image.create(_mondo.larghezza, _mondo.altezza, false, Image.FORMAT_RGBA8)
		for y in _mondo.altezza:
			for x in _mondo.larghezza:
				img.set_pixel(x, y, _tinta(_mondo.carattere(Vector2i(x, y))))
		_terreno = ImageTexture.create_from_image(img)

	func _tinta(ch: String) -> Color:
		match ch:
			"~": return Color(0.16, 0.30, 0.50)
			"#": return Color(0.62, 0.64, 0.70)
			"=", ":": return Color(0.55, 0.57, 0.60)
			"C": return Color(0.45, 0.55, 0.85)
			"G": return Color(0.80, 0.35, 0.35)
			"A": return Color(0.70, 0.50, 0.30)
			"t": return Color(0.20, 0.40, 0.22)
			",": return Color(0.42, 0.34, 0.26)
			_: return Color(0.28, 0.42, 0.26)

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if _mondo == null or _terreno == null:
			return
		var dim := Vector2(_mondo.larghezza, _mondo.altezza) * SCALA
		var schermo := get_viewport_rect().size
		var org := schermo - dim - Vector2(14, 14)
		draw_rect(Rect2(org - Vector2(2, 2), dim + Vector2(4, 4)), Color(0, 0, 0, 0.65))
		draw_texture_rect(_terreno, Rect2(org, dim), false)

		for b in get_tree().get_nodes_in_group("barricata"):
			var quota: float = b.vita / Balance.BARRICATA_VITA
			var colore := Color(1.0 - quota * 0.9, 0.25 + 0.7 * quota, 0.2)
			if not b.in_piedi:
				colore = Color(0.25, 0.1, 0.1)
			for cella in b.celle:
				draw_rect(Rect2(org + Vector2(cella) * SCALA, Vector2.ONE * SCALA), colore)

		_punti(org, "zombie", Color(0.55, 0.95, 0.4), 2.0)
		_punti(org, "guardia", Color(0.5, 0.8, 1.0), 2.5)
		_punti(org, "player", Color(1, 1, 1), 3.5)

		# dove stai guardando adesso, ritagliato ai bordi della minimappa:
		# con la telecamera molto larga il rettangolo sforava fuori dal riquadro
		var trasf := get_viewport().get_canvas_transform()
		var vista := Rect2(-trasf.origin / trasf.get_scale(), schermo / trasf.get_scale())
		var a := org + (vista.position / Balance.TILE * SCALA).clamp(Vector2.ZERO, dim)
		var b := org + ((vista.position + vista.size) / Balance.TILE * SCALA).clamp(Vector2.ZERO, dim)
		draw_rect(Rect2(a, b - a), Color(1, 1, 1, 0.4), false, 1.0)

	func _punti(org: Vector2, gruppo: String, colore: Color, raggio: float) -> void:
		for n in get_tree().get_nodes_in_group(gruppo):
			var c: Vector2 = n.global_position / Balance.TILE * SCALA
			draw_circle(org + c, raggio, colore)
