class_name Grafica
## Piccoli tocchi visivi condivisi da tutto quello che si muove.
## Non sono decorazione fine a se stessa: l'ombra ancora le figure al terreno e
## il passo distingue a colpo d'occhio chi si muove da chi e' fermo.

static func ombra(genitore: Node2D, raggio := 5.0) -> void:
	var p := Polygon2D.new()
	var punti := PackedVector2Array()
	for i in 12:
		punti.append(Vector2(cos(TAU * i / 12.0) * raggio, sin(TAU * i / 12.0) * raggio * 0.42))
	p.polygon = punti
	p.color = Color(0, 0, 0, 0.25)
	p.position = Vector2(0, 6)
	p.z_index = -1
	genitore.add_child(p)

## Ondeggio del passo + specchiatura secondo la direzione.
static func passo(sprite: Sprite2D, velocita: Vector2, tempo: float) -> void:
	if velocita.length() < 1.0:
		sprite.position.y = 0.0
		return
	sprite.position.y = -absf(sin(tempo * 11.0)) * 1.8
	if absf(velocita.x) > 1.0:
		sprite.flip_h = velocita.x < 0.0

static func schizzo(genitore: Node, dove: Vector2, colore: Color, quanti := 7) -> void:
	for i in quanti:
		var g := ColorRect.new()
		g.color = colore
		g.size = Vector2(2, 2)
		g.global_position = dove
		g.z_index = 40
		genitore.add_child(g)
		var verso := Vector2.RIGHT.rotated(randf() * TAU) * randf_range(6.0, 18.0)
		var t := g.create_tween()
		t.set_parallel()
		t.tween_property(g, "global_position", dove + verso, 0.35)
		t.tween_property(g, "modulate:a", 0.0, 0.35)
		t.chain().tween_callback(g.queue_free)

## Scossone della telecamera: si sente quando una porta cede anche se stai
## guardando dall'altra parte della citta'.
static func scossa(camera: Camera2D, forza := 4.0) -> void:
	if camera == null:
		return
	var t := camera.create_tween()
	for i in 6:
		t.tween_property(camera, "offset",
			Vector2(randf_range(-forza, forza), randf_range(-forza, forza)), 0.04)
	t.tween_property(camera, "offset", Vector2.ZERO, 0.08)
