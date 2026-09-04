extends CharacterBody2D
class_name Player
## Il leader di una fazione sulla mappa.
## is_multiplayer_authority() e' gia' qui apposta: quando aggiungeremo la rete
## questo file non cambia, cambia solo chi detiene l'autorita'.

## 0 Chiesa, 1 Governo, 2 Esercito
@export_enum("Chiesa", "Governo", "Esercito") var fazione: int = 0
## true solo sul leader che muovi tu. Offline e' il tuo; in rete locale lo
## decide l'autorita' Godot; online lo assegna chi crea i nodi.
var comando_locale := true

## Colonne in assets/sprites.png: mitra dorata, tuba, elmo con cresta.
## Devono dire a colpo d'occhio CHI sei, non solo che sei un personaggio.
const SPRITE_FAZIONE := [0, 1, 2]
const PORTATA_RIPARAZIONE := Balance.TILE * 2.5

var mondo: World
var guardie: Node2D
var vita: float = Balance.PLAYER_VITA
var a_terra := false

var _direzione := Vector2.DOWN
var _cooldown := 0.0
var _rialzo := 0.0
var _tempo := 0.0
var _fra_controlli_ombra := 0.0

## L'autorita' va decisa in _enter_tree: se la si cambia in _ready il
## MultiplayerSynchronizer e' gia' partito senza id di rete e si lamenta.
## In rete il nodo si chiama "<peer>_<fazione>": e' il modo piu' corto per far
## sapere a ogni client chi comanda questo leader e di che fazione e'.
func _enter_tree() -> void:
	if Rete.in_rete:
		var pezzi := String(name).split("_")
		set_multiplayer_authority(pezzi[0].to_int())
		fazione = pezzi[1].to_int()

func _ready() -> void:
	add_to_group("player")
	if Rete.in_rete:
		comando_locale = is_multiplayer_authority()
	if comando_locale:
		add_to_group("mio")
	add_to_group("danneggiabile")
	_vesti(fazione)
	Grafica.ombra(self, 5.0)

func _vesti(f: int) -> void:
	$Sprite2D.region_rect = Rect2(SPRITE_FAZIONE[f] * Balance.TILE, 0, Balance.TILE, Balance.TILE)

func _physics_process(delta: float) -> void:
	if Rete.in_rete and multiplayer.is_server():
		_aggiorna_ombra(delta)
	if not comando_locale:
		return
	if a_terra:
		_rialzo -= delta
		if _rialzo <= 0.0:
			_rialzati()
		return

	_cooldown -= delta
	# su telefono la levetta a schermo prende il posto della tastiera
	var dir := Tocco.direzione if Tocco.direzione != Vector2.ZERO \
		else Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		_direzione = dir
	velocity = dir * Balance.PLAYER_SPEED
	move_and_slide()
	_tempo += delta
	Grafica.passo($Sprite2D, velocity, _tempo)   # era l'unico a non camminare

	if Input.is_action_pressed("attacca") and _cooldown <= 0.0:
		_attacca()
	if Input.is_action_just_pressed("ripara"):
		_ripara()
	if Input.is_action_just_pressed("costruisci"):
		_costruisci()
	_scorciatoie()

## 1-4 lanciano le azioni della tua fazione, F1-F3 cambiano fazione (serve solo
## a provare il gioco da soli: col multiplayer sparisce).
func _scorciatoie() -> void:
	var azioni := Azioni.istanza.per_fazione(GameState.fazione_effettiva())
	for i in mini(azioni.size(), 6):
		if Input.is_action_just_pressed("azione_%d" % (i + 1)):
			Azioni.istanza.esegui(azioni[i]["id"])
	for f in 3:
		if Input.is_action_just_pressed("fazione_%d" % (f + 1)):
			GameState.fazione_giocatore = f
			fazione = f
			_vesti(f)
			GameState.annuncio.emit("Ora giochi: %s" % GameState.NOMI[GameState.fazione_effettiva()], Color(0.8, 0.9, 1))

