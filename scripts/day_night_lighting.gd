extends WorldEnvironment
## Cambia la luz entre el día y la noche con una transición suave (Tween).

@export var sun: DirectionalLight3D
@export var transition_time := 3.0

const DAY_LOOK := {
	sun_energy = 1.0,
	sun_color = Color(1, 0.97, 0.9),
	ambient = 0.5,
	sky = Color(0.55, 0.7, 0.85),
}
const NIGHT_LOOK := {
	sun_energy = 0.2,
	sun_color = Color(0.45, 0.55, 1),
	ambient = 0.25,
	sky = Color(0.05, 0.07, 0.15),
}


func _ready() -> void:
	GameState.day_started.connect(func(_day): _change_to(DAY_LOOK))
	GameState.night_started.connect(func(_night): _change_to(NIGHT_LOOK))


func _change_to(look: Dictionary) -> void:
	# set_parallel(): todas las animaciones del Tween a la vez, no una tras otra.
	var tween := create_tween().set_parallel()
	tween.tween_property(sun, "light_energy", look.sun_energy, transition_time)
	tween.tween_property(sun, "light_color", look.sun_color, transition_time)
	tween.tween_property(environment, "ambient_light_energy", look.ambient, transition_time)
	tween.tween_property(environment, "background_color", look.sky, transition_time)
