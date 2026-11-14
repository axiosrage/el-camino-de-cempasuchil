extends RigidBody2D

@export var velocidad: float = 120.0
@export var impulso_vertical: float = -360.0
@export var duracion: float = 1.5

var recta_activa: bool = false

var _golpe_sonado: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_programar_desvanecido()


func _on_body_entered(_body: Node) -> void:
	if not _golpe_sonado:
		_golpe_sonado = true
		Sonidos.reproducir_mundo("golpe_piedra", global_position, -3.0, 900.0)

	# El tiro recto solo ignora la gravedad hasta el primer impacto.
	# Al chocar con una pared vuelve a caer con física normal.
	if recta_activa:
		recta_activa = false
		gravity_scale = 1.0


func _programar_desvanecido() -> void:
	var tween := create_tween()
	tween.tween_interval(maxf(duracion - 0.3, 0.1))
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.3)
	tween.tween_callback(queue_free)


func inicializar(nueva_vel: float, direccion: float = 1.0, nueva_altura: float = -360.0) -> void:
	velocidad = absf(nueva_vel)
	impulso_vertical = nueva_altura
	recta_activa = false
	gravity_scale = 1.0
	linear_velocity = Vector2(direccion * velocidad, impulso_vertical)
	angular_velocity = direccion * randf_range(9.0, 14.0)


func inicializar_recta(nueva_vel: float, direccion: float = 1.0) -> void:
	velocidad = absf(nueva_vel)
	recta_activa = true
	gravity_scale = 0.0
	linear_velocity = Vector2(direccion * velocidad, 0.0)
	angular_velocity = direccion * randf_range(9.0, 14.0)


func eliminar() -> void:
	queue_free()
