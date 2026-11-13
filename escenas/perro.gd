extends CharacterBody2D

@export var VELOCIDAD = 30.0
@export var SALTO = -290
@export var IMPULSO_PICO = 100.0
@export var IMPULSO_DURACION = 0.45
@onready var animaciones: AnimatedSprite2D = $AnimatedSprite2D
var activo = false
var en_rango = false
var player: CharacterBody2D = null
var tiempo_impulso: float = 0.0

func _physics_process(delta: float) -> void:
	
	# El impulso es una campana suave: acelera y desacelera sin saltos.
	if tiempo_impulso > 0.0:
		tiempo_impulso = maxf(tiempo_impulso - delta, 0.0)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif activo == true:
		velocity.x = _velocidad_actual()
	
	_actualizar_animacion()
	move_and_slide()


func _velocidad_actual() -> float:
	if tiempo_impulso <= 0.0:
		return VELOCIDAD
	var progreso: float = 1.0 - tiempo_impulso / IMPULSO_DURACION
	return lerpf(VELOCIDAD, IMPULSO_PICO, sin(PI * progreso))


func _actualizar_animacion() -> void:
	animaciones.play("nadando")
	# La animación acelera un poco durante el impulso para acompañar el avance.
	var exceso := clampf(
		(absf(velocity.x) - VELOCIDAD) / maxf(IMPULSO_PICO - VELOCIDAD, 1.0),
		0.0,
		1.0
	)
	animaciones.speed_scale = lerpf(1.0, 1.5, exceso)


func impulsar() -> void:
	if not activo:
		return
	# Ignora pulsaciones mientras el impulso anterior sigue en curso.
	if tiempo_impulso > 0.0:
		return
	tiempo_impulso = IMPULSO_DURACION

func _voltear(direccion):
	if direccion.max_axis_index() == 0:
		animaciones.flip_h = false
	else:
		animaciones.flip_h = true


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("hola")
	activo = true
