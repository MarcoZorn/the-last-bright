extends SceneTree
## godot --headless --script res://tools/test_potere.gd
## Il potere e' a somma zero: se questo si rompe, una fazione puo' salire senza
## che nessuno scenda e il golpe non arriva mai.

## Con --script gli autoload non sono identificatori globali: si prende dal tree.
var GS: Node = null

func _process(_delta: float) -> bool:
	GS = root.get_node_or_null("GameState")
	if GS == null:
		print("!! autoload GameState non disponibile in questo contesto")
		return true
	assert(is_equal_approx(_somma(), 100.0), "il potere deve sempre sommare 100")

	# una Chiesa con morale altissimo e un Esercito con le mura a pezzi:
	# prima o poi qualcuno deve saltare
	GS.morale = 100.0
	GS.denaro = 400.0
	GS.sicurezza = 0.0
	var golpe_avvenuto := false
	for giorno in 40:
		GS._ridistribuisci_potere()
		GS._controlla_golpe()
		assert(is_equal_approx(_somma(), 100.0), "il potere deve restare normalizzato")
		if GS.deposta >= 0:
			golpe_avvenuto = true
			break
	assert(golpe_avvenuto, "chi non produce risultati deve essere deposto")
	assert(GS.deposta == 2, "con le mura a zero deve cadere l'Esercito, non altri")
	print("OK potere: golpe dopo il collasso delle mura, deposta = %s" % GS.NOMI[GS.deposta])

	# il ribelle che si riprende il consenso torna al potere e ne butta fuori un altro
	GS.potere[2] = 60.0
	GS.normalizza_potere()
	GS._controlla_golpe()
	assert(GS.deposta != 2, "il ribelle che supera la soglia deve rientrare")
	print("OK ritorno: ora e' fuori %s" % GS.NOMI[GS.deposta])
	return true

func _somma() -> float:
	return GS.potere[0] + GS.potere[1] + GS.potere[2]
