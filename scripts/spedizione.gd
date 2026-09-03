extends Node
class_name Spedizione
## Qualcuno esce dalle mura a cercare roba. Il rischio e' il punto: e' l'unico
## modo di far entrare risorse dall'esterno, e ogni tanto non torna nessuno.

static var in_corso := 0

var rimanente: float = Balance.SPEDIZIONE_DURATA

func _ready() -> void:
	in_corso += 1
	GameState.annuncio.emit("Spedizione partita", Color(0.8, 0.9, 1))

## Il decremento sta qui e non in _process: se la scena cambia mentre una
## spedizione e' in volo, il conteggio resterebbe alto per sempre.
func _exit_tree() -> void:
	in_corso -= 1

func _process(delta: float) -> void:
	rimanente -= delta
	if rimanente > 0.0:
		return
	if randf() < Balance.SPEDIZIONE_RISCHIO:
		GameState.modifica("morale", -8.0)
		GameState.annuncio.emit("La spedizione non e' tornata", Color(1, 0.5, 0.4))
	else:
		GameState.modifica("denaro", Balance.SPEDIZIONE_BOTTINO_DENARO)
		GameState.modifica("viveri", Balance.SPEDIZIONE_BOTTINO_VIVERI)
		GameState.annuncio.emit("Spedizione rientrata col bottino", Color(0.6, 1, 0.7))
	queue_free()