## Fendente frontale: colpisce tutto quello che hai davanti entro il raggio.
## Un leader non e' un soldato -- serve a toglierti dai guai, non a reggere
## un'ondata da solo. Per quello ci sono i posti di guardia.
## Il ribelle di notte sparisce dagli schermi altrui finche' non gli vai vicino.
## Decide il server e basta: se la posizione la filtrasse il client, basterebbe
## una console aperta per vedere dove trama.
func _aggiorna_ombra(delta: float) -> void:
	_fra_controlli_ombra -= delta
	if _fra_controlli_ombra > 0.0:
		return
	_fra_controlli_ombra = 0.4
	var sincro: MultiplayerSynchronizer = $Sincronizza
	var in_ombra := GameState.deposta == fazione and GameState.fase == GameState.Fase.NOTTE
	sincro.public_visibility = not in_ombra
	if not in_ombra:
		return
	for altro in get_tree().get_nodes_in_group("player"):
		if altro == self:
			continue
		var peer: int = altro.get_multiplayer_authority()
		sincro.set_visibility_for(peer,
			global_position.distance_to(altro.global_position) < Balance.AVVISTAMENTO_RIBELLE)

func _attacca() -> void:
	_cooldown = Balance.ATTACCO_CADENZA
	_mostra_fendente()
	Audio.suona("fendente", -14.0)
	for z in get_tree().get_nodes_in_group("zombie"):
		if global_position.distance_to(z.global_position) > Balance.ATTACCO_RAGGIO:
			continue
		if _direzione.normalized().dot(global_position.direction_to(z.global_position)) < 0.15:
			continue
		z.subisci(Balance.ATTACCO_DANNO, global_position.direction_to(z.global_position))
		Grafica.schizzo(get_parent(), z.global_position, Color(0.5, 0.9, 0.4), 4)
		Audio.suona("colpo", -10.0)

func attaccabile() -> bool:
	return not a_terra

func distanza(p: Vector2) -> float:
	return global_position.distance_to(p)

func subisci(quanto: float, _spinta := Vector2.ZERO) -> void:
	if a_terra:
		return
	vita -= quanto
	if vita <= 0.0:
		_cadi()

func _cadi() -> void:
	a_terra = true
	vita = 0.0
	_rialzo = Balance.RIANIMAZIONE
	rotation = PI * 0.5
	modulate = Color(0.55, 0.55, 0.6)
	# un leader non viene eliminato: viene trascinato via. Ma la citta' lo vede.
	GameState.modifica("morale", -Balance.MORALE_PER_CADUTA)

func _rialzati() -> void:
	a_terra = false
	vita = Balance.PLAYER_VITA
	rotation = 0.0
	modulate = Color.WHITE
	if mondo != null:
		global_position = mondo.piazza_centro()

func _mostra_fendente() -> void:
	var arco := Line2D.new()
	arco.width = 2.5
	arco.default_color = Color(1.0, 0.98, 0.8)
	var base := _direzione.angle()
	for i in 9:
		arco.add_point(Vector2.RIGHT.rotated(base - 0.6 + i * 0.15) * Balance.ATTACCO_RAGGIO * 0.8)
	add_child(arco)
	var t := create_tween()
	t.tween_property(arco, "modulate:a", 0.0, 0.22)
	t.tween_callback(arco.queue_free)

func _ripara() -> void:
	if GameState.denaro < Balance.RIPARA_COSTO:
		return
	for b in get_tree().get_nodes_in_group("barricata"):
		if b.distanza(global_position) < PORTATA_RIPARAZIONE and b.vita < Balance.BARRICATA_VITA:
			b.ripara(Balance.RIPARA_QUANTITA)
			GameState.riparazioni += 1
			Audio.suona("riparazione", -8.0)
			GameState.modifica("denaro", -Balance.RIPARA_COSTO)
			return

func _costruisci() -> void:
	if GameState.denaro < Balance.GUARDIA_COSTO or mondo == null:
		return
	if mondo.bloccato(mondo.a_cella(global_position)):
		return
	# passa dal server come tutte le altre azioni, cosi' la guardia esiste per
	# tutti e non solo sullo schermo di chi ha premuto il tasto
	var g: Guardia = Azioni.SCENA_GUARDIA.instantiate()
	g.mondo = mondo
	g.position = mondo.centro(mondo.a_cella(global_position))
	guardie.add_child(g, true)
	Audio.suona("monete", -8.0)
	GameState.modifica("denaro", -Balance.GUARDIA_COSTO)
