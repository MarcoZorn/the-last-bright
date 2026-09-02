extends Node2D
## Monta la scena e guida il ciclo giorno/notte.
## Giorno: ripari, costruisci, incassi. Notte: arrivano e devi reggere.

const PLAYER := preload("res://scenes/player.tscn")
const ZOMBIE := preload("res://scenes/zombie.tscn")

var mondo: World
var _zombie: Node2D
var _da_spawnare := 0
var _prossimo_spawn := 0.0
var _vita_totale_barricate := 0.0

func _ready() -> void:
	mondo = preload("res://scripts/world.gd").new()
	add_child(mondo)

	var barricate := Node2D.new()
	add_child(barricate)
	for gruppo in mondo.varchi:
		var b := Barricata.new()
		b.mondo = mondo
		b.celle.assign(gruppo)
		barricate.add_child(b)
	_vita_totale_barricate = mondo.varchi.size() * Balance.BARRICATA_VITA

	_zombie = Node2D.new()
	add_child(_zombie)
	var guardie := Node2D.new()
	add_child(guardie)

	var p: Player = PLAYER.instantiate()
	p.global_position = mondo.piazza_centro()
	p.mondo = mondo
	p.guardie = guardie
	add_child(p)

	add_child(preload("res://scripts/hud.gd").new())

	if "--shot" in OS.get_cmdline_user_args():
		_scatta_panoramica()

func _process(delta: float) -> void:
	if GameState.finita:
		return
	GameState.tempo_fase += delta
	_aggiorna_sicurezza()
	if GameState.fase == GameState.Fase.GIORNO:
		if GameState.tempo_fase >= Balance.GIORNO_DURATA:
			_inizia_notte()
	else:
		_notte(delta)

## La sicurezza dell'Esercito non e' un numero libero: e' lo stato reale delle
## mura. Non si puo' barare sul proprio indicatore.
func _aggiorna_sicurezza() -> void:
	var somma := 0.0
	for b in get_tree().get_nodes_in_group("barricata"):
		somma += b.vita
	GameState.sicurezza = 100.0 * somma / maxf(_vita_totale_barricate, 1.0)

func _inizia_notte() -> void:
	_da_spawnare = Balance.ONDATA_BASE + Balance.ONDATA_CRESCITA * (GameState.giorno - 1)
	_prossimo_spawn = 0.0
	GameState.cambia_fase(GameState.Fase.NOTTE)

func _notte(delta: float) -> void:
	_prossimo_spawn -= delta
	if _da_spawnare > 0 and _prossimo_spawn <= 0.0 and _zombie.get_child_count() < Balance.ZOMBIE_MAX:
		_prossimo_spawn = Balance.SPAWN_RITMO
		_da_spawnare -= 1
		_genera()
	var finito: bool = _da_spawnare == 0 and _zombie.get_child_count() == 0
	if finito or GameState.tempo_fase > Balance.NOTTE_MAX:
		GameState.cambia_fase(GameState.Fase.GIORNO)

func _genera() -> void:
	var cella: Vector2i = mondo.spawn_zombie.pick_random()
	var z: Zombie = ZOMBIE.instantiate()
	z.mondo = mondo
	z.global_position = mondo.centro(cella) + Vector2(randf_range(-24, 24), randf_range(-16, 16))
	_zombie.add_child(z)

## Debug: `godot -- --shot` salva una panoramica della mappa e esce.
func _scatta_panoramica() -> void:
	var cam := Camera2D.new()
	cam.zoom = Vector2(0.82, 0.82)
	cam.global_position = mondo.centro(Vector2i(mondo.larghezza / 2, mondo.altezza / 2))
	add_child(cam)
	cam.make_current()
	if "--notte" in OS.get_cmdline_user_args():
		_inizia_notte()
		for i in 40:
			_notte(Balance.SPAWN_RITMO)
	await get_tree().create_timer(18.0 if "--notte" in OS.get_cmdline_user_args() else 2.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/lastbright_shot.png")
	get_tree().quit()
