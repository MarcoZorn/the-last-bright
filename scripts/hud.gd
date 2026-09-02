extends CanvasLayer
## HUD di debug. Non e' l'interfaccia del gioco: serve a vedere i numeri
## mentre proviamo le meccaniche.

var _label := Label.new()

func _ready() -> void:
	var p := PanelContainer.new()
	p.position = Vector2(12, 12)
	p.add_child(_label)
	add_child(p)
	GameState.changed.connect(_aggiorna)
	_aggiorna()

func _aggiorna() -> void:
	_label.text = "  Morale (Chiesa)     %5.1f\n  Denaro (Governo)    %5.1f\n  Sicurezza (Esercito)%5.1f\n  Popolazione          %4d  " % [
		GameState.morale, GameState.denaro, GameState.sicurezza, GameState.popolazione]
