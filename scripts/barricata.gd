extends Node2D
class_name Barricata
## Un varco nelle mura. Finche' e' in piedi e' un muro a tutti gli effetti
## (solido per la fisica E per il pathfinding); quando cade diventa una breccia
## e gli zombie ci si infilano da soli, senza che nessuno glielo dica.

var mondo: World
var celle: Array[Vector2i] = []
var vita: float = Balance.BARRICATA_VITA
var in_piedi := true

var _corpo: StaticBody2D
var _approcci: PackedVector2Array

func _ready() -> void:
	add_to_group("barricata")
	_chiudi()
	for c in celle:
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not mondo.bloccato(c + d):
				_approcci.append(mondo.centro(c + d))

## Dove deve arrivare uno zombie per poterla picchiare.
func punto_approccio(da: Vector2) -> Vector2:
	var migliore := da
	var d_min := INF
	for p in _approcci:
		var d := da.distance_squared_to(p)
		if d < d_min:
			d_min = d
			migliore = p
	return migliore

func distanza(p: Vector2) -> float:
	var d_min := INF
	for c in celle:
		d_min = minf(d_min, p.distance_to(mondo.centro(c)))
	return d_min

func danneggia(quanto: float) -> void:
	if not in_piedi:
		return
	vita -= quanto
	if vita <= 0.0:
		vita = 0.0
		in_piedi = false
		_apri()

## Riparabile anche da caduta: risigillare una breccia costa, ma si puo' fare.
func ripara(quanto: float) -> void:
	vita = minf(vita + quanto, Balance.BARRICATA_VITA)
	if not in_piedi and vita > 0.0:
		in_piedi = true
		_chiudi()

func _chiudi() -> void:
	_corpo = StaticBody2D.new()
	_corpo.collision_layer = 1
	_corpo.collision_mask = 0
	add_child(_corpo)
	for c in celle:
		mondo.imposta_solido(c, true)
		mondo.dipingi_cella(c, "+")
		var forma := RectangleShape2D.new()
		forma.size = Vector2.ONE * Balance.TILE
		var cs := CollisionShape2D.new()
		cs.shape = forma
		cs.position = mondo.centro(c)
		_corpo.add_child(cs)

func _apri() -> void:
	for c in celle:
		mondo.imposta_solido(c, false)
		mondo.dipingi_cella(c, ",")
	if is_instance_valid(_corpo):
		_corpo.queue_free()
