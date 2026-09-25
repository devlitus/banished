extends PanelContainer
## Pantalla de fin de partida. Pausa el juego (get_tree().paused) y ofrece
## volver a empezar. Este nodo tiene process_mode = ALWAYS para que su botón
## funcione aunque todo lo demás esté en pausa.

@onready var title: Label = $Box/Title
@onready var details: Label = $Box/Details
@onready var restart_button: Button = $Box/Restart


func _ready() -> void:
	visible = false
	restart_button.pressed.connect(_restart)


func show_result(title_text: String, details_text: String) -> void:
	title.text = title_text
	details.text = details_text
	visible = true
	get_tree().paused = true


func _restart() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().reload_current_scene()
