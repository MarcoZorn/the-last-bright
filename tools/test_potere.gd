extends Node
## godot --headless res://tools/test_potere.tscn
## Il potere e' a somma zero: se questo si rompe, una fazione puo' salire senza
## che nessuno scenda e il golpe non arriva mai.

func _ready() -> void:
	assert(is_equal_approx(_somma(), 100.0), "il potere deve sempre sommare 100")

	# una Chiesa con morale altissimo e un Esercito con le mura a pezzi:
	# prima o poi qualcuno deve saltare
	GameState.morale = 100.0
	GameState.denaro = 400.0
	GameState.sicurezza = 0.0
	var golpe := false
	for giorno in 40:
		GameState._ridistribuisci_potere()
		GameState._controlla_golpe()
		assert(is_equal_approx(_somma(), 100.0), "il potere deve restare normalizzato")
		if GameState.deposta >= 0:
			golpe = true
			break
	assert(golpe, "chi non produce risultati deve essere deposto")
	assert(GameState.deposta == 2, "con le mura a zero deve cadere l'Esercito")
	print("OK potere: golpe dopo il collasso delle mura, deposta = %s" % GameState.NOMI[GameState.deposta])

	# il ribelle che si riprende il consenso torna al potere e ne butta fuori un altro
	GameState.potere[2] = 60.0
	GameState.normalizza_potere()
	GameState._controlla_golpe()
	assert(GameState.deposta != 2, "il ribelle che supera la soglia deve rientrare")
	print("OK ritorno: ora e' fuori %s" % GameState.NOMI[GameState.deposta])
	get_tree().quit()

func _somma() -> float:
	return GameState.potere[0] + GameState.potere[1] + GameState.potere[2]
