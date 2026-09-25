extends StaticBody3D
## Árbol: fuente de madera. Cuando se agota, desaparece.
## Solo admite un leñador a la vez: el aldeano lo "reserva" guardándose en "worker".

@export var wood := 30
@export var radius := 0.3 ## tamaño en el suelo (el del tronco)
@export var models: Array[PackedScene] = [] ## cada árbol elige uno al azar

var worker: Node3D = null ## aldeano que lo tiene reservado


## Para que el bosque no parezca copiado y pegado: modelo y giro al azar.
func _ready() -> void:
	var model_holder: Node3D = $Model
	if not models.is_empty():
		for child in model_holder.get_children():
			child.free()
		model_holder.add_child(models.pick_random().instantiate())
	model_holder.rotation.y = randf() * TAU


func is_free() -> bool:
	# Si el aldeano que lo reservó ha muerto, is_instance_valid da false.
	return not is_instance_valid(worker)


## Quita hasta "amount" de madera y devuelve cuánta se ha llevado de verdad.
func take_wood(amount: int) -> int:
	var taken := mini(amount, wood)
	wood -= taken
	if wood <= 0:
		_deplete()
	return taken


func _deplete() -> void:
	remove_from_group("trees") # ningún aldeano lo volverá a elegir
	collision_layer = 0 # así la navegación ya no lo cuenta como obstáculo
	get_tree().call_group("navigation", "rebake")
	queue_free()
