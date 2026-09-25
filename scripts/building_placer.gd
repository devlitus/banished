extends Node3D
## Coloca edificios sobre una cuadrícula con el ratón.
## Un cubo semitransparente ("fantasma") sigue al ratón: verde = se puede, rojo = no
## (celda ocupada, hay alguien encima o no te llega el dinero).
## Clic izquierdo = construir el tipo seleccionado, clic derecho = demoler (devuelve la mitad).
## Lo que ya viene en el mapa (árboles, estructuras) también ocupa su celda,
## pero solo se puede demoler lo construido por el jugador (grupo "buildings").

const CELL_SIZE := 2.0

@export var building_types: Array[BuildingType] = []
@export var map_half_size := 20.0 ## el suelo mide 40x40, centrado en el origen
@export var buildings_parent: Node3D ## dónde se añaden los edificios construidos

@onready var ghost: MeshInstance3D = $Ghost

var selected: BuildingType = null
var occupied := {} ## celda (Vector2i) -> nodo que la ocupa
var hovered_cell: Variant = null ## Vector2i bajo el ratón, o null si está fuera del mapa
var ghost_material := StandardMaterial3D.new()


func _ready() -> void:
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.material_override = ghost_material
	for group in ["obstacles", "structures"]:
		for node: Node3D in get_tree().get_nodes_in_group(group):
			occupied[world_to_cell(node.global_position)] = node
	if not building_types.is_empty():
		selected = building_types[0]


func select(type: BuildingType) -> void:
	selected = type


func _process(_delta: float) -> void:
	hovered_cell = _cell_under_mouse()
	ghost.visible = hovered_cell != null
	if hovered_cell == null:
		return
	# El cubo mide 2 de alto, lo subimos 1 para que se apoye en el suelo.
	ghost.position = cell_to_world(hovered_cell) + Vector3(0, 1, 0)
	if _can_build(hovered_cell):
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
	if not _can_build(cell):
		return
	GameState.spend(selected.cost)
	var building: Structure = selected.scene.instantiate()
	building.building_type = selected
	building.add_to_group("buildings") # construido por el jugador: se puede demoler
	building.position = cell_to_world(cell)
	buildings_parent.add_child(building)
	occupied[cell] = building
	get_tree().call_group("navigation", "rebake")


func _remove(cell: Vector2i) -> void:
	if _is_free(cell):
		return
	var building: Node3D = occupied[cell]
	if not building.is_in_group("buildings"): # lo que venía en el mapa no se demuele
		return
	for type: String in building.building_type.cost: # devuelve la mitad
		GameState.add_resource(type, floori(building.building_type.cost[type] / 2.0))
	building.destroy()
	occupied.erase(cell)


func _can_build(cell: Vector2i) -> bool:
	return (selected != null
		and _is_free(cell)
		and not _has_unit_on(cell)
		and GameState.can_afford(selected.cost))


## Una celda está libre si no hay nada o si lo que había ya no existe
## (un árbol talado, un muro destruido por los zombies...).
func _is_free(cell: Vector2i) -> bool:
	return not (occupied.has(cell) and is_instance_valid(occupied[cell]))


## ¿Hay un aldeano o un zombie en la celda? Construir encima lo dejaría atrapado.
func _has_unit_on(cell: Vector2i) -> bool:
	for group in ["villagers", "zombies"]:
		for unit: Node3D in get_tree().get_nodes_in_group(group):
			if world_to_cell(unit.global_position) == cell:
				return true
	return false


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
