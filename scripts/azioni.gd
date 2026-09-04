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

## Senza questo, dopo un ritorno al menu `istanza` punta a un nodo liberato.
func _exit_tree() -> void:
	if istanza == self:
		istanza = null

func _process(delta: float) -> void:
	for chiave in _ricarica:
		if _ricarica[chiave] > 0.0:
			_ricarica[chiave] = maxf(_ricarica[chiave] - delta, 0.0)

func per_fazione(fazione: int) -> Array:
	return Balance.AZIONI.filter(func(a): return a["fazione"] == fazione or a["fazione"] == -1)

## La ricarica e' per fazione: prima la Spedizione aveva una chiave sola per
## tutti e tre, quindi quando la lanciava un'IA il tuo tasto si spegneva.
func _chiave(id: String, esecutore: int) -> String:
	return "%s:%d" % [id, esecutore]

func quota_ricarica(id: String, esecutore := -99) -> float:
	if esecutore == -99:
		esecutore = GameState.fazione_effettiva()
	var a := _trova(id)
	if a.is_empty() or a["ricarica"] <= 0.0:
		return 0.0
	return float(_ricarica.get(_chiave(id, esecutore), 0.0)) / a["ricarica"]

func azioni_rimaste(esecutore: int) -> int:
	return Balance.AZIONI_PER_GIORNO - GameState.azioni_usate[esecutore]

func eseguibile(id: String, esecutore := -99) -> bool:
	if esecutore == -99:
		esecutore = GameState.fazione_effettiva()
	var a := _trova(id)
	if a.is_empty() or float(_ricarica.get(_chiave(id, esecutore), 0.0)) > 0.0:
		return false
	# si decide di giorno e si sopravvive di notte: prima le azioni giravano
	# anche di notte e il giocatore ne faceva tre per ogni azione dell'IA
	if GameState.fase != GameState.Fase.GIORNO:
		return false
	if azioni_rimaste(esecutore) <= 0:
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

func esegui(id: String, esecutore := -99) -> bool:
	if esecutore == -99:
		esecutore = GameState.fazione_effettiva()
	# un client non applica niente da solo: chiede, e chi ospita decide
	if Rete.online() and not Rete.e_il_server():
		Relay.azioni_da_spedire.append(id)
		return true
	if Rete.in_rete and not multiplayer.is_server():
		_chiedi.rpc_id(1, id, esecutore)
		return true
	if not eseguibile(id, esecutore):
		Audio.suona("negato", -12.0)
		return false
	var a := _trova(id)
	_ricarica[_chiave(id, esecutore)] = a["ricarica"]
	GameState.azioni_usate[esecutore] += 1
	for campo in a.get("effetti", {}):
		GameState.modifica(campo, a["effetti"][campo])
	if a.has("speciale"):
		_speciale(a["speciale"], esecutore)
	Audio.suona("azione", -10.0)
	return true

@rpc("any_peer", "call_remote", "reliable")
func _chiedi(id: String, esecutore: int) -> void:
	# il mittente non puo' spacciarsi per un'altra fazione
	var chi: int = Rete.fazioni.get(multiplayer.get_remote_sender_id(), -1)
	if chi < 0:
		return
	if GameState.deposta == chi:
		chi = GameState.Faction.RIBELLE
	if chi != esecutore:
		return
	esegui(id, esecutore)

func _trova(id: String) -> Dictionary:
	for a in Balance.AZIONI:
		if a["id"] == id:
			return a
	return {}

## `mia` prima leggeva la fazione del GIOCATORE invece di quella di chi esegue:
## se un'IA deposta sabotava, i punti potere finivano al giocatore.
func _speciale(nome: String, mia: int) -> void:
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
			# non risuscita i varchi gia' caduti: risigillare una breccia deve
			# costare il leader sul posto col tasto E
			for b in get_tree().get_nodes_in_group("barricata"):
				if b.in_piedi:
					b.ripara(Balance.BARRICATA_VITA * Balance.RINFORZA_QUOTA)
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
			# nessun annuncio: gli altri vedono una barricata che cede, non un
			# colpevole. E' l'unica azione del gioco che non lascia firma.
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

const SCENA_GUARDIA := preload("res://scenes/guardia.tscn")

func _recluta(dove: Vector2) -> void:
	var g: Guardia = SCENA_GUARDIA.instantiate()
	g.mondo = mondo
	g.global_position = mondo.centro(mondo.a_cella(dove))
	contenitore_guardie.add_child(g, true)
