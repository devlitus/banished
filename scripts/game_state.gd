extends Node
## Estado global de la partida: recursos y reloj de día/noche.
## Es un "autoload" (Proyecto → Configuración → Globales): Godot lo crea al arrancar
## y cualquier script puede usarlo escribiendo GameState.
## Otros nodos se enteran de lo que pasa conectándose a sus señales.

signal resources_changed
signal night_started(night: int)
signal day_started(day: int)

@export var day_length := 90.0 ## segundos
@export var night_length := 45.0

var resources := {"wood": 0, "stone": 0, "food": 0}
var day := 1 ## la noche N es la que sigue al día N
var is_night := false
var time_left := day_length


func _process(delta: float) -> void:
	time_left -= delta
	if time_left > 0:
		return
	if is_night:
		is_night = false
		day += 1
		time_left = day_length
		day_started.emit(day)
	else:
		is_night = true
		time_left = night_length
		night_started.emit(day)


func _unhandled_input(event: InputEvent) -> void:
	# Atajo para probar: N salta a la siguiente fase.
	if event.is_action_pressed("debug_skip_phase"):
		time_left = 0


func add_resource(type: String, amount: int) -> void:
	resources[type] += amount
	resources_changed.emit()
