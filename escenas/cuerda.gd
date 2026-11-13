extends RigidBody2D

@onready var contenedor_cuerda: Node2D = $".."
@onready var luz: PointLight2D = $PointLight2D

var puede_cortarse = false
var cortada = false


	
func _on_timer_timeout() -> void:
	#linear_velocity.x = 20
	pass 
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	romper_cuerda()
	

func romper_cuerda() -> void:
	cortada = true
	puede_cortarse = false
	var mi_indice = get_index()
	var indice_pin = mi_indice - 1
	
	luz.enabled = false
	if indice_pin >= 0:
		
		var joint = contenedor_cuerda.get_child(indice_pin)
		if joint is PinJoint2D:
			joint.queue_free()
		
