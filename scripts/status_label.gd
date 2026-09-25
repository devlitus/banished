extends Label
## Muestra la fase (día/noche), el tiempo que queda y el estado de la población.
## Cambia en cada frame (el tiempo corre), así que aquí sí usamos _process.

@export var colony: Node


func _process(_delta: float) -> void:
	var phase := "Noche" if GameState.is_night else "Día"
	var survived := GameState.day - 1
	var villagers: Array = get_tree().get_nodes_in_group("villagers")
	var jobless := villagers.filter(func(v): return not is_instance_valid(v.workplace)).size()
	text = "%s %d · quedan %d s · noches superadas: %d/%d\nAldeanos: %d/%d · sin trabajo: %d" % [
		phase, GameState.day, ceili(GameState.time_left), survived, GameState.NIGHTS_TO_WIN,
		villagers.size(), colony.housing_capacity(), jobless]
