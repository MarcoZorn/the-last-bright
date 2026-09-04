extends Node
## godot --headless --audio-driver Dummy res://tools/sim.tscn
## Gioca partite intere da solo, a velocita' moltiplicata, e dice come vanno a
## finire. Serve a rispondere all'unica domanda che i test non coprono: il gioco
## e' tarato? Se il bot vince sempre e' troppo facile, se muore al giorno due
## e' troppo difficile.

const PARTITE := 1
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
	Guardia.avvicinamento_minimo = INF
	_partita = load("res://scenes/main.tscn").instantiate()
	add_child(_partita)

func _process(_delta: float) -> void:
	if _partita == null or not GameState.finita:
		return
	var causa := "vittoria"
	if not GameState.vinta:
		causa = "popolazione a zero" if GameState.popolazione == 0 else "edifici distrutti"
	var guardie := get_tree().get_nodes_in_group("guardia").size()
	var varchi_caduti := get_tree().get_nodes_in_group("barricata").filter(
		func(b): return not b.in_piedi).size()
	_esiti.append({
		"giorno": GameState.giorno, "vinta": GameState.vinta, "causa": causa,
		"morale": GameState.morale, "denaro": GameState.denaro, "viveri": GameState.viveri,
		"uccisi": GameState.zombie_uccisi, "bruciati": GameState.zombie_bruciati, "deposta": GameState.deposta,
		"guardie": guardie, "perse": GameState.guardie_perse, "colpi": GameState.colpi_sparati, "mura": GameState.sicurezza, "varchi_caduti": varchi_caduti,
		"popolazione": GameState.popolazione,
	})
	# le colonne che contano per capire PERCHE' e' finita cosi'
	print("  partita %d | giorno %2d | %-20s | pop %3d | avvicinamento %4.0f | colpi %4d | uccisi %3d | bruciati %3d | guardie %d (-%d) | mura %3.0f%% | varchi giu' %d | morale %3.0f | $%4.0f | viveri %4.0f" % [
		_esiti.size(), GameState.giorno, causa, GameState.popolazione, Guardia.avvicinamento_minimo, GameState.colpi_sparati, GameState.zombie_uccisi, GameState.zombie_bruciati,
		guardie, GameState.guardie_perse, GameState.sicurezza, varchi_caduti, GameState.morale, GameState.denaro, GameState.viveri])
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
	var uccisi := 0
	var bruciati := 0
	var guardie := 0
	for e in _esiti:
		uccisi += e["uccisi"]
		bruciati += e["bruciati"]
		guardie += e["guardie"]
	var totale: float = maxf(uccisi + bruciati, 1)
	print("  per partita: %.1f uccisi, %.1f bruciati dall'alba (%.0f%% ammazzati)" % [
		float(uccisi) / _esiti.size(), float(bruciati) / _esiti.size(), 100.0 * uccisi / totale])
	var perse := 0
	for e in _esiti:
		perse += e["perse"]
	print("  guardie: %.1f vive alla fine, %.1f perse durante" % [
		float(guardie) / _esiti.size(), float(perse) / _esiti.size()])
	print("\n  Lettura: l'IA gioca a caso, quindi e' il pavimento del gioco.")
	print("  Se vince quasi sempre, per un umano e' banale.")
