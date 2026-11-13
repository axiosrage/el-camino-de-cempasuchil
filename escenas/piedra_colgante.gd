extends RigidBody2D

var congelado = false

func _process(delta: float) -> void:
	if congelado:
		congelar()

func _on_area_2d_body_entered(body: Node2D) -> void:
	congelado = true
	
func congelar():
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0


func _on_timer_timeout() -> void:
	linear_velocity.x = 30
