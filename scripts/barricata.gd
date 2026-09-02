extends Node2D
class_name Barricata
## Un varco nelle mura. Finche' e' in piedi e' un muro a tutti gli effetti
## (solido per la fisica E per il pathfinding); quando cade diventa una breccia
## e gli zombie ci si infilano da soli, senza che nessuno glielo dica.

var mondo: World
var celle: Array[Vector2i] = []
var vita: float = Balance.BARRICATA_VITA
var in_piedi := true
var sotto_attacco := 0.0   # secondi da cui sta prendendo colpi: lo legge l'HUD

var _corpo: StaticBody2D
var _barra: BarraVita
var _approcci: PackedVector2Array

func _ready() -> void:
	add_to_group("barricata")
	add_to_group("danneggiabile")
	_chiudi()
	for c in celle:
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not mondo.bloccato(c + d):
				_approcci.append(mondo.centro(c + d))
	_crea_barra()

## Barra di vita sopra il varco: senza, non si capisce quale porta sta cedendo.
func _crea_barra() -> void:
	var centro_visivo := Vector2.ZERO
	for c in celle:
		centro_visivo += mondo.centro(c)
	_barra = BarraVita.new(34.0, 0.0)
	add_child(_barra)
	_barra.global_position = centro_visivo / celle.size() - Vector2(17, 14)
	_barra.aggiorna(1.0)

func attaccabile() -> bool:
	return in_piedi

func _process(d: float) -> void:
	sotto_attacco = maxf(sotto_attacco - d, 0.0)

## Punto medio del varco: lo usa l'HUD per la freccia di allarme.
func centro_varco() -> Vector2:
	var c := Vector2.ZERO
	for cella in celle:
		c += mondo.centro(cella)
	return c / celle.size()

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

func subisci(quanto: float, _spinta := Vector2.ZERO) -> void:
	if not in_piedi:
		return
	sotto_attacco = 2.0
	vita -= quanto
	_barra.aggiorna(vita / Balance.BARRICATA_VITA)
	if vita <= 0.0:
		vita = 0.0
		in_piedi = false
		_apri()

## Riparabile anche da caduta: risigillare una breccia costa, ma si puo' fare.
func ripara(quanto: float) -> void:
	vita = minf(vita + quanto, Balance.BARRICATA_VITA)
	_barra.aggiorna(vita / Balance.BARRICATA_VITA)
	if not in_piedi and vita > 0.0:
		in_piedi = true
		_chiudi()

func _chiudi() -> void:
	_corpo = StaticBody2D.new()
	# livello 3: gli zombie lo intercettano, tu e le guardie no. I cancelli si
	# aprono dalla parte giusta, cosi' si puo' uscire in sortita.
	_corpo.collision_layer = 4
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
	GameState.annuncio.emit("UN VARCO E' CADUTO", Color(1, 0.35, 0.3))
	var cam := get_viewport().get_camera_2d()
	Grafica.scossa(cam, 6.0)
	for c in celle:
		mondo.imposta_solido(c, false)
		mondo.dipingi_cella(c, ",")
	if is_instance_valid(_corpo):
		_corpo.queue_free()
