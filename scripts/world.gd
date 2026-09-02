extends Node2D
class_name World
## Costruisce il mondo da assets/map.txt: tile, collisioni e griglia di
## pathfinding vengono TUTTE dalla stessa fonte, quindi non possono divergere.
## Per cambiare la mappa si edita map.txt, non questo file.

const T := Balance.TILE
const ATLANTI := [
	"res://assets/kenney/tiny-town/Tilemap/tilemap_packed.png",
	"res://assets/kenney/tiny-battle/Tilemap/tilemap_packed.png",
]
## carattere -> [indice atlante, coordinate del tile nell'atlante]
const TILES := {
	".": [1, Vector2i(0, 0)],   # erba
	"S": [1, Vector2i(0, 0)],   # spawn (graficamente erba)
	"~": [1, Vector2i(1, 2)],   # acqua
	"=": [0, Vector2i(1, 9)],   # ponte
	",": [0, Vector2i(4, 3)],   # terra battuta
	":": [0, Vector2i(1, 9)],   # pavimentazione della piazza
	"#": [0, Vector2i(1, 8)],   # muro
	"+": [0, Vector2i(4, 9)],   # porta / barricata
	"C": [0, Vector2i(1, 4)],   # chiesa
	"G": [0, Vector2i(5, 4)],   # governo
	"A": [0, Vector2i(1, 6)],   # caserma
	"V": [1, Vector2i(6, 5)],   # blocco veicolare
	"t": [0, Vector2i(4, 0)],   # albero
	"o": [0, Vector2i(10, 8)],  # barile
	"x": [0, Vector2i(9, 3)],   # sacchi di sabbia
}
const BLOCCANTI := "~#CGAVtox"

## Le nove facce del muro di cinta nell'atlante tiny-town: e' un blocco 3x3,
## angoli sugli spigoli e lati sui bordi.
const MURO := {
	"alto": Vector2i(1, 8), "basso": Vector2i(1, 10),
	"sinistra": Vector2i(0, 9), "destra": Vector2i(2, 9),
	"ang_as": Vector2i(0, 8), "ang_ad": Vector2i(2, 8),
	"ang_bs": Vector2i(0, 10), "ang_bd": Vector2i(2, 10),
}

var larghezza: int
var altezza: int
var griglia: PackedStringArray
var spawn_zombie: Array[Vector2i] = []
var fronti := {"nord": [], "fianchi": [], "sud": []}   # spawn raggruppati per lato
var porte: Array[Vector2i] = []
var piazza: Array[Vector2i] = []

var varchi: Array = []          # gruppi contigui di celle "+": ogni gruppo e' una barricata
var edifici := {}               # carattere "C"/"G"/"A" -> celle di quell'edificio

var _solidi_extra := {}         # celle rese solide a runtime (barricate in piedi)
var _astar := AStarGrid2D.new()
var _layer := TileMapLayer.new()

func _ready() -> void:
	add_to_group("mondo")
	griglia = FileAccess.get_file_as_string("res://assets/map.txt").strip_edges().split("\n")
	altezza = griglia.size()
	larghezza = griglia[0].length()
	_layer.tile_set = _costruisci_tileset()
	add_child(_layer)
	_dipingi()
	_crea_collisioni()
	_prepara_astar()
	varchi = _raggruppa(porte)
	for ch in ["C", "G", "A"]:
		edifici[ch] = _celle_con(ch)

func carattere(c: Vector2i) -> String:
	if c.x < 0 or c.y < 0 or c.x >= larghezza or c.y >= altezza:
		return "#"
	return griglia[c.y][c.x]

func bloccato(c: Vector2i) -> bool:
	return BLOCCANTI.contains(carattere(c)) or _solidi_extra.has(c)

## Le barricate aprono e chiudono varchi a partita in corso: A* e collisioni
## devono restare d'accordo, quindi passano tutte da qui.
func imposta_solido(c: Vector2i, solido: bool) -> void:
	if solido:
		_solidi_extra[c] = true
	else:
		_solidi_extra.erase(c)
	_astar.set_point_solid(c, solido)

func dipingi_cella(c: Vector2i, ch: String) -> void:
	var t: Array = TILES.get(ch, TILES["."])
	_layer.set_cell(c, t[0], t[1])

func centro(c: Vector2i) -> Vector2:
	return Vector2(c.x + 0.5, c.y + 0.5) * T

func a_cella(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))

## Percorso in pixel. Vuoto se non esiste.
func percorso(da: Vector2, a: Vector2) -> PackedVector2Array:
	var c0 := a_cella(da)
	var c1 := a_cella(a)
	if bloccato(c0) or bloccato(c1):
		return PackedVector2Array()
	return _astar.get_point_path(c0, c1)

