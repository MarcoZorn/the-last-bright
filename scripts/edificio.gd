extends Node2D
class_name Edificio
## Il polo di potere di una fazione. Non e' decorazione: ha una vita, gli zombie
## ci puntano, e se crolla la citta' lo sente. E' il motivo per cui vale la pena
## difendere un lato delle mura piuttosto che un altro.

const NOMI := {"C": "Chiesa", "G": "Palazzo", "A": "Caserma"}

var mondo: World
var celle: Array[Vector2i] = []
var tipo := "C"
var vita: float = Balance.EDIFICIO_VITA
var in_piedi := true

var _barra: BarraVita
var _approcci: PackedVector2Array

func _ready() -> void:
	add_to_group("danneggiabile")
	add_to_group("edificio")
	var centro := Vector2.ZERO
	for c in celle:
		centro += mondo.centro(c)
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not mondo.bloccato(c + d):
				_approcci.append(mondo.centro(c + d))
	global_position = centro / maxi(celle.size(), 1)

	_barra = BarraVita.new(46.0, 4.0)
	add_child(_barra)
	var nome := Label.new()
	nome.text = NOMI.get(tipo, "?")
	nome.add_theme_font_size_override("font_size", 9)
	nome.position = Vector2(-20, -20)
	add_child(nome)

func attaccabile() -> bool:
	return in_piedi

func distanza(p: Vector2) -> float:
	var d := INF
	for c in celle:
		d = minf(d, p.distance_to(mondo.centro(c)))
	return d

func punto_approccio(da: Vector2) -> Vector2:
	var migliore := da
	var d_min := INF
	for p in _approcci:
		var d := da.distance_squared_to(p)
		if d < d_min:
			d_min = d
			migliore = p
	return migliore

func subisci(danno: float, _spinta := Vector2.ZERO) -> void:
	if not in_piedi:
		return
	vita -= danno
	_barra.aggiorna(vita / Balance.EDIFICIO_VITA)
	if vita <= 0.0:
		_crolla()

## Le macerie restano solide: un edificio crollato non diventa una scorciatoia.
func _crolla() -> void:
	in_piedi = false
	vita = 0.0
	remove_from_group("danneggiabile")
	var macerie := ColorRect.new()
	macerie.color = Color(0.15, 0.1, 0.1, 0.6)
	var minimo := celle[0]
	var massimo := celle[0]
	for c in celle:
		minimo = minimo.min(c)
		massimo = massimo.max(c)
	macerie.size = Vector2(massimo - minimo + Vector2i.ONE) * Balance.TILE
	macerie.global_position = Vector2(minimo) * Balance.TILE
	get_parent().add_child(macerie)
	GameState.modifica("morale", -Balance.EDIFICIO_CADUTO_MORALE)
	GameState.perdi_abitanti(Balance.EDIFICIO_CADUTO_ABITANTI)
