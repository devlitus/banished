extends HBoxContainer
## Barra de construcción: un botón por cada tipo de edificio del BuildingPlacer.
## Los botones se crean por código a partir de los datos (BuildingType), así
## que añadir un edificio nuevo no requiere tocar esta escena.
## Teclas 1, 2, 3... también seleccionan.

@export var placer: Node

const RESOURCE_NAMES := {"wood": "madera", "stone": "piedra", "food": "comida"}

var buttons: Array[Button] = []


func _ready() -> void:
	var group := ButtonGroup.new() # solo uno pulsado a la vez
	for type: BuildingType in placer.building_types:
		var button := Button.new()
		button.text = "%s\n%s" % [type.display_name, _cost_text(type.cost)]
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE # que las teclas no "pulsen" el botón
		button.custom_minimum_size = Vector2(110, 0)
		button.pressed.connect(placer.select.bind(type))
		add_child(button)
		buttons.append(button)
	buttons[0].button_pressed = true
	GameState.resources_changed.connect(_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.physical_keycode - KEY_1
		if index >= 0 and index < buttons.size():
			buttons[index].button_pressed = true
			placer.select(placer.building_types[index])


## Atenúa los botones de lo que no te puedes permitir.
func _refresh() -> void:
	for i in buttons.size():
		var affordable: bool = GameState.can_afford(placer.building_types[i].cost)
		buttons[i].modulate = Color.WHITE if affordable else Color(1, 1, 1, 0.45)


func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for type: String in cost:
		parts.append("%d %s" % [cost[type], RESOURCE_NAMES[type]])
	return ", ".join(parts)
