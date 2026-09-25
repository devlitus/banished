extends PanelContainer
## Guía de primeros pasos: muestra el primer consejo que aún no se ha cumplido.
## Cada consejo se cumple al construir cierto edificio; cuando están todos, se oculta.
## Si el jugador se adelanta (p. ej. construye la torre antes que la granja),
## ese paso ya cuenta como hecho y la guía salta al siguiente pendiente.

const STEPS := [
	{"building": "Cantera", "text": "Construye una CANTERA (tecla 4).\nDos aldeanos sin trabajo irán a picar piedra."},
	{"building": "Granja", "text": "Construye una GRANJA (tecla 5).\nAl amanecer cada aldeano come 2 de comida:\nsi falta, alguien muere de hambre."},
	{"building": "Torre", "text": "Construye una TORRE (tecla 7) cerca del almacén.\nDispara a los zombies que se acerquen."},
	{"building": "Casa", "text": "Construye una CASA (tecla 1).\nSi hay sitio y sobra comida, al amanecer\nnacen aldeanos nuevos."},
	{"building": "Muro", "text": "Pon MUROS (tecla 6) en el lado de la franja roja:\npor ahí entrará la horda esta noche."},
]

@onready var label: Label = $Label


func _process(_delta: float) -> void:
	var built := _built_names()
	for i in STEPS.size():
		if STEPS[i].building not in built:
			label.text = "Primeros pasos (%d/%d)\n\n%s" % [i + 1, STEPS.size(), STEPS[i].text]
			return
	GameState.message.emit("¡Colonia en marcha! Sobrevive %d noches" % GameState.NIGHTS_TO_WIN)
	queue_free() # guía completada: ya no hace falta


## Nombres de los edificios que ha construido el jugador ("Cantera", "Torre"...).
func _built_names() -> Array:
	var names := []
	for building in get_tree().get_nodes_in_group("buildings"):
		names.append(building.building_type.display_name)
	return names
