class_name BuildingType
extends Resource
## Datos de un tipo de edificio (nombre, escena y coste).
## Cada tipo es un archivo .tres en data/buildings/ que se edita desde el
## Inspector: para cambiar el coste de un muro no hace falta tocar código.

@export var display_name := ""
@export var scene: PackedScene
@export var cost := {} ## p. ej. {"wood": 5}
