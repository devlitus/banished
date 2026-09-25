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

@onready var load_mesh: Node3D = $Load ## el "tronco" que lleva en brazos

var state := State.IDLE
var target: Node3D = null ## árbol, almacén o refugio al que va
var carried := 0
var chop_timer := 0.0
var nav: Node = null

## Propiedad calculada: se lee como una variable, pero su valor sale de "state".
var is_sheltered: bool:
	get:
		return state == State.SHELTERED


func _ready() -> void:
	super() # ejecuta también el _ready() de Unit
	nav = get_tree().get_first_node_in_group("navigation")
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
				_deliver_wood()
				state = State.IDLE

		State.GOING_TO_SHELTER:
			if not is_instance_valid(target):
				_go_to_nearest_shelter()
			elif _move_along_path():
				_hide()

		State.SHELTERED:
			pass # esperando dentro a que amanezca

	load_mesh.visible = carried > 0


func _on_night_started(_night: int) -> void:
	_go_to_nearest_shelter()


func _on_day_started(_day: int) -> void:
	if state == State.SHELTERED:
		# Sale del refugio: vuelve a verse, a chocar y a ser una presa.
		visible = true
		collision_layer = 2
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


func _deliver_wood() -> void:
	if carried > 0:
		GameState.add_resource("wood", carried)
		carried = 0


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
