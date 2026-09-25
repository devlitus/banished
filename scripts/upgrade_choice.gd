extends PanelContainer
## Mejora al amanecer: tras sobrevivir una noche, pausa el juego y ofrece
## 3 cartas al azar. La elegida cambia GameState.bonuses (o da recursos) para
## el resto de la partida. Tiene process_mode = ALWAYS para funcionar en pausa.

const CHOICES := 3

## "unique": solo se puede elegir una vez (después ya no vuelve a salir).
var cards := [
	{"name": "Arqueros expertos", "text": "Torres +30 % de daño",
		"apply": func(b): b.tower_damage += 0.3},
	{"name": "Vigías", "text": "Torres +2 de alcance",
		"apply": func(b): b.tower_range += 2.0},
	{"name": "Muros reforzados", "text": "Muros, torres y edificios\n+50 % de vida",
		"apply": func(b): b.structure_health += 0.5},
	{"name": "Brazos fuertes", "text": "Aldeanos +2 de carga\npor viaje",
		"apply": func(b): b.carry += 2},
	{"name": "Buena cosecha", "text": "Granjas +50 % de comida",
		"apply": func(b): b.farm += 0.5},
	{"name": "Racionamiento", "text": "Cada aldeano come 1\nen vez de 2", "unique": true,
		"apply": func(b): b.food_saved = 1},
	{"name": "Pies ligeros", "text": "Aldeanos +25 % de velocidad",
		"apply": func(b): b.villager_speed += 0.25},
	{"name": "Carromato de suministros", "text": "+40 madera y +25 piedra\nal momento",
		"apply": _add_supplies},
]

@export var colony: Node

@onready var buttons_box: HBoxContainer = $Box/Cards


func _ready() -> void:
	visible = false
	GameState.day_started.connect(_on_day_started)


func _on_day_started(_day: int) -> void:
	# call_deferred: esperamos a que la colonia procese el amanecer (quizá se acabó la partida).
	_offer.call_deferred()


func _offer() -> void:
	if colony.game_ended:
		return
	for child in buttons_box.get_children():
		child.queue_free()
	var available := cards.duplicate()
	available.shuffle()
	for card in available.slice(0, CHOICES):
		var button := Button.new()
		button.text = "%s\n\n%s" % [card.name, card.text]
		button.custom_minimum_size = Vector2(230, 130)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_choose.bind(card))
		buttons_box.add_child(button)
	visible = true
	get_tree().paused = true


func _add_supplies(_bonuses: Dictionary) -> void:
	GameState.add_resource("wood", 40)
	GameState.add_resource("stone", 25)


func _choose(card: Dictionary) -> void:
	card.apply.call(GameState.bonuses)
	if card.get("unique", false):
		cards.erase(card)
	# Si ha subido la vida de los edificios, que empiecen el día con la nueva vida máxima.
	get_tree().call_group("structures", "_repair", GameState.day)
	GameState.message.emit("Mejora: %s" % card.name)
	visible = false
	get_tree().paused = false
