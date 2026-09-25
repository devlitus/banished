extends Node3D
## Coloca edificios (cubos) sobre una cuadrícula con el ratón.
## Un cubo semitransparente ("fantasma") sigue al ratón: verde = se puede, rojo = ocupado.
## Clic izquierdo = construir, clic derecho = demoler.
## Los nodos del grupo "obstacles" (árboles, almacén) también ocupan su celda.

const CELL_SIZE := 2.0

@export var building_scene: PackedScene
@export var map_half_size := 20.0 ## el suelo mide 40x40, centrado en el origen
@export var buildings_parent: Node3D ## dónde se añaden los edificios construidos

@onready var ghost: MeshInstance3D = $Ghost

var occupied := {} ## celda (Vector2i) -> edificio (Node3D)
var hovered_cell: Variant = null ## Vector2i bajo el ratón, o null si está fuera del mapa
var ghost_material := StandardMaterial3D.new()


func _ready() -> void:
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.material_override = ghost_material
	for obstacle: Node3D in get_tree().get_nodes_in_group("obstacles"):
		occupied[world_to_cell(obstacle.global_position)] = obstacle


func _process(_delta: float) -> void:
	hovered_cell = _cell_under_mouse()
	ghost.visible = hovered_cell != null
	if hovered_cell == null:
		return
	# El cubo mide 2 de alto, lo subimos 1 para que se apoye en el suelo.
	ghost.position = cell_to_world(hovered_cell) + Vector3(0, 1, 0)
	if _is_free(hovered_cell):
		ghost_material.albedo_color = Color(0.2, 1, 0.3, 0.4)
	else:
		ghost_material.albedo_color = Color(1, 0.2, 0.2, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	if hovered_cell == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place(hovered_cell)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_remove(hovered_cell)


func _place(cell: Vector2i) -> void:
	if not _is_free(cell):
		return
	var building: Node3D = building_scene.instantiate()
	building.position = cell_to_world(cell)
	buildings_parent.add_child(building)
	occupied[cell] = building
	get_tree().call_group("navigation", "rebake")


func _remove(cell: Vector2i) -> void:
	if _is_free(cell):
		return
	var building: StaticBody3D = occupied[cell]
	if not building.is_in_group("buildings"): # árboles y almacén no se demuelen
		return
	building.collision_layer = 0 # que la navegación deje de verlo antes de borrarlo
	building.queue_free()
	occupied.erase(cell)
	get_tree().call_group("navigation", "rebake")


## Una celda está libre si no hay nada o si lo que había ya se borró (p. ej. un árbol talado).
func _is_free(cell: Vector2i) -> bool:
	return not (occupied.has(cell) and is_instance_valid(occupied[cell]))


## Lanza un rayo desde la cámara a través del ratón y mira dónde corta el suelo (y = 0).
func _cell_under_mouse() -> Variant:
	var camera := get_viewport().get_camera_3d()
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	var hit: Variant = Plane(Vector3.UP, 0).intersects_ray(origin, direction)
	if hit == null:
		return null
	if absf(hit.x) >= map_half_size or absf(hit.z) >= map_half_size:
		return null
	return world_to_cell(hit)


func world_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.z / CELL_SIZE))


## Centro de una celda en coordenadas del mundo.
func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3((cell.x + 0.5) * CELL_SIZE, 0, (cell.y + 0.5) * CELL_SIZE)
