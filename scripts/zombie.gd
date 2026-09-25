extends Unit
## Zombie: persigue al aldeano más cercano que esté a la intemperie y le golpea.
## Si todos están refugiados, va a por el refugio más cercano y lo golpea.
## Si algo le corta el paso (un muro, una torre...), lo golpea hasta romperlo.
## Como los aldeanos se mueven, recalcula la ruta cada "repath_interval" segundos
## (recalcularla en cada frame sería caro con muchos zombies).

@export var damage := 10
@export var attack_range := 0.8 ## distancia de golpe, medida desde el borde del objetivo
@export var attack_cooldown := 1.0 ## segundos entre golpes
@export var repath_interval := 0.5

var target: Node3D = null ## aldeano o refugio
var attack_timer := 0.0
var repath_timer := 0.0
var attacking := false ## si en este frame está golpeando algo (para la animación)


func _physics_process(delta: float) -> void:
	attack_timer -= delta
	repath_timer -= delta
	attacking = false
	if repath_timer <= 0:
		repath_timer = repath_interval
		_choose_target()

	# Primero comprobamos que sigue existiendo: preguntar "is" a un nodo borrado da error.
	if is_instance_valid(target) and target is Villager and target.is_sheltered:
		target = null # se nos ha escondido
	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		return

	if _in_reach(target):
		_attack(target)
	elif _move_along_path():
		# Se acabó la ruta y no llegamos: o el aldeano se movió, o algo nos bloquea.
		var blocker := _nearest_in_group("structures", _in_reach)
		if blocker:
			_attack(blocker)
		else:
			_walk_towards(target.global_position)


func _choose_target() -> void:
	target = _nearest_in_group("villagers", _is_prey)
	if not target:
		target = _nearest_in_group("shelter")
	if target:
		agent.target_position = target.global_position


## Una presa es un aldeano que no está refugiado.
func _is_prey(villager: Villager) -> bool:
	return not villager.is_sheltered


## ¿Está lo bastante cerca para golpearlo? Se mide desde su borde ("radius"),
## porque un almacén es más ancho que un aldeano.
func _in_reach(node: Node3D) -> bool:
	var offset := node.global_position - global_position
	offset.y = 0
	return offset.length() <= attack_range + radius + node.radius


func _current_animation() -> String:
	return "attack-melee-right" if attacking else super()


func _attack(node: Node3D) -> void:
	attacking = true
	velocity = Vector3.ZERO
	_face(node.global_position - global_position)
	if attack_timer <= 0:
		attack_timer = attack_cooldown
		node.take_damage(damage)
