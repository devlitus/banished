extends Node3D
## Planifica y lanza las hordas.
## Al amanecer decide cómo será la noche siguiente (cuántos zombies y por qué
## lados) y lo anuncia: así el jugador sabe dónde defenderse.
## Al anochecer los zombies aparecen en una franja de los lados anunciados.
## Al amanecer, los zombies que quedan se queman (desaparecen).

signal wave_planned ## el plan de la próxima noche ha cambiado

## Oleada de cada noche: [zombies, lados por los que atacan]. Tras la última se repite esta.
const WAVES := [[2, 1], [3, 1], [5, 1], [6, 1], [8, 2], [10, 2], [12, 2], [14, 2], [17, 3], [20, 3]]
## Hacia dónde queda cada lado, visto desde el centro del mapa.
const SIDES := {
	"NORTE": Vector3(0, 0, -1),
	"SUR": Vector3(0, 0, 1),
	"OESTE": Vector3(-1, 0, 0),
	"ESTE": Vector3(1, 0, 0),
}
const WARNING_TIME := 15.0 ## segundos antes de anochecer en que se avisa

@export var zombie_scene: PackedScene
@export var spawn_distance := 18.0 ## a qué distancia del centro aparecen (el mapa llega a 20)
@export var band_width := 16.0 ## largo de la franja del borde por la que entran

var next_count := 0
var next_sides: Array[String] = []
var warned := false
var markers: Array[Node3D] = []


func _ready() -> void:
	GameState.night_started.connect(_on_night_started)
	GameState.day_started.connect(_on_day_started)
	_plan_wave(GameState.day)


func _process(_delta: float) -> void:
	if not GameState.is_night and not warned and GameState.time_left <= WARNING_TIME:
		warned = true
		GameState.message.emit("¡La horda llega en %d s por el %s!" % [WARNING_TIME, sides_text()])


## "NORTE", "NORTE y ESTE", "NORTE, SUR y ESTE"...
func sides_text() -> String:
	if next_sides.size() == 1:
		return next_sides[0]
	return ", ".join(next_sides.slice(0, -1)) + " y " + next_sides[-1]


func _plan_wave(night: int) -> void:
	var wave: Array = WAVES[mini(night, WAVES.size()) - 1]
	next_count = wave[0]
	var sides: Array = SIDES.keys()
	sides.shuffle()
	next_sides.assign(sides.slice(0, wave[1]))
	warned = false
	_show_markers()
	wave_planned.emit()


func _on_night_started(_night: int) -> void:
	_hide_markers()
	for i in next_count:
		var zombie: Node3D = zombie_scene.instantiate()
		zombie.position = _spawn_point(next_sides[i % next_sides.size()])
		add_child(zombie)


func _on_day_started(day: int) -> void:
	for zombie in get_children():
		if zombie.is_in_group("zombies"):
			zombie.die()
	_plan_wave(day)


## Punto al azar en la franja del lado indicado.
func _spawn_point(side: String) -> Vector3:
	var out: Vector3 = SIDES[side]
	var along := Vector3(-out.z, 0, out.x) # perpendicular: a lo largo del borde
	return out * spawn_distance + along * randf_range(-band_width / 2, band_width / 2)


## Una franja roja que late en cada lado por el que vendrá la horda.
func _show_markers() -> void:
	_hide_markers()
	for side in next_sides:
		var out: Vector3 = SIDES[side]
		var marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(band_width, 0.05, 1.5)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(1, 0.15, 0.1, 0.6)
		mesh.material = material
		marker.mesh = mesh
		marker.position = out * spawn_distance + Vector3(0, 0.05, 0)
		if out.x != 0: # este/oeste: la franja va de norte a sur
			marker.rotation.y = PI / 2
		add_child(marker)
		markers.append(marker)
		# Late: la transparencia sube y baja sin parar.
		var tween := marker.create_tween().set_loops()
		tween.tween_property(material, "albedo_color:a", 0.15, 0.8)
		tween.tween_property(material, "albedo_color:a", 0.6, 0.8)


func _hide_markers() -> void:
	for marker in markers:
		marker.queue_free()
	markers.clear()
