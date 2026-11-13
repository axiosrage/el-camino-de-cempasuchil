extends CharacterBody2D

@export var VELOCIDAD = 50.0
@export var VELOCIDAD_ATAQUE = 90.0
@export var VELOCIDAD_CANSADO = 20.0 
@export var SALTO = -290
@onready var animaciones: AnimatedSprite2D = $AnimatedSprite2D
@onready var zona_ataque: Area2D = $zonaAtaque

var atacar = false
var cansado = false 

func _ready() -> void:
	animaciones.animation_finished.connect(_on_animacion_terminada)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
	
		if atacar:
			velocity.x = VELOCIDAD_ATAQUE
		elif cansado:
			velocity.x = VELOCIDAD_CANSADO
		else:
			velocity.x = VELOCIDAD

	# Control de animaciones
	if atacar:
		animaciones.play("ataque")
	else:
		animaciones.play("nadando")

	move_and_slide()

func _on_zona_ataque_body_entered(body: Node2D) -> void:
	
	if atacar or cansado:
		return

	if body is Player:
		body.recibir_dano(1.0, "lagarto")

	print("¡Atacando al jugador!")
	atacar = true
	

func _on_animacion_terminada() -> void:

	if animaciones.animation == "ataque":
		atacar = false
		cansado = true 
		print("Terminó de atacar. CANSADO (velocidad baja).")
		
		await get_tree().create_timer(5.0).timeout
		
		cansado = false
		print("Recuperó velocidad normal. Reactivando zona de ataque.")
		
