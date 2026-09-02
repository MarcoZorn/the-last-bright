extends Label
class_name DannoFluttuante
## Il numerino che sale quando colpisci. Serve solo a far capire che il colpo
## e' andato a segno: senza, non si distingue un attacco che funziona da uno no.

static func mostra(genitore: Node, dove: Vector2, testo: String, colore := Color.WHITE) -> void:
	var l := DannoFluttuante.new()
	l.text = testo
	l.modulate = colore
	l.global_position = dove + Vector2(randf_range(-4, 4), -10)
	l.add_theme_font_size_override("font_size", 11)
	l.z_index = 100
	genitore.add_child(l)
	var t := l.create_tween()
	t.set_parallel()
	t.tween_property(l, "position:y", l.position.y - 16.0, 0.6)
	t.tween_property(l, "modulate:a", 0.0, 0.6)
	t.chain().tween_callback(l.queue_free)
