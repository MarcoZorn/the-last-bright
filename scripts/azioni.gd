extends Node
class_name Azioni
## Esegue le azioni delle fazioni. La tabella sta in Balance.AZIONI: aggiungere
## un'azione e' aggiungere una riga li', non toccare questo file -- a meno che
## non serva un effetto "speciale", che si aggancia nel match in fondo.

static var istanza: Azioni

var mondo: World
var contenitore_guardie: Node2D

var _ricarica := {}   # id azione -> secondi rimanenti

func _ready() -> void:
	istanza = self
	for a in Balance.AZIONI:
		_ricarica[a["id"]] = 0.0

func _process(delta: float) -> void:
	for id in _ricarica:
		if _ricarica[id] > 0.0:
			_ricarica[id] = maxf(_ricarica[id] - delta, 0.0)

func per_fazione(fazione: int) -> Array:
	return Balance.AZIONI.filter(func(a): return a["fazione"] == fazione or a["fazione"] == -1)

func quota_ricarica(id: String) -> float:
	var a := _trova(id)
	if a.is_empty() or a["ricarica"] <= 0.0:
		return 0.0
	return _ricarica[id] / a["ricarica"]

func eseguibile(id: String) -> bool:
	var a := _trova(id)
	if a.is_empty() or _ricarica[id] > 0.0:
		return false
	if id == "licenzia":
		return not get_tree().get_nodes_in_group("guardia").is_empty()
	if id == "addestramento":
		return GameState.livello_guardie < Balance.GUARDIA_LIVELLO_MAX \
			and GameState.denaro >= GameState.costo_addestramento()
	for campo in a.get("effetti", {}):
		var delta: float = a["effetti"][campo]
		if delta < 0.0 and GameState.get(campo) + delta < 0.0:
			return false
	return true

func esegui(id: String) -> bool:
	if not eseguibile(id):
		Audio.suona("negato", -12.0)
		return false
	var a := _trova(id)
	_ricarica[id] = a["ricarica"]
	for campo in a.get("effetti", {}):
		GameState.modifica(campo, a["effetti"][campo])
	if a.has("speciale"):
		_speciale(a["speciale"])
	Audio.suona("azione", -10.0)
	GameState.cambiato.emit()
	return true

func _trova(id: String) -> Dictionary:
	for a in Balance.AZIONI:
		if a["id"] == id:
			return a
	return {}

func _speciale(nome: String) -> void:
	var mia: int = GameState.fazione_effettiva()
	match nome:
		"scomunica":
			# colpisce chi comanda davvero, non a caso
			var forte := 0
			for f in 3:
				if f != 0 and GameState.potere[f] > GameState.potere[forte]:
					forte = f
			GameState.sposta_potere(forte, 0, 8.0)
			GameState.annuncio.emit("Scomunica contro %s" % GameState.NOMI[forte], Color(1, 0.9, 0.6))
		"decreto":
			GameState.sposta_potere(-1, 1, 6.0)
		"coprifuoco":
			GameState.sposta_potere(-1, 2, 6.0)
		"ripara_tutto":
			for b in get_tree().get_nodes_in_group("barricata"):
				b.ripara(Balance.BARRICATA_VITA)
		"addestramento":
			GameState.modifica("denaro", -GameState.costo_addestramento())
			GameState.addestramenti += 1
			GameState.livello_guardie += 1
			GameState.annuncio.emit("Guardie di livello %d" % GameState.livello_guardie, Color(0.6, 0.9, 1))
		"licenzia":
			var scelte := get_tree().get_nodes_in_group("guardia")
			if scelte.is_empty():
				return
			var congedata = scelte.filter(func(g): return g.selezionata)
			var chi = congedata[0] if not congedata.is_empty() else scelte[0]
			chi.queue_free()
			GameState.modifica("denaro", Balance.GUARDIA_LIQUIDAZIONE)
		"leva":
			for i in 2:
				_recluta(mondo.piazza_centro() + Vector2(randf_range(-30, 30), randf_range(-30, 30)))
		"sabota":
			var in_piedi := get_tree().get_nodes_in_group("barricata").filter(func(b): return b.in_piedi)
			if not in_piedi.is_empty():
				in_piedi.pick_random().subisci(Balance.BARRICATA_VITA * 0.5)
			GameState.sposta_potere(2, mia if mia < 3 else GameState.deposta, 6.0)
		"voci":
			GameState.sposta_potere(0, GameState.deposta, 6.0)
		"furto":
			GameState.modifica("denaro", -40.0)
			GameState.sposta_potere(1, GameState.deposta, 5.0)
		"spedizione":
			Audio.suona("porta", -8.0)
			var s := Spedizione.new()
			add_child(s)

func _recluta(dove: Vector2) -> void:
	var g := Guardia.new()
	g.mondo = mondo
	g.global_position = mondo.centro(mondo.a_cella(dove))
	contenitore_guardie.add_child(g)
