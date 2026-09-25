extends Unit
## Zombie: persigue al aldeano más cercano que esté a la intemperie y le golpea.
## Si todos están refugiados, ronda el refugio más cercano (en el hito 4 lo atacará).
## Como los aldeanos se mueven, recalcula la ruta cada "repath_interval" segundos
## (recalcularla en cada frame sería caro con muchos zombies).

@export var damage := 10
@export var attack_range := 1.2
@export var attack_cooldown := 1.0 ## segundos entre golpes
@export var repath_interval := 0.5

var target: Node3D = null ## el aldeano perseguido
var attack_timer := 0.0
var repath_timer := 0.0


func _physics_process(delta: float) -> void:
	attack_timer -= delta
	repath_timer -= delta
	if repath_timer <= 0:
		repath_timer = repath_interval
		_choose_target()

	if not _is_prey(target):
		_move_along_path() # nadie a quien perseguir: va hacia el refugio
		return

	var to_target := target.global_position - global_position
	to_target.y = 0
	if to_target.length() <= attack_range:
		velocity = Vector3.ZERO
		_face(to_target)
		if attack_timer <= 0:
			attack_timer = attack_cooldown
			target.take_damage(damage)
	elif _move_along_path():
		# Llegó al final de la ruta, pero el aldeano ya se ha movido: va directo a él.
		_walk_towards(target.global_position)


func _choose_target() -> void:
	target = _nearest_in_group("villagers", _is_prey)
	if target:
		agent.target_position = target.global_position
		return
	var shelter := _nearest_in_group("shelter")
	if shelter:
		agent.target_position = shelter.global_position


## Una presa es un aldeano vivo que no está refugiado.
func _is_prey(villager: Node3D) -> bool:
	return is_instance_valid(villager) and not villager.is_sheltered
