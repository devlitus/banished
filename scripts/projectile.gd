extends Node3D
## Flecha que persigue a su objetivo y le hace daño al alcanzarlo.
## Si el objetivo muere antes, la flecha desaparece.

@export var speed := 20.0

var target: Node3D = null
var damage := 0


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	var aim := target.global_position + Vector3(0, 0.8, 0) # al pecho, no a los pies
	var to_aim := aim - global_position
	var step := speed * delta
	if to_aim.length() <= step:
		target.take_damage(damage)
		queue_free()
		return
	look_at(aim)
	global_position += to_aim.normalized() * step
