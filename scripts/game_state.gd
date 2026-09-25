extends Node
## Estado global de la partida.
## Es un "autoload" (Proyecto → Configuración → Globales): Godot lo crea al arrancar
## y cualquier script puede usarlo escribiendo GameState.

signal resources_changed

var resources := {"wood": 0, "stone": 0, "food": 0}


func add_resource(type: String, amount: int) -> void:
	resources[type] += amount
	resources_changed.emit()
