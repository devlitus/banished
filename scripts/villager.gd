class_name Villager
extends Unit
## Aldeano. Si no tiene trabajo, busca un edificio de trabajo con plaza libre
## (grupo "workplaces") y se apunta. Después, según su trabajo:
##   leñador:         IDLE → GOING_TO_TREE → CHOPPING → GOING_TO_STORAGE → IDLE
##   cantera/granja:  IDLE → GOING_TO_WORK → WORKING  → GOING_TO_STORAGE → IDLE
## De noche deja lo que esté haciendo y se refugia (grupo "shelter"):
##   ... → GOING_TO_SHELTER → SHELTERED → (amanece) → IDLE
## Es una "máquina de estados": en cada momento está en un solo estado.
## La vida, el daño y el movimiento vienen de Unit (unit.gd).

enum State {
	IDLE, GOING_TO_TREE, CHOPPING, GOING_TO_WORK, WORKING,
	GOING_TO_STORAGE, GOING_TO_SHELTER, SHELTERED,
}

const LOAD_COLORS := {
	"wood": Color(0.45, 0.3, 0.18),
	"stone": Color(0.6, 0.6, 0.62),
	"food": Color(0.95, 0.8, 0.25),
}

@export var chop_time := 2.0 ## segundos que tarda en talar
@export var carry_capacity := 5 ## madera que lleva por viaje
@export var reach := 1.5 ## distancia máxima al borde del objetivo para usarlo

@onready var load_mesh: MeshInstance3D = $Load ## lo que lleva en brazos

var state := State.IDLE
var target: Node3D = null ## árbol, almacén o refugio al que va
var workplace: WorkBuilding = null ## su trabajo (null = parado)
var carried := 0
var carried_type := ""
var work_timer := 0.0
var nav: Node = null
var unreachable_trees: Array[Node3D] = [] ## árboles a los que no hay camino (muros...)
var load_material := StandardMaterial3D.new()

## Propiedad calculada: se lee como una variable, pero su valor sale de "state".
var is_sheltered: bool:
	get:
		return state == State.SHELTERED


func _ready() -> void:
	super() # ejecuta también el _ready() de Unit
	load_mesh.material_override = load_material
	nav = get_tree().get_first_node_in_group("navigation")
	nav.rebaked.connect(_on_navigation_rebaked)
	GameState.night_started.connect(_on_night_started)
	GameState.day_started.connect(_on_day_started)


func _physics_process(delta: float) -> void:
	if not nav.is_ready: # sin malla de navegación aún no sabemos caminar
		return

	match state:
		State.IDLE:
			_choose_task()

		State.GOING_TO_TREE:
			if not is_instance_valid(target): # otro lo agotó por el camino
				state = State.IDLE
			elif _move_along_path():
				if _is_next_to(target):
					state = State.CHOPPING
					work_timer = chop_time
				else: # la ruta acabó lejos: hay algo en medio
					_give_up_tree()

		State.CHOPPING:
			if not is_instance_valid(target):
				state = State.IDLE
				return
			work_timer -= delta
			if work_timer <= 0:
				var amount: int = target.take_wood(carry_capacity + GameState.bonuses.carry)
				target.worker = null # libera el árbol para otro aldeano
				_pick_up("wood", amount)

		State.GOING_TO_WORK:
			if not is_instance_valid(workplace): # lo han destruido
				state = State.IDLE
			elif _move_along_path() and _is_next_to(workplace):
				state = State.WORKING
				work_timer = workplace.work_time

		State.WORKING:
			if not is_instance_valid(workplace):
				state = State.IDLE
				return
			work_timer -= delta
			if work_timer <= 0:
				var amount: int = workplace.amount_per_trip + GameState.bonuses.carry
				if workplace.resource_type == "food":
					amount = roundi(amount * GameState.bonuses.farm)
				_pick_up(workplace.resource_type, amount)

		State.GOING_TO_STORAGE:
			if not is_instance_valid(target): # ¿no hay almacén? seguimos buscando
				_go_to_nearest_storage()
			elif _move_along_path() and _is_next_to(target):
				_deliver()
				state = State.IDLE
			# Si la ruta acaba lejos del almacén, espera ahí con la carga.

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


func _speed() -> float:
	return speed * GameState.bonuses.villager_speed


func _current_animation() -> String:
	if state in [State.CHOPPING, State.WORKING]:
		return "interact-right"
	return super()


## Decide qué hacer ahora: descargar, buscar trabajo o ir a trabajar.
func _choose_task() -> void:
	if carried > 0: # p. ej. amaneció y aún llevaba algo encima
		_go_to_nearest_storage()
		return
	if not is_instance_valid(workplace):
		_find_job()
	if not is_instance_valid(workplace): # sin trabajo: espera quieto
		velocity = Vector3.ZERO
		return
	if workplace.resource_type == "wood":
		_go_to_nearest_tree()
	else:
		state = State.GOING_TO_WORK
		agent.target_position = workplace.global_position


func _find_job() -> void:
	workplace = _nearest_in_group("workplaces", func(w): return w.has_free_slot())
	if workplace:
		workplace.add_worker(self)


func _pick_up(type: String, amount: int) -> void:
	carried = amount
	carried_type = type
	if carried > 0:
		load_material.albedo_color = LOAD_COLORS[type]
		_go_to_nearest_storage()
	else:
		state = State.IDLE


func _deliver() -> void:
	if carried > 0:
		GameState.add_resource(carried_type, carried)
		carried = 0


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
		_deliver()
	state = State.SHELTERED
	visible = false
	collision_layer = 0


## Sale del refugio: vuelve a verse, a chocar y a ser una presa.
func _unhide() -> void:
	visible = true
	collision_layer = 2


func _go_to_nearest_tree() -> void:
	target = _nearest_in_group("trees",
		func(tree): return tree.is_free() and tree not in unreachable_trees)
	if target:
		target.worker = self # lo reserva: los demás buscarán otro
		agent.target_position = target.global_position
		state = State.GOING_TO_TREE
	else:
		velocity = Vector3.ZERO # no quedan árboles alcanzables: espera


## Si iba a un árbol o lo estaba talando, lo deja libre.
func _release_tree() -> void:
	if state in [State.GOING_TO_TREE, State.CHOPPING] and is_instance_valid(target):
		target.worker = null


func _go_to_nearest_storage() -> void:
	state = State.GOING_TO_STORAGE
	target = _nearest_in_group("storage")
	if target:
		agent.target_position = target.global_position
