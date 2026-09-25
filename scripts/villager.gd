class_name Villager
extends Unit
## Aldeano leñador: va al árbol más cercano, corta madera y la lleva al almacén.
## Es una "máquina de estados": en cada momento está en un solo estado y pasa
## a otro cuando termina lo que estaba haciendo.
##   IDLE → GOING_TO_TREE → CHOPPING → GOING_TO_STORAGE → IDLE → ...
## De noche deja lo que esté haciendo y se refugia (grupo "shelter"):
##   ... → GOING_TO_SHELTER → SHELTERED → (amanece) → IDLE
## La vida, el daño y el movimiento vienen de Unit (unit.gd).

enum State { IDLE, GOING_TO_TREE, CHOPPING, GOING_TO_STORAGE, GOING_TO_SHELTER, SHELTERED }

@export var chop_time := 2.0 ## segundos que tarda en cortar
@export var carry_capacity := 5 ## madera que lleva por viaje
@export var reach := 1.5 ## distancia máxima al borde del objetivo para usarlo

@onready var load_mesh: Node3D = $Load ## el "tronco" que lleva en brazos

var state := State.IDLE
var target: Node3D = null ## árbol, almacén o refugio al que va
var carried := 0
var chop_timer := 0.0
var nav: Node = null
var unreachable_trees: Array[Node3D] = [] ## árboles a los que no hay camino (muros...)

## Propiedad calculada: se lee como una variable, pero su valor sale de "state".
var is_sheltered: bool:
	get:
		return state == State.SHELTERED


func _ready() -> void:
	super() # ejecuta también el _ready() de Unit
	nav = get_tree().get_first_node_in_group("navigation")
	nav.rebaked.connect(_on_navigation_rebaked)
	GameState.night_started.connect(_on_night_started)
	GameState.day_started.connect(_on_day_started)


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
				if _is_next_to(target):
					state = State.CHOPPING
					chop_timer = chop_time
				else: # la ruta acabó lejos: hay algo en medio
					_give_up_tree()

		State.CHOPPING:
			if not is_instance_valid(target):
				state = State.IDLE
				return
			chop_timer -= delta
			if chop_timer <= 0:
				carried = target.take_wood(carry_capacity)
				target.worker = null # libera el árbol para otro aldeano
				if carried > 0:
					_go_to_nearest_storage()
				else:
					state = State.IDLE

		State.GOING_TO_STORAGE:
			if not is_instance_valid(target): # ¿no hay almacén? seguimos buscando
				_go_to_nearest_storage()
			elif _move_along_path() and _is_next_to(target):
				_deliver_wood()
				state = State.IDLE
			# Si la ruta acaba lejos del almacén, espera ahí con la madera.

		State.GOING_TO_SHELTER:
			if not is_instance_valid(target):
				_go_to_nearest_shelter()
			elif _move_along_path() and _is_next_to(target):
				_hide()
			# Si no puede llegar al refugio, se queda fuera... a merced de los zombies.

		State.SHELTERED:
			if not is_instance_valid(target): # ¡han destruido el refugio!
				_unhide()
				_go_to_nearest_shelter()

	load_mesh.visible = carried > 0


## La navegación ha cambiado (muro construido o destruido...): quizá ahora
## hay camino a sitios que antes no, así que se vuelve a intentar todo.
func _on_navigation_rebaked() -> void:
	unreachable_trees.clear()
	if is_instance_valid(target):
		agent.target_position = target.global_position # recalcula la ruta


## ¿Está pegado al objetivo? Se mide desde su borde ("radius").
func _is_next_to(node: Node3D) -> bool:
	var offset := node.global_position - global_position
	offset.y = 0
	return offset.length() <= node.radius + reach


func _give_up_tree() -> void:
	unreachable_trees.append(target)
	target.worker = null
	state = State.IDLE


func _on_night_started(_night: int) -> void:
	_release_tree()
	_go_to_nearest_shelter()


func _on_day_started(_day: int) -> void:
	if state == State.SHELTERED:
		_unhide()
	state = State.IDLE # si no llegó a refugiarse, vuelve al trabajo igualmente


func _go_to_nearest_shelter() -> void:
	state = State.GOING_TO_SHELTER
	target = _nearest_in_group("shelter")
	if target:
		agent.target_position = target.global_position


## "Entra" en el refugio: se oculta y deja de chocar con nada.
## Los zombies lo ignoran porque is_sheltered pasa a ser true.
func _hide() -> void:
	if target.is_in_group("storage"):
		_deliver_wood()
	state = State.SHELTERED
	visible = false
	collision_layer = 0


## Sale del refugio: vuelve a verse, a chocar y a ser una presa.
func _unhide() -> void:
	visible = true
	collision_layer = 2


func _deliver_wood() -> void:
	if carried > 0:
		GameState.add_resource("wood", carried)
		carried = 0


func _go_to_nearest_tree() -> void:
	target = _nearest_in_group("trees",
		func(tree): return tree.is_free() and tree not in unreachable_trees)
	if target:
		target.worker = self # lo reserva: los demás buscarán otro
		agent.target_position = target.global_position
		state = State.GOING_TO_TREE


## Si iba a un árbol o lo estaba cortando, lo deja libre.
func _release_tree() -> void:
	if state in [State.GOING_TO_TREE, State.CHOPPING] and is_instance_valid(target):
		target.worker = null


func _go_to_nearest_storage() -> void:
	state = State.GOING_TO_STORAGE
	target = _nearest_in_group("storage")
	if target:
		agent.target_position = target.global_position
