extends CharacterBody2D

@export var VELOCIDAD = 130.0
@export var VELOCIDAD_SALIDA = 250.0 # Velocidad con la que se adelanta al irse
@export var SALTO = -350
@export var IMPULSO_PICO = 200.0
@export var IMPULSO_DURACION = 0.45
@export var DISTANCIA_MINIMA = 15.0 # Evita que vibre al quedar justo encima del jugador
@export var MARGEN_BORDE = 20.0 # Qué tan adelante detecta el vacío antes de saltar

@onready var animaciones: AnimatedSprite2D = $AnimatedSprite2D
@onready var detector_borde: RayCast2D = get_node_or_null("DetectorBorde")
@onready var notificador_pantalla: VisibleOnScreenNotifier2D = get_node_or_null("VisibleOnScreenNotifier2D")

var activo = false
var en_rango = false
var yendose = false
var direccion_salida: float = 1.0
var player: CharacterBody2D = null
var tiempo_impulso: float = 0.0


func _ready() -> void:
	if is_instance_valid(notificador_pantalla):
		notificador_pantalla.screen_exited.connect(_on_pantalla_salida)


func _physics_process(delta: float) -> void:
	# El impulso es una campana suave: acelera y desacelera sin saltos.
	if tiempo_impulso > 0.0:
		tiempo_impulso = maxf(tiempo_impulso - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if yendose:
		# Se adelanta en línea recta sin comprobar paredes ni bordes para no saltar
		velocity.x = VELOCIDAD_SALIDA * direccion_salida
		_voltear(direccion_salida)
		_comprobar_fuera_de_pantalla()
	elif activo and is_instance_valid(player):
		var distancia_x: float = player.global_position.x - global_position.x
		if absf(distancia_x) > DISTANCIA_MINIMA:
			var direccion_x: float = signf(distancia_x)
			velocity.x = _velocidad_actual() * direccion_x
			_voltear(direccion_x)

			var hay_pared := is_on_wall() and signf(get_wall_normal().x) == -direccion_x
			var hay_borde := false

			if is_instance_valid(detector_borde):
				detector_borde.position.x = MARGEN_BORDE * direccion_x
				detector_borde.force_raycast_update()
				hay_borde = not detector_borde.is_colliding()

			if is_on_floor() and (hay_pared or hay_borde):
				velocity.y = SALTO
		else:
			velocity.x = 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, VELOCIDAD)

	move_and_slide()
	_actualizar_animacion()


func _velocidad_actual() -> float:
	if tiempo_impulso <= 0.0:
		return VELOCIDAD
	var progreso: float = 1.0 - tiempo_impulso / IMPULSO_DURACION
	return lerpf(VELOCIDAD, IMPULSO_PICO, sin(PI * progreso))


func _actualizar_animacion() -> void:
	if not is_on_floor():
		animaciones.play("saltar")
		animaciones.speed_scale = 1.0
	elif absf(velocity.x) > 1.0:
		animaciones.play("caminar")
		# La animación acelera un poco durante el impulso para acompañar el avance.
		var exceso := clampf(
			(absf(velocity.x) - VELOCIDAD) / maxf(IMPULSO_PICO - VELOCIDAD, 1.0),
			0.0,
			1.0
		)
		animaciones.speed_scale = lerpf(1.0, 1.5, exceso)
	else:
		animaciones.play("idle")
		animaciones.speed_scale = 1.0


func impulsar() -> void:
	if not activo or yendose:
		return
	# Ignora pulsaciones mientras el impulso anterior sigue en curso.
	if tiempo_impulso > 0.0:
		return
	tiempo_impulso = IMPULSO_DURACION


func _voltear(direccion_x: float) -> void:
	if direccion_x != 0.0:
		# Si tu sprite base mira hacia la izquierda, cambia < por >
		animaciones.flip_h = direccion_x < 0.0


func _comprobar_fuera_de_pantalla() -> void:
	# Si ya tienes el nodo VisibleOnScreenNotifier2D, él se encarga con su señal
	if is_instance_valid(notificador_pantalla):
		return
	# Respaldo automático usando los límites de la cámara actual
	var pos_pantalla: Vector2 = get_viewport().get_canvas_transform() * global_position
	var ancho_pantalla: float = get_viewport_rect().size.x
	if pos_pantalla.x < -50.0 or pos_pantalla.x > ancho_pantalla + 50.0:
		queue_free()


func _on_pantalla_salida() -> void:
	if yendose:
		queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if yendose:
		return
	player = body
	en_rango = true
	activo = true


func _on_desaparecer_perro_body_entered(body: Node2D) -> void:
	# Funciona tanto si el Area2D detecta al propio perro como si detecta al jugador
	if body == self or body == player:
		if absf(velocity.x) > 0.1:
			direccion_salida = signf(velocity.x)
		else:
			direccion_salida = -1.0 if animaciones.flip_h else 1.0

		yendose = true
		activo = false
		tiempo_impulso = 0.0
