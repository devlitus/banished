class_name Unit
extends CharacterBody3D
## Base común de aldeanos y zombies: vida, daño y movimiento con navegación.
## Villager y Zombie "heredan" de Unit (extends Unit), así que tienen todo esto
## sin repetirlo. Cada escena que use este script necesita un nodo hijo "Body"
## (Node3D con el modelo 3D dentro) y otro "NavigationAgent3D".

signal died

const LOOPED_ANIMATIONS := ["idle", "walk", "interact-right", "attack-melee-right"]

@export var speed := 3.0
@export var max_health := 30
@export var radius := 0.3 ## tamaño en el suelo; los zombies lo usan para saber si llegan a golpear
@export var models: Array[PackedScene] = [] ## si hay varios, cada unidad elige uno al azar
@export var tint := Color.WHITE ## color que se mezcla con el del modelo (verde para zombies)

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var body: Node3D = $Body

var health := 0
var hit_material := StandardMaterial3D.new() ## capa roja al recibir un golpe
var meshes: Array[MeshInstance3D] = []
var anim: AnimationPlayer = null ## el del modelo (null si no tiene animaciones)


func _ready() -> void:
	health = max_health
	hit_material.albedo_color = Color(1, 0.15, 0.15, 0.6)
	hit_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hit_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_setup_model()


func _process(_delta: float) -> void:
	if anim:
		var animation_name := _current_animation()
		if anim.current_animation != animation_name:
			anim.play(animation_name, 0.2) # 0.2 s de mezcla entre animaciones


## Qué animación toca ahora. Villager y Zombie la cambian para trabajar o atacar.
func _current_animation() -> String:
	return "walk" if velocity.length() > 0.1 else "idle"


## Cambia el modelo por uno al azar de "models", lo tiñe y busca sus animaciones.
func _setup_model() -> void:
	if not models.is_empty():
		for child in body.get_children():
			child.free()
		body.add_child(models.pick_random().instantiate())
	for node in body.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node)
		if tint != Color.WHITE:
			for i in node.mesh.get_surface_count():
				var material: BaseMaterial3D = node.mesh.surface_get_material(i).duplicate()
				material.albedo_color *= tint
				node.set_surface_override_material(i, material)
	anim = body.find_child("AnimationPlayer", true, false)
	if anim:
		for animation_name in LOOPED_ANIMATIONS:
			if anim.has_animation(animation_name):
				anim.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR


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


## Se pone rojo un momento (una capa encima de su material, en todas sus mallas).
## El Tween pertenece a este nodo, así que si muere antes de terminar,
## el Tween desaparece con él sin dar errores.
func _flash() -> void:
	_set_overlay(hit_material)
	var tween := create_tween()
	tween.tween_interval(0.15)
	tween.tween_callback(_set_overlay.bind(null))


func _set_overlay(material: Material) -> void:
	for mesh in meshes:
		mesh.material_overlay = material


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
