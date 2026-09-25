extends StaticBody3D
## Árbol: fuente de madera. Cuando se agota, desaparece.

@export var wood := 20


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
