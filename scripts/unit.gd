class_name Unit
extends CharacterBody3D
## Base común de aldeanos y zombies: vida, daño y movimiento con navegación.
## Villager y Zombie "heredan" de Unit (extends Unit), así que tienen todo esto
## sin repetirlo. Cada escena que use este script necesita un nodo hijo "Body"
## (MeshInstance3D) y otro "NavigationAgent3D".

signal died

@export var speed := 3.0
@export var max_health := 30

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var body_mesh: MeshInstance3D = $Body

var health := 0
var hit_material := StandardMaterial3D.new() ## color al recibir un golpe


func _ready() -> void:
	health = max_health
	hit_material.albedo_color = Color(1, 0.15, 0.15)


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	_flash()
	if health <= 0:
		die()


func die() -> void:
	died.emit()
	queue_free()


## Se pone rojo un momento. El Tween pertenece a este nodo, así que si muere
## antes de terminar, el Tween desaparece con él sin dar errores.
func _flash() -> void:
	body_mesh.material_override = hit_material
	var tween := create_tween()
	tween.tween_interval(0.15)
	tween.tween_callback(func(): body_mesh.material_override = null)


## Da un paso siguiendo la ruta del NavigationAgent3D. Devuelve true al llegar.
func _move_along_path() -> bool:
	if agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return true
	_walk_towards(agent.get_next_path_position())
	return false


## Camina en línea recta hacia un punto (ignorando la altura) y mira hacia él.
func _walk_towards(point: Vector3) -> void:
	var direction := point - global_position
	direction.y = 0
	velocity = direction.normalized() * speed
	move_and_slide()
	_face(direction)


func _face(direction: Vector3) -> void:
	direction.y = 0
	if direction.length() > 0.01:
		look_at(global_position + direction)


## El más cercano de un grupo. "accept" es opcional: una función que recibe
## cada nodo y devuelve false para descartarlo.
func _nearest_in_group(group: String, accept := Callable()) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for node: Node3D in get_tree().get_nodes_in_group(group):
		if accept.is_valid() and not accept.call(node):
			continue
		var d := global_position.distance_squared_to(node.global_position)
		if d < best_distance:
			best = node
			best_distance = d
	return best
