extends StaticBody3D
## Árbol: fuente de madera. Cuando se agota, desaparece.
## Solo admite un leñador a la vez: el aldeano lo "reserva" guardándose en "worker".

@export var wood := 20
@export var radius := 0.3 ## tamaño en el suelo (el del tronco)

var worker: Node3D = null ## aldeano que lo tiene reservado


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
