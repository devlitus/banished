class_name Structure
extends StaticBody3D
## Base de todo lo construido que los zombies pueden destruir: muros, torres, almacén.
## Cuando recibe daño muestra su vida encima; al llegar a 0 desaparece y la
## navegación se recalcula (por ese hueco ya se puede pasar).

signal destroyed

@export var max_health := 100
@export var radius := 0.9 ## medio lado; los zombies lo usan para saber si llegan a golpearlo
@export var label_height := 2.6

var health := 0
var building_type: BuildingType = null ## con qué tipo se construyó (null si venía en el mapa)
var health_label := Label3D.new()


func _ready() -> void:
	health = full_health()
	add_to_group("structures")
	# Etiqueta de vida creada por código: siempre mira a la cámara (billboard)
	# y se dibuja por encima de todo (no_depth_test).
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label.no_depth_test = true
	health_label.font_size = 48
	health_label.pixel_size = 0.01 # tamaño en el mundo de cada píxel del texto
	health_label.outline_size = 12
	health_label.position.y = label_height
	health_label.visible = false
	add_child(health_label)
	GameState.day_started.connect(_repair)


## Al amanecer los aldeanos lo reparan: cada noche empieza con todo entero.
func _repair(_day: int) -> void:
	health = full_health()
	health_label.visible = false


## Vida máxima con la mejora "Muros reforzados" aplicada.
func full_health() -> int:
	return roundi(max_health * GameState.bonuses.structure_health)


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	health_label.visible = true
	health_label.text = "%d/%d" % [maxi(health, 0), full_health()]
	var fraction := float(health) / full_health()
	health_label.modulate = Color(1, 0.3, 0.3) if fraction < 0.35 else Color(1, 1, 1)
	if health <= 0:
		destroy()


func destroy() -> void:
	destroyed.emit()
	collision_layer = 0 # que la navegación deje de verlo antes de borrarlo
	get_tree().call_group("navigation", "rebake")
	queue_free()
