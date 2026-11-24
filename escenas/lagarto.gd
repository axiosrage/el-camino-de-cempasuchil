extends CharacterBody2D

@export var VELOCIDAD = 50.0
@export var VELOCIDAD_ATAQUE = 90.0
@export var VELOCIDAD_CANSADO = 20.0 
@export var SALTO = -290
@export var VELOCIDAD_HUNDIR = 35.0
@export var TIEMPO_HUNDIR = 1.2

@onready var animaciones: AnimatedSprite2D = $AnimatedSprite2D
@onready var zona_ataque: Area2D = $zonaAtaque

var atacar = false
var cansado = false
var hundiendo = false

func _ready() -> void:
	animaciones.animation_finished.connect(_on_animacion_terminada)

func _physics_process(delta: float) -> void:
	if hundiendo:
		# Frena el avance horizontal y desciende suavemente
		velocity.x = move_toward(velocity.x, 0.0, VELOCIDAD * delta * 2.0)
		velocity.y = VELOCIDAD_HUNDIR
		animaciones.play("nadando")
		animaciones.speed_scale = 0.5
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if atacar:
			velocity.x = VELOCIDAD_ATAQUE
		elif cansado:
			velocity.x = VELOCIDAD_CANSADO
		else:
			velocity.x = VELOCIDAD

	if atacar:
		animaciones.play("ataque")
	else:
		animaciones.play("nadando")

	move_and_slide()

func hundirse() -> void:
	if hundiendo:
		return

	hundiendo = true
	atacar = false

	# Desactiva la zona de ataque para no dañar al jugador mientras se hunde
	zona_ataque.set_deferred("monitoring", false)
	zona_ataque.set_deferred("monitorable", false)

	# Desactiva colisiones físicas para que atraviese el suelo hacia abajo
	collision_layer = 0
	collision_mask = 0

	# Desvanece el sprite y elimina el nodo al finalizar
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, TIEMPO_HUNDIR)
	await tween.finished
	queue_free()

func _on_zona_ataque_body_entered(body: Node2D) -> void:
	if atacar or cansado or hundiendo:
		return

	if body is Player:
		atacar = true

func _on_animacion_terminada() -> void:
	if hundiendo:
		return

	if animaciones.animation == "ataque":
		for body in zona_ataque.get_overlapping_bodies():
			if body is Player:
				body.recibir_dano(1.0, "lagarto")

		atacar = false
		cansado = true
		
		await get_tree().create_timer(5.0).timeout
		if hundiendo:
			return
		
		cansado = false
		
		for body in zona_ataque.get_overlapping_bodies():
			if body is Player:
				atacar = true
				break
