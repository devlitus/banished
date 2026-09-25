extends Label
## Muestra los recursos. Se actualiza solo cuando GameState avisa de un cambio (señal).


func _ready() -> void:
	GameState.resources_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var r := GameState.resources
	text = "Madera: %d    Piedra: %d    Comida: %d" % [r.wood, r.stone, r.food]
