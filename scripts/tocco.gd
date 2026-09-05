extends CanvasLayer
class_name Tocco
## Comandi per touchscreen. Compaiono solo se il dispositivo ha un touch:
## su PC non si vedono e non intercettano niente.
##
## Godot converte gia' i tocchi in clic del mouse, quindi selezionare una
## guardia e mandarla in giro funziona senza aggiungere nulla. Qui servono le
## due cose che il mouse non copre: muoversi e le azioni da tastiera.

const RAGGIO := 78.0        # zona utile del pollice sinistro
const RAGGIO_POMELLO := 34.0

static var direzione := Vector2.ZERO   # la legge Player al posto della tastiera

var _dito := -1
var _centro := Vector2.ZERO
var _base: Control
var _pomello: Control

func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		queue_free()
		return
	layer = 5
	var telaio := Control.new()
	telaio.set_anchors_preset(Control.PRESET_FULL_RECT)
	telaio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(telaio)

	_base = _cerchio(RAGGIO, Color(1, 1, 1, 0.10))
	_pomello = _cerchio(RAGGIO_POMELLO, Color(1, 1, 1, 0.22))
	telaio.add_child(_base)
	telaio.add_child(_pomello)
	_base.visible = false
	_pomello.visible = false

	var piede := Control.new()
	piede.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	piede.mouse_filter = Control.MOUSE_FILTER_IGNORE
	telaio.add_child(piede)
	_bottone(piede, "COLPISCI", Vector2(-124, -128), Vector2(112, 62), "attacca")
	_bottone(piede, "RIPARA", Vector2(-124, -60), Vector2(54, 52), "ripara")
	_bottone(piede, "GUARDIA", Vector2(-66, -60), Vector2(54, 52), "costruisci")

func _cerchio(raggio: float, colore: Color) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := Polygon2D.new()
	var punti := PackedVector2Array()
	for i in 24:
		punti.append(Vector2.RIGHT.rotated(TAU * i / 24.0) * raggio)
	p.polygon = punti
	p.color = colore
	c.add_child(p)
	return c

func _bottone(genitore: Control, testo: String, dove: Vector2, dim: Vector2, azione: String) -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.text = testo
	b.position = dove
	b.custom_minimum_size = dim
	b.size = dim
	b.add_theme_font_size_override("font_size", 12)
	# button_down/up invece di "pressed": tenere premuto COLPISCI deve continuare
	b.button_down.connect(func(): _premi(azione, true))
	b.button_up.connect(func(): _premi(azione, false))
	genitore.add_child(b)

func _premi(azione: String, giu: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = azione
	ev.pressed = giu
	Input.parse_input_event(ev)

## Il pollice sinistro fa da levetta: dove tocchi diventa il centro, e lo
## scostamento da li' e' la direzione. Cosi' non serve mirare a un punto fisso.
func _input(evento: InputEvent) -> void:
	var meta_schermo := get_viewport().get_visible_rect().size.x * 0.5
	if evento is InputEventScreenTouch:
		if evento.pressed and _dito == -1 and evento.position.x < meta_schermo:
			_dito = evento.index
			_centro = evento.position
			_base.position = _centro
			_pomello.position = _centro
			_base.visible = true
			_pomello.visible = true
		elif not evento.pressed and evento.index == _dito:
			_dito = -1
			direzione = Vector2.ZERO
			_base.visible = false
			_pomello.visible = false
	elif evento is InputEventScreenDrag and evento.index == _dito:
		var scarto: Vector2 = evento.position - _centro
		direzione = scarto / RAGGIO
		if direzione.length() > 1.0:
			direzione = direzione.normalized()
		_pomello.position = _centro + direzione * RAGGIO
