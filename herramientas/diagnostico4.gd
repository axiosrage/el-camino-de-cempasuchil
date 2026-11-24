extends Node

const NIVEL = preload("res://escenas/Nivel1.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EstadoJuego.reiniciar_estado()
	EstadoJuego.slot_activo = 0

	var nivel = NIVEL.instantiate()
	add_child(nivel)
	await get_tree().process_frame
	await get_tree().physics_frame

	var player = nivel.get_node("%Player")
	var hud = nivel.get_node("%HUD")
	var flor = nivel.get("_flor_final")
	var portal = nivel.get("_portal_final")

	print("portal activo inicial=", portal.get("activo"))

	player.global_position = portal.global_position
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("mensaje portal sellado visible=", hud.get("mensaje").visible, " texto=", hud.get("mensaje_texto").text)

	player.global_position = flor.global_position
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	print("flor recogida=", EstadoJuego.flor_recogida, " portal activo=", portal.get("activo"))
	print("mensaje flor visible=", hud.get("mensaje").visible, " texto=", hud.get("mensaje_texto").text)

	player.global_position = portal.global_position
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(1.6).timeout

	print("terminando=", nivel.get("_terminando"), " pausado=", get_tree().paused)
	var final = nivel.get("_final_nivel")
	print("final=", final)
	if final != null:
		print("final process_mode=", final.process_mode)
		var boton: Button = final.get_node("Centro/Contenido/Boton")
		print("boton texto=", boton.text, " foco=", boton.has_focus())

	get_tree().paused = false
	nivel.queue_free()
	await get_tree().process_frame
	get_tree().quit()
