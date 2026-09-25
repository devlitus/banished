extends Node
## Reglas de la colonia, que se aplican cada amanecer:
## 1. Comer: cada aldeano come "food_per_villager". Si no llega, muere uno de hambre.
## 2. Crecer: si sobra comida y hay sitio en las casas, nacen aldeanos.
## 3. Ganar: sobrevivir GameState.NIGHTS_TO_WIN noches.
## Y en todo momento: si no queda ningún aldeano, se pierde.

@export var villager_scene: PackedScene
@export var villagers_parent: Node3D
@export var game_over: Control
@export var base_capacity := 5 ## plazas sin ninguna casa (el campamento inicial)
@export var capacity_per_house := 4
@export var food_per_villager := 2
@export var food_per_birth := 15
@export var max_births_per_day := 3

var game_ended := false


func _ready() -> void:
	GameState.day_started.connect(_on_day_started)


func _process(_delta: float) -> void:
	if not game_ended and villager_count() == 0:
		_end(false)


func villager_count() -> int:
	return get_tree().get_nodes_in_group("villagers").size()


func housing_capacity() -> int:
	return base_capacity + capacity_per_house * get_tree().get_nodes_in_group("houses").size()


func _on_day_started(day: int) -> void:
	if day > GameState.NIGHTS_TO_WIN:
		_end(true)
		return
	_feed()
	_grow()


func _feed() -> void:
	var villagers := get_tree().get_nodes_in_group("villagers")
	var needed: int = villagers.size() * (food_per_villager - GameState.bonuses.food_saved)
	var food: int = GameState.resources.food
	if food >= needed:
		GameState.spend({"food": needed})
		GameState.message.emit("Amanece. Los aldeanos comen %d de comida" % needed)
		return
	GameState.spend({"food": food})
	villagers.pick_random().die()
	GameState.message.emit("¡Hambre! Falta comida y muere un aldeano")


func _grow() -> void:
	var room := housing_capacity() - villager_count()
	var affordable := floori(GameState.resources.food / float(food_per_birth))
	var births := mini(mini(room, affordable), max_births_per_day)
	if births <= 0:
		return
	GameState.spend({"food": births * food_per_birth})
	var storage: Node3D = get_tree().get_first_node_in_group("storage")
	for i in births:
		var villager: Node3D = villager_scene.instantiate()
		villager.position = _free_spot_near(storage.global_position if storage else Vector3.ZERO)
		villagers_parent.add_child(villager)
	GameState.message.emit("¡Han nacido %d aldeanos!" % births if births > 1 else "¡Ha nacido un aldeano!")


## Un punto caminable cerca de "center": uno al azar alrededor, "pegado" a la
## malla de navegación para no nacer dentro de un edificio.
func _free_spot_near(center: Vector3) -> Vector3:
	var nav: NavigationRegion3D = get_tree().get_first_node_in_group("navigation")
	var angle := randf() * TAU
	var spot := center + Vector3(cos(angle), 0, sin(angle)) * 2.5
	var closest := NavigationServer3D.map_get_closest_point(nav.get_navigation_map(), spot)
	closest.y = 0
	return closest


func _end(won: bool) -> void:
	game_ended = true
	if won:
		game_over.show_result("¡Victoria!",
			"La colonia ha sobrevivido %d noches con %d aldeanos." % [GameState.NIGHTS_TO_WIN, villager_count()])
	else:
		game_over.show_result("Derrota",
			"No queda nadie en la colonia. Aguantasteis hasta el día %d." % GameState.day)
