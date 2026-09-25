extends Structure
## Torre: dispara flechas al zombie más cercano que esté a su alcance.

@export var shoot_range := 8.0
@export var fire_interval := 1.0 ## segundos entre disparos
@export var damage := 10
@export var projectile_scene: PackedScene
@export var muzzle_height := 3.2 ## altura desde la que sale la flecha

var cooldown := 0.0


func _physics_process(delta: float) -> void:
	cooldown -= delta
	if cooldown > 0:
		return
	var zombie := _nearest_zombie_in_range()
	if zombie:
		cooldown = fire_interval
		_shoot(zombie)


func _nearest_zombie_in_range() -> Node3D:
	var best: Node3D = null
	var best_distance: float = shoot_range + GameState.bonuses.tower_range
	for zombie: Node3D in get_tree().get_nodes_in_group("zombies"):
		var d := global_position.distance_to(zombie.global_position)
		if d <= best_distance:
			best = zombie
			best_distance = d
	return best


func _shoot(zombie: Node3D) -> void:
	var projectile: Node3D = projectile_scene.instantiate()
	projectile.target = zombie
	projectile.damage = roundi(damage * GameState.bonuses.tower_damage)
	add_child(projectile)
	# top_level: la flecha se mueve en coordenadas del mundo, no relativas a la torre.
	projectile.top_level = true
	projectile.global_position = global_position + Vector3(0, muzzle_height, 0)
