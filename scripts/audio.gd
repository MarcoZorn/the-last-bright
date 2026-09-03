extends Node
## Suoni del gioco. Autoload.
## Tutti CC0 di Kenney. Un pool di lettori riusati a rotazione: creare un nodo
## nuovo a ogni colpo, con cento zombie a schermo, ammazza il framerate.

const K := "res://assets/kenney/"
const SUONI := {
	"fendente": [K + "rpg-audio/Audio/knifeSlice.ogg", K + "rpg-audio/Audio/knifeSlice2.ogg"],
	"colpo": [K + "impact-sounds/Audio/impactPunch_medium_000.ogg",
		K + "impact-sounds/Audio/impactPunch_medium_001.ogg",
		K + "impact-sounds/Audio/impactPunch_medium_002.ogg"],
	"morte": [K + "impact-sounds/Audio/impactSoft_heavy_000.ogg",
		K + "impact-sounds/Audio/impactSoft_heavy_001.ogg"],
	"morso_mura": [K + "impact-sounds/Audio/impactWood_light_000.ogg",
		K + "impact-sounds/Audio/impactWood_light_001.ogg",
		K + "impact-sounds/Audio/impactWood_light_002.ogg"],
	"varco_caduto": [K + "impact-sounds/Audio/impactWood_heavy_000.ogg"],
	"riparazione": [K + "impact-sounds/Audio/impactPlank_medium_000.ogg",
		K + "impact-sounds/Audio/impactPlank_medium_001.ogg"],
	"sparo": [K + "impact-sounds/Audio/impactMetal_light_000.ogg",
		K + "impact-sounds/Audio/impactMetal_light_001.ogg",
		K + "impact-sounds/Audio/impactMetal_light_002.ogg"],
	"monete": [K + "rpg-audio/Audio/handleCoins.ogg", K + "rpg-audio/Audio/handleCoins2.ogg"],
	"azione": [K + "interface-sounds/Audio/confirmation_001.ogg"],
	"negato": [K + "interface-sounds/Audio/error_002.ogg"],
	"notte": [K + "interface-sounds/Audio/bong_001.ogg"],
	"alba": [K + "interface-sounds/Audio/question_002.ogg"],
	"golpe": [K + "interface-sounds/Audio/glitch_002.ogg"],
	"selezione": [K + "interface-sounds/Audio/click_002.ogg"],
	"porta": [K + "rpg-audio/Audio/doorOpen_1.ogg"],
}

const LETTORI := 14
## Alcuni suoni partono decine di volte al secondo (i morsi alle mura): senza
## questo, cento zombie che rodono la stessa porta fanno un muro di rumore.
const RIPETIZIONE_MINIMA := {"morso_mura": 0.12, "sparo": 0.05, "colpo": 0.04}

var _tracce := {}   # nome -> [AudioStream], caricate una volta sola
var _pool: Array[AudioStreamPlayer] = []
var _prossimo := 0
var _ultima_volta := {}

func _ready() -> void:
	for nome in SUONI:
		_tracce[nome] = SUONI[nome].map(func(p): return load(p))
	for i in LETTORI:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)

func suona(nome: String, volume_db := -6.0) -> void:
	if not SUONI.has(nome):
		return
	var minimo: float = RIPETIZIONE_MINIMA.get(nome, 0.0)
	if minimo > 0.0:
		var ora := Time.get_ticks_msec() / 1000.0
		if ora - float(_ultima_volta.get(nome, -99.0)) < minimo:
			return
		_ultima_volta[nome] = ora
	var lettore := _pool[_prossimo]
	_prossimo = (_prossimo + 1) % LETTORI
	lettore.stream = _tracce[nome].pick_random()
	lettore.volume_db = volume_db
	lettore.pitch_scale = randf_range(0.92, 1.08)
	lettore.play()
