extends CharacterBody3D
class_name Player3D
## Leader in terza persona. Braccio di camera dietro le spalle, movimento
## relativo a dove guardi: e' il minimo perche' "camminare dentro la piazza"
## voglia dire qualcosa.

const VELOCITA := 5.2
const CORSA := 8.4
const GRAVITA := 22.0
const SENSIBILITA := 0.0032
const DISTANZA := 6.5

var _braccio: Node3D
var _camera: Camera3D
var _giro := 0.0
var _inclinazione := -0.25

func _ready() -> void:
	add_to_group("player3d")
	var forma := CapsuleShape3D.new()
	forma.radius = 0.42
	forma.height = 1.8
	var cs := CollisionShape3D.new()
	cs.shape = forma
	cs.position.y = 0.9
	add_child(cs)

	var corpo := MeshInstance3D.new()
	var capsula := CapsuleMesh.new()
	capsula.radius = 0.42
	capsula.height = 1.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.86, 0.80, 0.62)
	capsula.material = mat
	corpo.mesh = capsula
	corpo.position.y = 0.9
	add_child(corpo)

	# Perno semplice invece di SpringArm3D: il braccio elastico partiva da dentro
	# la capsula del giocatore, urtava se stesso e si accorciava a zero -- camera
	# dentro la testa, schermo vuoto. Per un blockout una camera a distanza fissa
	# basta e toglie di mezzo il problema.
	# ponytail: niente camera che evita i muri. Se entrando nei vicoli la camera
	# passa dentro la pietra, allora conviene tornare a SpringArm3D fatto bene.
	_braccio = Node3D.new()
	_braccio.position.y = 1.6
	add_child(_braccio)
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 1.2, DISTANZA)
	_camera.far = 900.0
	_camera.current = true
	_braccio.add_child(_camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_giro -= evento.relative.x * SENSIBILITA
		_inclinazione = clampf(_inclinazione - evento.relative.y * SENSIBILITA, -1.2, 0.4)
	elif evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
			else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	_braccio.rotation = Vector3(_inclinazione, _giro, 0.0)
	if not is_on_floor():
		velocity.y -= GRAVITA * delta
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var avanti := Vector3(sin(_giro), 0, cos(_giro))
	var lato := Vector3(sin(_giro - PI * 0.5), 0, cos(_giro - PI * 0.5))
	var moto := (avanti * dir.y + lato * dir.x).normalized()
	var v: float = CORSA if Input.is_key_pressed(KEY_SHIFT) else VELOCITA
	velocity.x = moto.x * v
	velocity.z = moto.z * v
	if moto.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(moto.x, moto.z), delta * 10.0)
	move_and_slide()
