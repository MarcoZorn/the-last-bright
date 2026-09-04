extends Node
## Multiplayer online che passa da una staffetta HTTP (`web/relay.php`).
##
## Nel browser ENet non esiste e su questo host non c'e' un WebSocket, quindi
## si fa a posta: chi ospita simula la partita e deposita un'istantanea ~8 volte
## al secondo, gli altri la leggono e depositano i propri comandi.
##
## Non e' elegante e la latenza si sente sui movimenti altrui (interpolati per
## non farli scattare). Ma funziona su qualunque hosting PHP, senza aprire
## porte, e a tutti basta un codice stanza.
## ponytail: se un giorno si attiva proxy_wstunnel sul server, si butta via
## tutto questo e si torna a WebSocketMultiplayerPeer, che riusa il codice di
## rete gia' scritto senza modifiche.

const INDIRIZZO := "https://aconite.dev/thelastbright/relay.php"
const RITMO := 0.12          # secondi fra un giro di posta e il successivo
const SCALA := 4.0           # quantizzazione delle posizioni: 1/4 di pixel

var stanza := ""
var mio_id := ""
var ospito := false
var collegato := false
var partita_in_corso := false   # chi ospita ha depositato la prima istantanea
var errore := ""
var fazioni := {}            # id -> fazione
var mia_fazione := 0

signal cambiato

var _http := HTTPRequest.new()
var _in_volo := false
var _fra_giri := 0.0
var _ultimo_turno := -1
var _da_applicare := {}      # ultima istantanea ricevuta, per chi non ospita
var _comandi_ricevuti: Array = []

func _ready() -> void:
	_http.timeout = 8.0
	add_child(_http)
	_http.request_completed.connect(_risposta)

func entra(codice: String) -> void:
	stanza = codice.strip_edges().to_upper()
	errore = ""
	_chiama("entra", "")

func esci() -> void:
	if collegato:
		_chiama("esci", "")
	collegato = false
	stanza = ""
	mio_id = ""
	ospito = false
	fazioni.clear()

func _process(delta: float) -> void:
	if not collegato or _in_volo:
		return
	_fra_giri -= delta
	if _fra_giri > 0.0:
		return
	_fra_giri = RITMO
	if ospito:
		_chiama("stato", JSON.stringify(_istantanea()))
	else:
		_chiama("leggi", JSON.stringify(_miei_comandi()))

func _chiama(azione: String, corpo: String) -> void:
	var url := "%s?r=%s&a=%s" % [INDIRIZZO, stanza, azione]
	if mio_id != "":
		url += "&id=" + mio_id
	_in_volo = true
	var esito := _http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, corpo)
	if esito != OK:
		_in_volo = false
		errore = "richiesta non partita"

func _risposta(_r: int, codice: int, _h: PackedStringArray, corpo: PackedByteArray) -> void:
	_in_volo = false
	if codice == 0:
		errore = "server irraggiungibile"
		cambiato.emit()
		return
	var d = JSON.parse_string(corpo.get_string_from_utf8())
	if typeof(d) != TYPE_DICTIONARY:
		errore = "risposta illeggibile"
		return
	if d.has("errore"):
		errore = str(d["errore"])
		if codice == 403 or codice == 409:
			collegato = false
		cambiato.emit()
		return

	errore = ""
	if d.has("id"):
		mio_id = str(d["id"])
		collegato = true
	if d.has("giocatori"):
		_leggi_giocatori(d["giocatori"])
	if d.has("comandi"):
		_comandi_ricevuti = d["comandi"]
	if d.has("istantanea") and d["istantanea"] != null and int(d.get("turno", -1)) != _ultimo_turno:
		_ultimo_turno = int(d.get("turno", -1))
		var i = JSON.parse_string(str(d["istantanea"]))
		if typeof(i) == TYPE_DICTIONARY:
			_da_applicare = i
			partita_in_corso = true
	cambiato.emit()

func _leggi_giocatori(elenco: Dictionary) -> void:
	fazioni.clear()
	for id in elenco:
		fazioni[id] = int(elenco[id]["fazione"])
		if id == mio_id:
			mia_fazione = int(elenco[id]["fazione"])
			ospito = bool(elenco[id]["ospite"])

## --- quello che si spedisce ---

func _istantanea() -> Dictionary:
	var d := {"s": GameState.istantanea()}
	var p := []
	for g in get_tree().get_nodes_in_group("player"):
		p.append([g.fazione, roundi(g.global_position.x * SCALA), roundi(g.global_position.y * SCALA)])
	d["p"] = p
	var z := PackedInt32Array()
	for n in get_tree().get_nodes_in_group("zombie"):
		z.append(roundi(n.global_position.x))
		z.append(roundi(n.global_position.y))
	d["z"] = Array(z)
	var b := []
	for n in get_tree().get_nodes_in_group("barricata"):
		b.append(roundi(n.vita))
	d["b"] = b
	var e := []
	for n in get_tree().get_nodes_in_group("edificio"):
		e.append(roundi(n.vita))
	d["e"] = e
	var gu := []
	for n in get_tree().get_nodes_in_group("guardia"):
		gu.append([roundi(n.global_position.x), roundi(n.global_position.y)])
	d["g"] = gu
	return d

var azioni_da_spedire: Array = []

func _miei_comandi() -> Dictionary:
	var d := {"f": mia_fazione, "a": azioni_da_spedire.duplicate()}
	azioni_da_spedire.clear()
	var mio: Node2D = get_tree().get_first_node_in_group("mio")
	if mio != null:
		d["x"] = roundi(mio.global_position.x * SCALA)
		d["y"] = roundi(mio.global_position.y * SCALA)
	return d

## --- quello che si riceve ---

func prendi_istantanea() -> Dictionary:
	var d := _da_applicare
	_da_applicare = {}
	return d

func prendi_comandi() -> Array:
	var c := _comandi_ricevuti
	_comandi_ricevuti = []
	return c
