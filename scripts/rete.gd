extends Node
## Rete. Autoload.
##
## Divisione delle responsabilita', decisa una volta e valida per tutto il resto:
##   - il MOVIMENTO dei leader e' del client (ognuno muove il suo, gli altri lo
##     vedono replicato). Barare sulla posizione non rompe niente di importante.
##   - lo STATO della citta' -- risorse, potere, ondate, zombie, barricate -- e'
##     del server, e basta. E' li' che vive l'informazione nascosta: se un client
##     conoscesse tutto lo stato, il ribelle in incognito sarebbe barabile
##     aprendo la console del browser.
##
## Senza nessuna connessione aperta tutto continua a funzionare: Godot considera
## un gioco offline come un server con zero peer, quindi il singolo giocatore
## non ha bisogno di percorsi separati.

const PORTA := 8910
const GIOCATORI_MAX := 3

signal lobby_cambiata
signal partita_avviata

## id del peer -> fazione assegnata (0 Chiesa, 1 Governo, 2 Esercito)
var fazioni := {}
var in_rete := false
var errore := ""

func _ready() -> void:
	multiplayer.peer_connected.connect(_entrato)
	multiplayer.peer_disconnected.connect(_uscito)
	multiplayer.connected_to_server.connect(func(): lobby_cambiata.emit())
	multiplayer.connection_failed.connect(func():
		errore = "Connessione fallita"
		in_rete = false
		lobby_cambiata.emit())
	multiplayer.server_disconnected.connect(func():
		errore = "Il server e' sparito"
		chiudi())

func ospita() -> bool:
	var pari := ENetMultiplayerPeer.new()
	var esito := pari.create_server(PORTA, GIOCATORI_MAX)
	if esito != OK:
		errore = "Non riesco ad aprire la porta %d" % PORTA
		return false
	multiplayer.multiplayer_peer = pari
	in_rete = true
	errore = ""
	fazioni = {1: 0}          # l'ospite e' il peer 1 e prende la Chiesa
	lobby_cambiata.emit()
	print("[rete] ospito sulla porta %d" % PORTA)
	return true

func unisciti(indirizzo: String) -> bool:
	var pari := ENetMultiplayerPeer.new()
	var esito := pari.create_client(indirizzo, PORTA)
	if esito != OK:
		errore = "Indirizzo non valido"
		return false
	multiplayer.multiplayer_peer = pari
	in_rete = true
	errore = ""
	return true

func chiudi() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	in_rete = false
	fazioni.clear()
	lobby_cambiata.emit()

func mia_fazione() -> int:
	if not in_rete:
		return GameState.fazione_giocatore
	return fazioni.get(multiplayer.get_unique_id(), 0)

func e_il_server() -> bool:
	return not in_rete or multiplayer.is_server()

func _entrato(id: int) -> void:
	if not multiplayer.is_server():
		return
	# prima fazione libera: con tre posti non serve niente di piu' furbo
	var prese := fazioni.values()
	for f in 3:
		if f not in prese:
			fazioni[id] = f
			break
	_annuncia_lobby.rpc(fazioni)
	print("[rete] entrato %d, lobby: %s" % [id, fazioni])
	lobby_cambiata.emit()

func _uscito(id: int) -> void:
	if not multiplayer.is_server():
		return
	fazioni.erase(id)
	_annuncia_lobby.rpc(fazioni)
	lobby_cambiata.emit()

@rpc("authority", "call_remote", "reliable")
func _annuncia_lobby(nuove: Dictionary) -> void:
	fazioni = nuove
	print("[rete] lobby: %s" % nuove)
	lobby_cambiata.emit()

## Il server dice a tutti di caricare la partita.
@rpc("authority", "call_local", "reliable")
func avvia() -> void:
	GameState.ripristina()
	GameState.fazione_giocatore = mia_fazione()
	partita_avviata.emit()
	get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")
