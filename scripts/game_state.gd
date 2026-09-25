extends Node
## Estado global de la partida: recursos y reloj de día/noche.
## Es un "autoload" (Proyecto → Configuración → Globales): Godot lo crea al arrancar
## y cualquier script puede usarlo escribiendo GameState.
## Otros nodos se enteran de lo que pasa conectándose a sus señales.

signal resources_changed
signal night_started(night: int)
signal day_started(day: int)
signal message(text: String) ## avisos para el jugador ("Ha nacido un aldeano"...)

const START_RESOURCES := {"wood": 40, "stone": 20, "food": 30}
## Mejoras de las cartas del amanecer. Cada script las lee al usarlas.
const START_BONUSES := {
	"tower_damage": 1.0, ## multiplicador
	"tower_range": 0.0, ## se suma
	"structure_health": 1.0, ## multiplicador
	"carry": 0, ## se suma a lo que llevan por viaje
	"farm": 1.0, ## multiplicador de la comida de las granjas
	"food_saved": 0, ## se resta a lo que come cada aldeano
	"villager_speed": 1.0, ## multiplicador
}
const NIGHTS_TO_WIN := 10

@export var day_length := 90.0 ## segundos
@export var night_length := 45.0

var resources := START_RESOURCES.duplicate()
var bonuses := START_BONUSES.duplicate()
var day := 1 ## la noche N es la que sigue al día N
var is_night := false
var time_left := day_length


## Deja todo como al principio (para "Jugar otra vez").
func reset() -> void:
	resources = START_RESOURCES.duplicate()
	bonuses = START_BONUSES.duplicate()
	day = 1
	is_night = false
	time_left = day_length


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
		message.emit("¡Cae la noche %d! Los aldeanos corren a refugiarse" % day)
		night_started.emit(day)


func _unhandled_input(event: InputEvent) -> void:
	# Atajo para probar: N salta a la siguiente fase.
	if event.is_action_pressed("debug_skip_phase"):
		time_left = 0


func add_resource(type: String, amount: int) -> void:
	resources[type] += amount
	resources_changed.emit()


## cost es un diccionario tipo {"wood": 5, "stone": 2}.
func can_afford(cost: Dictionary) -> bool:
	for type: String in cost:
		if resources[type] < cost[type]:
			return false
	return true


func spend(cost: Dictionary) -> void:
	for type: String in cost:
		resources[type] -= cost[type]
	resources_changed.emit()
