extends Node3D
## Cámara isométrica.
## El "rig" (este nodo) está en el suelo y la Camera3D hija lo mira desde arriba
## en diagonal. Mover o girar el rig mueve la cámara con él.
## Controles: WASD / flechas = mover, Q / E = girar, rueda = zoom.

@export var move_speed := 15.0
@export var rotate_speed := 90.0 ## grados por segundo
@export var zoom_step := 2.0
@export var min_zoom := 8.0
@export var max_zoom := 40.0
@export var map_limit := 20.0 ## la cámara no se aleja del centro más que esto

@onready var camera: Camera3D = $Camera3D


func _process(delta: float) -> void:
	# get_vector devuelve x = derecha/izquierda, y = atrás/adelante (entre -1 y 1).
	var input := Input.get_vector("camera_left", "camera_right", "camera_forward", "camera_back")
	# Pasamos la dirección a los ejes del rig, así "adelante" es hacia donde mira la cámara.
	var direction := transform.basis * Vector3(input.x, 0, input.y)
	# Con zoom alejado nos movemos más rápido.
	position += direction * move_speed * (camera.size / 20.0) * delta
	position.x = clampf(position.x, -map_limit, map_limit)
	position.z = clampf(position.z, -map_limit, map_limit)

	var turn := Input.get_axis("camera_rotate_left", "camera_rotate_right")
	rotate_y(deg_to_rad(turn * rotate_speed * delta))


func _unhandled_input(event: InputEvent) -> void:
	# Cámara ortográfica: el zoom se hace cambiando "size" (cuánto mundo cabe en pantalla).
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = clampf(camera.size - zoom_step, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = clampf(camera.size + zoom_step, min_zoom, max_zoom)
