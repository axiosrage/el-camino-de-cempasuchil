extends CharacterBody2D

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var velocidad = 180.0

func _ready() -> void:
	velocity.y = -400
	
func _physics_process(delta: float) -> void:
	
	if !is_on_floor():
		velocity.x = velocidad 
		
		velocity.y += gravity * delta
	if is_on_floor():
		velocity.x = 0
		queue_free()
	
	move_and_slide()
	
func inicializar(nueva_vel: float) -> void:
	velocidad = nueva_vel
	
func eliminar() -> void:
	queue_free()
