extends Node
## godot --headless --audio-driver Dummy res://tools/sim.tscn
## Gioca partite intere da solo, a velocita' moltiplicata, e dice come vanno a
## finire. Serve a rispondere all'unica domanda che i test non coprono: il gioco
## e' tarato? Se il bot vince sempre e' troppo facile, se muore al giorno due
## e' troppo difficile.

const PARTITE := 5
const VELOCITA := 30.0

var _fatte := 0
var _esiti: Array = []
var _partita: Node
var _inizio := 0.0

func _ready() -> void:
	Engine.time_scale = VELOCITA
	_nuova()

func _nuova() -> void:
	GameState.ripristina()
	GameState.senza_umano = true
	_inizio = Time.get_ticks_msec() / 1000.0
	_partita = load("res://scenes/main.tscn").instantiate()
	add_child(_partita)

func _process(_delta: float) -> void:
	if _partita == null or not GameState.finita:
		return
	var causa := "vittoria"
	if not GameState.vinta:
		causa = "popolazione a zero" if GameState.popolazione == 0 else "edifici distrutti"
	_esiti.append({
		"giorno": GameState.giorno, "vinta": GameState.vinta, "causa": causa,
		"morale": GameState.morale, "denaro": GameState.denaro, "viveri": GameState.viveri,
		"uccisi": GameState.zombie_uccisi, "deposta": GameState.deposta,
	})
	print("  partita %d: giorno %d, %s  (morale %.0f, denaro %.0f, viveri %.0f, uccisi %d)" % [
		_esiti.size(), GameState.giorno, causa, GameState.morale, GameState.denaro,
		GameState.viveri, GameState.zombie_uccisi])
	_partita.queue_free()
	_partita = null
	_fatte += 1
	if _fatte >= PARTITE:
		_riassunto()
		get_tree().quit()
	else:
		_nuova.call_deferred()

func _riassunto() -> void:
	var vinte := 0
	var giorni := 0.0
	var golpe := 0
	for e in _esiti:
		vinte += 1 if e["vinta"] else 0
		giorni += e["giorno"]
		golpe += 1 if e["deposta"] >= 0 else 0
	print("\n  RIASSUNTO su %d partite giocate dall'IA" % _esiti.size())
	print("  vittorie      %d / %d" % [vinte, _esiti.size()])
	print("  giorno medio  %.1f (si vince a %d)" % [giorni / _esiti.size(), Balance.GIORNI_PER_VINCERE])
	print("  con un golpe  %d / %d" % [golpe, _esiti.size()])
	print("\n  Lettura: l'IA gioca a caso, quindi e' il pavimento del gioco.")
	print("  Se vince quasi sempre, per un umano e' banale.")
