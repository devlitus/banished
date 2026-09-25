extends CharacterBody3D
## Aldeano leñador: va al árbol más cercano, corta madera y la lleva al almacén.
## Es una "máquina de estados": en cada momento está en un solo estado y pasa
## a otro cuando termina lo que estaba haciendo.
##   IDLE → GOING_TO_TREE → CHOPPING → GOING_TO_STORAGE → IDLE → ...

enum State { IDLE, GOING_TO_TREE, CHOPPING, GOING_TO_STORAGE }

@export var speed := 3.0
@export var chop_time := 2.0 ## segundos que tarda en cortar
@export var carry_capacity := 5 ## madera que lleva por viaje

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var load_mesh: Node3D = $Load ## el "tronco" que lleva en brazos

var state := State.IDLE
var target: Node3D = null ## árbol o almacén al que va
var carried := 0
var chop_timer := 0.0
var nav: Node = null


func _ready() -> void:
	nav = get_tree().get_first_node_in_group("navigation")


func _physics_process(delta: float) -> void:
	if not nav.is_ready: # sin malla de navegación aún no sabemos caminar
		return

	match state:
		State.IDLE:
			_go_to_nearest_tree()

		State.GOING_TO_TREE:
			if not is_instance_valid(target): # otro lo agotó por el camino
				state = State.IDLE
			elif _move_along_path():
				state = State.CHOPPING
				chop_timer = chop_time

		State.CHOPPING:
			if not is_instance_valid(target):
				state = State.IDLE
				return
			chop_timer -= delta
			if chop_timer <= 0:
				carried = target.take_wood(carry_capacity)
				if carried > 0:
					_go_to_nearest_storage()
				else:
					state = State.IDLE

		State.GOING_TO_STORAGE:
			if not is_instance_valid(target): # ¿no hay almacén? seguimos buscando
				_go_to_nearest_storage()
			elif _move_along_path():
				GameState.add_resource("wood", carried)
				carried = 0
				state = State.IDLE

	load_mesh.visible = carried > 0


func _go_to_nearest_tree() -> void:
	target = _nearest_in_group("trees")
	if target:
		agent.target_position = target.global_position
		state = State.GOING_TO_TREE


func _go_to_nearest_storage() -> void:
	state = State.GOING_TO_STORAGE
	target = _nearest_in_group("storage")
	if target:
		agent.target_position = target.global_position


func _nearest_in_group(group: String) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for node: Node3D in get_tree().get_nodes_in_group(group):
		var d := global_position.distance_squared_to(node.global_position)
		if d < best_distance:
			best = node
			best_distance = d
	return best


## Da un paso siguiendo la ruta del NavigationAgent3D. Devuelve true al llegar.
## El destino (el centro del árbol o del almacén) está dentro de un obstáculo,
## así que "llegar" significa alcanzar el punto caminable más cercano a él.
func _move_along_path() -> bool:
	if agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return true
	var direction := agent.get_next_path_position() - global_position
	direction.y = 0
	velocity = direction.normalized() * speed
	move_and_slide()
	if direction.length() > 0.01:
		look_at(global_position + direction) # mira hacia donde camina
	return false
