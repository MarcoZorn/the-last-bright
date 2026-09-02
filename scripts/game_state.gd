extends Node
## Stato della citta'-stato. Autoload.
## NOTA ARCHITETTURALE: quando arrivera' il multiplayer questo vive SOLO sul
## server e viene replicato filtrato per giocatore (serve al ribelle stealth:
## se il client conosce tutto lo stato, il tradimento e' barabile da console).

enum Faction { CHIESA, GOVERNO, ESERCITO }

const NOMI := {
	Faction.CHIESA: "Chiesa",
	Faction.GOVERNO: "Governo",
	Faction.ESERCITO: "Esercito",
}

var morale: float = Balance.MORALE_INIZIALE
var denaro: float = Balance.DENARO_INIZIALE
var sicurezza: float = Balance.SICUREZZA_INIZIALE
var popolazione: int = Balance.POPOLAZIONE_INIZIALE
var zombie_uccisi: int = 0

signal changed

func _ready() -> void:
	_registra_wasd()

func modifica(campo: String, delta: float) -> void:
	set(campo, clampf(get(campo) + delta, 0.0, 999.0))
	changed.emit()

## WASD in aggiunta alle frecce (ui_*), registrato da codice per non
## infilare blocchi InputEvent illeggibili dentro project.godot.
func _registra_wasd() -> void:
	for azione in {"ui_up": KEY_W, "ui_down": KEY_S, "ui_left": KEY_A, "ui_right": KEY_D}:
		var ev := InputEventKey.new()
		ev.physical_keycode = {"ui_up": KEY_W, "ui_down": KEY_S, "ui_left": KEY_A, "ui_right": KEY_D}[azione]
		InputMap.action_add_event(azione, ev)
