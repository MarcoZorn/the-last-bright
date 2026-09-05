extends CanvasLayer
## Tutorial interattivo. Ogni passo aspetta che tu faccia davvero la cosa:
## leggere le istruzioni e cliccare avanti non insegna niente.
##
## I passi senza `fatto` sono spiegazioni e si passano col pulsante; quelli con
## `fatto` sono obiettivi e si chiudono da soli quando la condizione e' vera.

var _passi: Array = []
var _n := 0
var _pannello := PanelContainer.new()
var _testo := Label.new()
var _avanti := Button.new()
var _partenza := Vector2.ZERO
var _guardie_iniziali := 0
var _azioni_iniziali := 0

func _ready() -> void:
	layer = 12
	_costruisci()
	await get_tree().process_frame
	var g: Player = get_tree().get_first_node_in_group("mio")
	_partenza = g.global_position if g != null else Vector2.ZERO
	_guardie_iniziali = get_tree().get_nodes_in_group("guardia").size()
	_azioni_iniziali = GameState.azioni_usate[GameState.fazione_effettiva()]
	_definisci()
	_mostra()

func _definisci() -> void:
	_passi = [
	{"t": "Sei uno dei tre che governano questa piazza fortificata.\n\n"
		+ "Fuori dalle mura c'e' un'apocalisse. Dentro, altri due come te che\n"
		+ "vogliono comandare al posto tuo. Devi cavartela con entrambe le cose."},

	{"t": "MUOVITI.\n\nSu computer: WASD o le frecce.\n"
		+ "Su telefono: tieni il pollice sulla meta' sinistra dello schermo e trascina.",
		"fatto": func(): return _mio() != null and _mio().global_position.distance_to(_partenza) > 70.0},

	{"t": "Questa e' la citta'.\n\n"
		+ "Al centro la piazza. Attorno i tre poli di potere: la CHIESA a nord,\n"
		+ "il PALAZZO a ovest, la CASERMA a est. Se crollano tutti e tre, hai perso.\n\n"
		+ "Il muro ha quattro porte, e a nord c'e' il ponte: e' da li' che arrivano."},

	{"t": "In alto a sinistra ci sono i numeri che contano.\n\n"
		+ "MORALE  quanto la gente ci crede. Da lui dipendono le tasse.\n"
		+ "DENARO  paga riparazioni, guardie, addestramento.\n"
		+ "VIVERI  la citta' mangia ogni giorno. A zero, si muore di fame.\n"
		+ "MURA    quanto reggono le barricate, adesso.\n\n"
		+ "In basso a destra c'e' la minimappa: serve a vedere dove stai perdendo."},

	{"t": "RIPARA UNA BARRICATA.\n\n"
		+ "Ne ho appena danneggiata una: e' quella con la barra rossa sulle mura.\n"
		+ "Vai vicino e premi E (o il pulsante RIPARA). Costa 8 denaro.\n\n"
		+ "Le barricate sono l'unica cosa fra te e loro.",
		"inizia": func(): _rompi_una_barricata(),
		"fatto": func(): return GameState.riparazioni > 0},

	{"t": "RECLUTA UNA GUARDIA.\n\n"
		+ "Premi Q (o il pulsante GUARDIA). Costa 35 denaro.\n\n"
		+ "Le guardie vanno da sole al varco piu' minacciato e sparano da ferme.\n"
		+ "Puoi anche selezionarle col clic e mandarle dove vuoi col destro.",
		"inizia": func(): _garantisci_denaro(Balance.GUARDIA_COSTO + 20.0),
		"fatto": func(): return get_tree().get_nodes_in_group("guardia").size() > _guardie_iniziali},

	{"t": "USA UN'AZIONE DELLA TUA FAZIONE.\n\n"
		+ "Sono i riquadri in basso: premi 1-6, oppure toccali.\n\n"
		+ "Ne hai TRE al giorno, e solo di giorno. Questo e' il vero costo del\n"
		+ "gioco: fare una cosa vuol dire non farne un'altra.",
		"inizia": func(): _prepara_azioni(),
		"fatto": func(): return GameState.azioni_usate[GameState.fazione_effettiva()] > _azioni_iniziali},

	{"t": "IL POTERE E' A SOMMA ZERO.\n\n"
		+ "In alto a destra: voi tre vi dividete cento punti di legittimita'.\n"
		+ "All'alba chi ha prodotto risultati ne guadagna, e li toglie agli altri.\n"
		+ "Morale alto premia la Chiesa, casse piene il Governo, mura intatte l'Esercito.\n\n"
		+ "Chi scende sotto 12 viene DEPOSTO. Ma non e' eliminato: passa a giocare\n"
		+ "da ribelle, e di notte gli altri non vedono nemmeno dove sia."},

	{"t": "Adesso arriva la notte. Sono pochi, per cominciare.\n\n"
		+ "AMMAZZANE UNO: avvicinati e premi SPAZIO (o COLPISCI).\n\n"
		+ "Attenzione: ogni zombie ancora vivo all'alba ti costa gente.\n"
		+ "Aspettare il sole non e' gratis.",
		"inizia": func(): _chiama_la_notte(),
		"fatto": func(): return GameState.zombie_uccisi > 0},

	{"t": "Sai tutto quello che serve.\n\n"
		+ "Reggi dieci giorni e hai vinto. I primi quattro arrivano solo dal ponte;\n"
		+ "dal quinto anche dai fianchi, dal decimo sei circondato.\n\n"
		+ "Premi H in qualunque momento per rileggere le regole.\n"
		+ "Buona fortuna."},
	]

