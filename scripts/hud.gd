extends CanvasLayer
## HUD di debug. Non e' l'interfaccia del gioco: serve a vedere i numeri
## mentre proviamo le meccaniche.

var _label := Label.new()

func _ready() -> void:
	var p := PanelContainer.new()
	p.position = Vector2(12, 12)
	p.add_child(_label)
	add_child(p)
	GameState.cambiato.connect(_aggiorna)
	_aggiorna()

func _process(_d: float) -> void:
	_aggiorna()

func _aggiorna() -> void:
	var fase := "GIORNO" if GameState.fase == GameState.Fase.GIORNO else "NOTTE"
	var resto := ""
	if GameState.fase == GameState.Fase.GIORNO:
		resto = "  (notte fra %ds)" % ceili(Balance.GIORNO_DURATA - GameState.tempo_fase)
	_label.text = ("  Giorno %d - %s%s\n" % [GameState.giorno, fase, resto]
		+ "  Morale (Chiesa)      %5.1f\n" % GameState.morale
		+ "  Denaro (Governo)     %5.1f\n" % GameState.denaro
		+ "  Sicurezza (Esercito) %5.1f\n" % GameState.sicurezza
		+ "  Popolazione           %4d\n" % GameState.popolazione
		+ "  Zombie uccisi         %4d\n" % GameState.zombie_uccisi
		+ ("  --- LA CITTA' E' CADUTA ---  \n" if GameState.finita else "")
		+ "  WASD muovi | E ripara (%d) | Q guardia (%d)  " % [Balance.RIPARA_COSTO, Balance.GUARDIA_COSTO])
