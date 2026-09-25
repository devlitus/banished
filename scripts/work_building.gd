class_name WorkBuilding
extends Structure
## Edificio de trabajo (leñador, cantera, granja) con plazas para aldeanos.
## Los aldeanos sin trabajo buscan uno con plaza libre y se apuntan solos.
## - Leñador (wood): sus trabajadores talan árboles.
## - Cantera (stone) y granja (food): sus trabajadores trabajan aquí "work_time"
##   segundos y se llevan "amount_per_trip" al almacén.

@export var display_name := ""
@export var resource_type := "wood" ## "wood", "stone" o "food"
@export var max_workers := 2
@export var work_time := 5.0
@export var amount_per_trip := 4

var workers := [] ## aldeanos apuntados (pueden haber muerto: ver has_free_slot)
var info_label := Label3D.new()


func _ready() -> void:
	super()
	add_to_group("workplaces")
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 36
	info_label.pixel_size = 0.01
	info_label.outline_size = 10
	info_label.position.y = label_height
	health_label.position.y = label_height + 0.5 # la vida, un poco más arriba
	add_child(info_label)


func _process(_delta: float) -> void:
	info_label.text = "%s %d/%d" % [display_name, _living_workers().size(), max_workers]


func has_free_slot() -> bool:
	return _living_workers().size() < max_workers


func add_worker(villager: Node3D) -> void:
	workers.append(villager)


## Quita de la lista a los que han muerto.
func _living_workers() -> Array:
	workers = workers.filter(func(w): return is_instance_valid(w))
	return workers
