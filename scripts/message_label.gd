extends Label
## Muestra los avisos de GameState.message unos segundos y luego los desvanece.

@export var show_time := 4.0

var tween: Tween = null


func _ready() -> void:
	modulate.a = 0
	GameState.message.connect(_show)


func _show(message: String) -> void:
	text = message
	modulate.a = 1
	if tween:
		tween.kill() # si había un aviso desvaneciéndose, lo cortamos
	tween = create_tween()
	tween.tween_interval(show_time)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
