extends Node3D
## Hace aparecer la horda por los bordes del mapa al anochecer.
## Al amanecer, los zombies que quedan se queman (desaparecen).
## Horda de la noche N = base_count + extra_per_night * (N - 1).

@export var zombie_scene: PackedScene
@export var base_count := 3
@export var extra_per_night := 2
@export var spawn_distance := 18.0 ## a qué distancia del centro aparecen (el mapa llega a 20)


func _ready() -> void:
	GameState.night_started.connect(_on_night_started)
	GameState.day_started.connect(_on_day_started)


func _on_night_started(night: int) -> void:
	for i in base_count + extra_per_night * (night - 1):
		var zombie: Node3D = zombie_scene.instantiate()
		zombie.position = _random_edge_point()
		add_child(zombie)


func _on_day_started(_day: int) -> void:
	for zombie in get_children():
		zombie.die()


## Punto al azar en uno de los cuatro lados del mapa.
func _random_edge_point() -> Vector3:
	var along := randf_range(-spawn_distance, spawn_distance)
	match randi() % 4:
		0: return Vector3(along, 0, -spawn_distance) # norte
		1: return Vector3(along, 0, spawn_distance) # sur
		2: return Vector3(-spawn_distance, 0, along) # oeste
		_: return Vector3(spawn_distance, 0, along) # este
