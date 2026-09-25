extends Label
## Muestra la fase (día/noche), el tiempo que queda y cuántos aldeanos viven.
## Cambia en cada frame (el tiempo corre), así que aquí sí usamos _process.


func _process(_delta: float) -> void:
	var phase := "Noche" if GameState.is_night else "Día"
	var villagers := get_tree().get_nodes_in_group("villagers").size()
	text = "%s %d · quedan %d s    Aldeanos: %d" % [
		phase, GameState.day, ceili(GameState.time_left), villagers]
