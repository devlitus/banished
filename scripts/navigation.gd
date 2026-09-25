extends NavigationRegion3D
## Genera la malla de navegación: la zona del suelo por la que se puede caminar.
## Se calcula a partir de los colisionadores (StaticBody3D) que cuelgan de este nodo:
## el suelo suma zona caminable y los árboles y edificios hacen agujeros.
## Cualquier script puede pedir que se recalcule con:
##     get_tree().call_group("navigation", "rebake")

var is_ready := false ## false hasta que termina el primer cálculo
var _pending := false ## alguien pidió recalcular mientras ya se estaba calculando


func _ready() -> void:
	bake_finished.connect(_on_bake_finished)
	rebake()


func rebake() -> void:
	if is_baking():
		_pending = true
		return
	bake_navigation_mesh() # se calcula en otro hilo para no congelar el juego


func _on_bake_finished() -> void:
	if _pending:
		_pending = false
		rebake()
		return
	# El servidor de navegación aplica la malla nueva en el siguiente frame de física.
	await get_tree().physics_frame
	is_ready = true
