extends CharacterBody2D

@export var VELOCIDAD = 50.0
@export var SALTO = -290
@export var duracion_desarme: float = 5.0
@onready var animaciones: AnimatedSprite2D = $AnimatedSprite2D
@onready var zona_dano: Area2D = $zonaDano
@onready var timer_rearme: Timer = $TiempoRearme

@onready var ray_cast: RayCast2D = $RayCast2D
@onready var pasos: AudioStreamPlayer2D = $Pasos
@onready var timer_pasos: Timer = $TimerPasos
@onready var default_ray_x: float = abs(ray_cast.position.x)
@onready var area_vision: CollisionShape2D = $AreaVision/CollisionShape2D
@onready var default_area_vision_x: float = abs(area_vision.position.x)

var en_rango = false
var player: CharacterBody2D = null
var desarmado: bool = false
var rearmando: bool = false


func _ready() -> void:
	timer_pasos.timeout.connect(_on_timer_pasos_timeout)


func _physics_process(delta: float) -> void:
	
	if desarmado:
		velocity.x = 0
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		_detener_pasos()
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if player:
			
			var direccion = global_position.direction_to(player.global_position)
			_voltear(direccion)
			if ray_cast.is_colliding():
				velocity = direccion * VELOCIDAD
				
				
			
			else:
				
				velocity.x = 0
		else:
			velocity.x = move_toward(velocity.x, 0, VELOCIDAD)
			

		
	if velocity.x != 0:
		animaciones.play("caminar")
		
		
	else:
		animaciones.play("idle")
		
	move_and_slide()
	_actualizar_pasos()

	if zona_dano:
		for body in zona_dano.get_overlapping_bodies():
			if body is Player:
				body.recibir_dano(0.5, "esqueleto")
	
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	player = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		
func _voltear(direccion):
	if direccion.max_axis_index() == 0:
		animaciones.flip_h = false
		ray_cast.position.x = default_ray_x
		area_vision.position.x = default_area_vision_x
	else:
		animaciones.flip_h = true
		ray_cast.position.x = -default_ray_x
		area_vision.position.x = -default_area_vision_x


func _on_zona_golpe_body_entered(body: Node2D) -> void:
	if body.has_method("eliminar"):
		body.eliminar()
	else:
		body.queue_free()

	if desarmado:
		return

	_desarmar()


func _desarmar() -> void:
	desarmado = true
	rearmando = false
	velocity.x = 0
	_detener_pasos()
	Sonidos.reproducir_mundo("enemigo_desarmado", global_position, -4.0)
	zona_dano.set_deferred("monitoring", false)
	animaciones.play("muerte")
	timer_rearme.start(duracion_desarme)


func _actualizar_pasos() -> void:
	var caminando := is_on_floor() and absf(velocity.x) > 1.0
	if caminando:
		if timer_pasos.is_stopped():
			_sonar_paso()
			timer_pasos.start()
	else:
		_detener_pasos()


func _on_timer_pasos_timeout() -> void:
	if not desarmado and is_on_floor() and absf(velocity.x) > 1.0:
		_sonar_paso()
	else:
		_detener_pasos()


func _sonar_paso() -> void:
	pasos.stop()
	pasos.play()


func _detener_pasos() -> void:
	if not timer_pasos.is_stopped():
		timer_pasos.stop()
	if pasos.playing:
		pasos.stop()


func _on_tiempo_rearme_timeout() -> void:
	# El rearme es la misma animación de desarme, pero hacia atrás.
	rearmando = true
	animaciones.play_backwards("muerte")
	await animaciones.animation_finished

	# Hasta que termina de armarse no puede moverse ni hacer daño.
	rearmando = false
	desarmado = false
	zona_dano.set_deferred("monitoring", true)
	animaciones.play("idle")
