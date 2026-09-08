extends Node3D
class_name Mondo3D
## Costruisce la citta' in 3D dalla STESSA assets/map.txt del gioco 2D.
##
## Non e' un secondo progetto: la mappa resta l'unica fonte di verita', quindi
## spostare un muro nel file di testo lo sposta in entrambe le versioni. Cosi'
## il 3D non parte da zero e non diverge.
##
## Questo e' un blockout: volumi giusti alle misure giuste, nessun modello.
## Serve a capire se camminarci dentro funziona, prima di spendere un'ora di
## modellazione su qualcosa che magari va buttato.

const PASSO := 3.0        # metri per casella: una piazza di 40x52 caselle = 120x156 m
const ALTEZZA_MURO := 6.0
const ALTEZZA_EDIFICIO := 12.0

const COLORI := {
	".": Color(0.36, 0.47, 0.26),   # erba
	",": Color(0.52, 0.42, 0.31),   # terra battuta
	":": Color(0.50, 0.49, 0.47),   # selciato della piazza
	"=": Color(0.60, 0.58, 0.54),   # ponte
	"~": Color(0.16, 0.29, 0.40),   # fiume
	"S": Color(0.36, 0.47, 0.26),
	"V": Color(0.30, 0.30, 0.32),
}
const ALTI := {
	"#": [ALTEZZA_MURO, Color(0.58, 0.56, 0.52)],
	"+": [1.2, Color(0.42, 0.31, 0.20)],           # barricata: bassa, si scavalca con lo sguardo
	"C": [ALTEZZA_EDIFICIO * 1.4, Color(0.62, 0.60, 0.56)],
	"G": [ALTEZZA_EDIFICIO, Color(0.60, 0.36, 0.32)],
	"M": [ALTEZZA_EDIFICIO * 0.8, Color(0.45, 0.38, 0.30)],
	# il tufo di Ponte Milvio: piloni e Torretta nello stesso materiale
	"A": [9.0, Color(0.68, 0.63, 0.52)],
	"T": [17.0, Color(0.72, 0.67, 0.56)],
	"t": [4.0, Color(0.20, 0.34, 0.18)],
	"o": [1.0, Color(0.44, 0.32, 0.22)],
	"x": [1.0, Color(0.50, 0.46, 0.34)],
}

var griglia: PackedStringArray
var larghezza := 0
var altezza := 0

func _ready() -> void:
	var testo := FileAccess.get_file_as_string("res://assets/map.txt").strip_edges()
	if testo.is_empty():
		push_error("assets/map.txt non trovato")
		return
	griglia = testo.split("\n")
	altezza = griglia.size()
	larghezza = griglia[0].length()
	_terreno()
	_volumi()
	_pavimento()
	_cielo()

func carattere(x: int, y: int) -> String:
	if x < 0 or y < 0 or x >= larghezza or y >= altezza:
		return "."
	return griglia[y][x]

func centro_mondo() -> Vector3:
	return Vector3(larghezza * PASSO * 0.5, 0.0, altezza * PASSO * 0.5)

## Una piastrella per casella. Un MultiMesh per colore: duemila oggetti separati
## affosserebbero il framerate, un'istanza sola per colore no.
func _terreno() -> void:
	var per_colore := {}
	for y in altezza:
		for x in larghezza:
			var ch := carattere(x, y)
			var c: Color = COLORI.get(ch, Color(0.52, 0.42, 0.31))
			var chiave := c.to_html()
			if not per_colore.has(chiave):
				per_colore[chiave] = {"colore": c, "punti": []}
			var giu := -0.35 if ch == "~" else 0.0
			per_colore[chiave]["punti"].append(Vector3(x * PASSO, giu, y * PASSO))
	for chiave in per_colore:
		var d = per_colore[chiave]
		var m := BoxMesh.new()
		m.size = Vector3(PASSO, 0.3, PASSO)
		_riempi(m, d["colore"], d["punti"], 0.15, false)

## Il terreno era solo grafica: senza un pavimento solido il giocatore cadeva
## nel vuoto e la camera inquadrava il cielo da sessanta metri sotto la citta'.
func _pavimento() -> void:
	var corpo := StaticBody3D.new()
	corpo.name = "Pavimento"
	add_child(corpo)
	var piano := WorldBoundaryShape3D.new()
	piano.plane = Plane(Vector3.UP, 0.15)
	var cs := CollisionShape3D.new()
	cs.shape = piano
	corpo.add_child(cs)

	# il fiume non si attraversa a piedi: solo dal ponte
	var acqua := StaticBody3D.new()
	acqua.name = "Fiume"
	add_child(acqua)
	for y in altezza:
		for x in larghezza:
			if carattere(x, y) != "~":
				continue
			var b := BoxShape3D.new()
			b.size = Vector3(PASSO, 4.0, PASSO)
			var c := CollisionShape3D.new()
			c.shape = b
			c.position = Vector3(x * PASSO, 2.0, y * PASSO)
			acqua.add_child(c)

func _volumi() -> void:
	var per_tipo := {}
	for y in altezza:
		for x in larghezza:
			var ch := carattere(x, y)
			if not ALTI.has(ch):
				continue
			if not per_tipo.has(ch):
				per_tipo[ch] = []
			per_tipo[ch].append(Vector3(x * PASSO, 0.0, y * PASSO))
	for ch in per_tipo:
		var h: float = ALTI[ch][0]
		var m := BoxMesh.new()
		m.size = Vector3(PASSO, h, PASSO)
		_riempi(m, ALTI[ch][1], per_tipo[ch], h * 0.5, true)

func _riempi(forma: Mesh, colore: Color, punti: Array, alza: float, con_urto: bool) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colore
	mat.roughness = 0.9
	forma.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = forma
	mm.instance_count = punti.size()
	for i in punti.size():
		mm.set_instance_transform(i, Transform3D(Basis(), punti[i] + Vector3(0, alza, 0)))
	var nodo := MultiMeshInstance3D.new()
	nodo.multimesh = mm
	# Senza un volume d'ingombro esplicito Godot calcola quello della singola
	# scatola e scarta l'intero MultiMesh appena l'origine esce dall'inquadratura:
	# la citta' c'era ma non si vedeva mai.
	nodo.custom_aabb = AABB(Vector3(-PASSO, -PASSO, -PASSO),
		Vector3(larghezza * PASSO + PASSO * 2, 40.0, altezza * PASSO + PASSO * 2))
	add_child(nodo)

	if not con_urto:
		return
	# i volumi alti fermano il giocatore: un corpo statico con una scatola per casella
	var corpo := StaticBody3D.new()
	add_child(corpo)
	for p in punti:
		var forma_urto := BoxShape3D.new()
		forma_urto.size = (forma as BoxMesh).size
		var cs := CollisionShape3D.new()
		cs.shape = forma_urto
		cs.position = p + Vector3(0, alza, 0)
		corpo.add_child(cs)

func _cielo() -> void:
	var sole := DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-52, -35, 0)
	sole.light_energy = 0.85
	sole.shadow_enabled = true
	add_child(sole)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.72   # senza, piazza e chiesa bruciavano a bianco pieno
	amb.environment = env
	add_child(amb)