## Il cuore della citta': obiettivo finale degli zombie.
func piazza_centro() -> Vector2:
	var somma := Vector2.ZERO
	for c in piazza:
		somma += centro(c)
	return somma / maxi(piazza.size(), 1)

func _costruisci_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	for i in ATLANTI.size():
		var tex: Texture2D = load(ATLANTI[i])
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(T, T)
		# creiamo ogni tile dell'atlante: cosi' cambiare un indice in TILES
		# non richiede di toccare nient'altro
		for y in tex.get_height() / T:
			for x in tex.get_width() / T:
				src.create_tile(Vector2i(x, y))
		ts.add_source(src, i)
	return ts

func _dipingi() -> void:
	for y in altezza:
		for x in larghezza:
			var ch := griglia[y][x]
			var t: Array = TILES.get(ch, TILES["."])
			if ch == "#":
				_layer.set_cell(Vector2i(x, y), 0, _faccia_muro(x, y))
			else:
				_layer.set_cell(Vector2i(x, y), t[0], t[1])
			match ch:
				"S":
					spawn_zombie.append(Vector2i(x, y))
					if y < altezza / 3:
						fronti["nord"].append(Vector2i(x, y))
					elif x == 0 or x == larghezza - 1:
						fronti["fianchi"].append(Vector2i(x, y))
					else:
						fronti["sud"].append(Vector2i(x, y))
				"+": porte.append(Vector2i(x, y))
				":": piazza.append(Vector2i(x, y))

## Un rettangolo per ogni sequenza orizzontale di celle bloccate: molti meno
## corpi fisici che uno per tile.
func _crea_collisioni() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for y in altezza:
		var x := 0
		while x < larghezza:
			if not bloccato(Vector2i(x, y)):
				x += 1
				continue
			var inizio := x
			while x < larghezza and bloccato(Vector2i(x, y)):
				x += 1
			var forma := RectangleShape2D.new()
			forma.size = Vector2((x - inizio) * T, T)
			var cs := CollisionShape2D.new()
			cs.shape = forma
			cs.position = Vector2((inizio + x) * 0.5 * T, (y + 0.5) * T)
			body.add_child(cs)

func _prepara_astar() -> void:
	_astar.region = Rect2i(0, 0, larghezza, altezza)
	_astar.cell_size = Vector2(T, T)
	_astar.offset = Vector2(T, T) * 0.5
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	for y in altezza:
		for x in larghezza:
			if bloccato(Vector2i(x, y)):
				_astar.set_point_solid(Vector2i(x, y), true)

## Sceglie la faccia giusta del muro guardando i vicini. Assunzione: la
## fortificazione e' convessa e la piazza sta al centro -- vale per Ponte Milvio,
## se un giorno disegneremo mura concave qui servira' un autotile vero.
func _faccia_muro(x: int, y: int) -> Vector2i:
	var su := carattere(Vector2i(x, y - 1)) == "#"
	var giu := carattere(Vector2i(x, y + 1)) == "#"
	var sx := carattere(Vector2i(x - 1, y)) == "#"
	var dx := carattere(Vector2i(x + 1, y)) == "#"
	var sopra := y < altezza / 2
	var a_sinistra := x < larghezza / 2
	if (sx or dx) and (su or giu):
		if sopra:
			return MURO["ang_as"] if a_sinistra else MURO["ang_ad"]
		return MURO["ang_bs"] if a_sinistra else MURO["ang_bd"]
	if su or giu:
		return MURO["sinistra"] if a_sinistra else MURO["destra"]
	return MURO["alto"] if sopra else MURO["basso"]

func _celle_con(ch: String) -> Array[Vector2i]:
	var fuori: Array[Vector2i] = []
	for y in altezza:
		for x in larghezza:
			if griglia[y][x] == ch:
				fuori.append(Vector2i(x, y))
	return fuori

## Celle adiacenti = un solo oggetto. Cosi' una porta larga 4 tile e' una
## barricata sola con una barra di vita sola, non quattro.
func _raggruppa(celle: Array[Vector2i]) -> Array:
	var gruppi: Array = []
	var restanti := celle.duplicate()
	while not restanti.is_empty():
		var gruppo: Array[Vector2i] = []
		var coda: Array[Vector2i] = [restanti.pop_back()]
		while not coda.is_empty():
			var c: Vector2i = coda.pop_back()
			gruppo.append(c)
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var i := restanti.find(c + d)
				if i >= 0:
					coda.append(restanti[i])
					restanti.remove_at(i)
		gruppi.append(gruppo)
	return gruppi