func _mio() -> Player:
	return get_tree().get_first_node_in_group("mio")

## --- ogni passo si prepara le condizioni per poter essere completato ---
## Senza questo il tutorial chiedeva di riparare una barricata quando erano
## tutte intere, e restava bloccato li' per sempre.

func _rompi_una_barricata() -> void:
	var vicina: Barricata = null
	var d_min := INF
	var qui: Vector2 = _mio().global_position if _mio() != null else Vector2.ZERO
	for b in get_tree().get_nodes_in_group("barricata"):
		if not b.in_piedi:
			continue
		var d: float = b.distanza(qui)
		if d < d_min:
			d_min = d
			vicina = b
	if vicina != null:
		vicina.subisci(Balance.BARRICATA_VITA * 0.55)
	_garantisci_denaro(Balance.RIPARA_COSTO + 20.0)

func _garantisci_denaro(quanto: float) -> void:
	if GameState.denaro < quanto:
		GameState.denaro = quanto

## L'azione dev'essere davvero disponibile: soldi in cassa, budget del giorno
## intero e nessuna ricarica in corso.
func _prepara_azioni() -> void:
	_garantisci_denaro(120.0)
	GameState.viveri = maxf(GameState.viveri, 100.0)
	GameState.azioni_usate = [0, 0, 0, 0]
	Azioni.istanza.azzera_ricariche()

func _chiama_la_notte() -> void:
	GameState.tutorial_notte = true
	GameState.tempo_fase = Balance.giorno_durata(GameState.giorno)
	# tre zombie a due passi, invece di farli attraversare mezza mappa
	# il genitore e' sempre la scena di gioco: `current_scene` non lo e' quando
	# il tutorial gira dentro un test
	var g := _mio()
	var principale := get_parent()
	if g != null and principale != null and principale.has_method("genera_vicino"):
		principale.genera_vicino(g.global_position, 3)

func _costruisci() -> void:
	var telaio := Control.new()
	telaio.set_anchors_preset(Control.PRESET_FULL_RECT)
	telaio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(telaio)

	_pannello.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_pannello.position = Vector2(-330, 96)
	_pannello.custom_minimum_size = Vector2(660, 0)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.06, 0.07, 0.10, 0.94)
	fondo.border_color = Color(0.85, 0.76, 0.5)
	fondo.set_border_width_all(1)
	fondo.set_content_margin_all(16)
	_pannello.add_theme_stylebox_override("panel", fondo)
	telaio.add_child(_pannello)

	var colonna := VBoxContainer.new()
	colonna.add_theme_constant_override("separation", 12)
	_pannello.add_child(colonna)
	_testo.add_theme_font_size_override("font_size", 15)
	_testo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_testo.custom_minimum_size = Vector2(628, 0)
	colonna.add_child(_testo)

	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 10)
	colonna.add_child(fila)
	_avanti.text = "AVANTI"
	_avanti.custom_minimum_size = Vector2(150, 42)
	_avanti.pressed.connect(_prossimo)
	fila.add_child(_avanti)
	var salta := Button.new()
	salta.text = "salta il tutorial"
	salta.custom_minimum_size = Vector2(150, 42)
	salta.pressed.connect(_chiudi)
	fila.add_child(salta)

func _mostra() -> void:
	if _n >= _passi.size():
		_chiudi()
		return
	var p: Dictionary = _passi[_n]
	_testo.text = p["t"]
	_avanti.visible = not p.has("fatto")
	if p.has("inizia"):
		p["inizia"].call()
	# aggiorna i riferimenti per il passo che verifica un cambiamento
	_guardie_iniziali = get_tree().get_nodes_in_group("guardia").size()
	_azioni_iniziali = GameState.azioni_usate[GameState.fazione_effettiva()]
	var g := _mio()
	if g != null:
		_partenza = g.global_position

func _prossimo() -> void:
	_n += 1
	_mostra()

func _process(_d: float) -> void:
	if _n >= _passi.size():
		return
	var p: Dictionary = _passi[_n]
	if p.has("fatto") and p["fatto"].call():
		Audio.suona("azione", -8.0)
		_prossimo()

func _chiudi() -> void:
	GameState.segna_tutorial_fatto()
	GameState.tutorial = false
	GameState.tutorial_notte = true
	queue_free()
