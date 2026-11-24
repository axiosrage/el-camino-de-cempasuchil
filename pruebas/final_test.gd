extends Node

## Prueba del final: portal sellado, recogida de la flor, activación del
## portal, fundido y pantalla final con el botón de volver al menú.
## Uso: godot --headless --path . pruebas/final_test.tscn

const NIVEL = preload("res://escenas/Nivel1.tscn")

var _fallos: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	EstadoJuego.reiniciar_estado()
	EstadoJuego.slot_activo = 0

	var nivel = NIVEL.instantiate()
	add_child(nivel)
	await get_tree().process_frame
	await get_tree().physics_frame

	var flor = nivel.get("_flor_final")
	var portal = nivel.get("_portal_final")
	_comprobar(flor != null, "la flor final existe")
	_comprobar(portal != null, "el portal final existe")
	if flor == null or portal == null:
		await _terminar(nivel)
		return

	_comprobar(not bool(portal.get("activo")), "el portal empieza sellado")
	_comprobar(flor.global_position.x < portal.global_position.x, "la flor está antes del portal")
	_comprobar(portal.global_position.x > 13_000.0, "el portal está al final del mapa")

	var area_flor = flor.get_node("Area2D/CollisionShape2D")
	var area_portal = portal.get_node("Area2D/CollisionShape2D")
	_comprobar(
		area_flor.position.y + (area_flor.shape as CircleShape2D).radius >= 0.0,
		"el área de la flor alcanza al jugador en el suelo"
	)
	_comprobar(
		area_portal.position.y + (area_portal.shape as CircleShape2D).radius >= 0.0,
		"el área del portal alcanza al jugador en el suelo"
	)
	var sprite_flor: Sprite2D = flor.get_node("Flor")
	_comprobar(
		sprite_flor.texture.get_width() * sprite_flor.scale.x <= 40.0,
		"la flor tiene un tamaño proporcionado"
	)
	_comprobar(Musica.pista_actual() == "juego", "el nivel reproduce la música de juego")

	var player = nivel.get_node("%Player")
	var hud = nivel.get_node("%HUD")

	# Portal sellado: debe avisar y no terminar el nivel.
	player.global_position = portal.global_position
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	_comprobar(hud.get("mensaje").visible, "aparece el aviso de portal sellado")
	_comprobar("SELLADO" in hud.get("mensaje_texto").text, "el aviso explica que está sellado")
	_comprobar(not bool(nivel.get("_terminando")), "el nivel no termina con el portal sellado")

	# Recoger la flor.
	player.global_position = flor.global_position
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	_comprobar(EstadoJuego.flor_recogida, "la flor queda registrada en EstadoJuego")
	_comprobar(bool(portal.get("activo")), "la flor activa el portal")
	_comprobar("FLOR" in hud.get("mensaje_texto").text, "el HUD anuncia la flor recogida")

	# Entrar al portal: primero aparece el panel de la intro.
	player.global_position = portal.global_position
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(1.2).timeout

	_comprobar(bool(nivel.get("_terminando")), "el nivel queda marcado como terminado")
	var final = nivel.get("_final_nivel")
	_comprobar(final != null, "se crea la pantalla final")
	if final == null:
		await _terminar(nivel)
		return

	_comprobar(final.process_mode == Node.PROCESS_MODE_ALWAYS, "la pantalla final procesa en pausa")
	var panel_demo: TextureRect = final.get_node_or_null("PanelDemo")
	_comprobar(panel_demo != null and panel_demo.visible, "aparece el panel finalDemo al entrar al portal")
	if panel_demo != null and panel_demo.texture != null:
		_comprobar(
			panel_demo.texture.resource_path.contains("finalDemo"),
			"el panel mostrado es finalDemo.png de la intro"
		)

	# Se avanza el panel con A y entonces aparece el mensaje de siempre.
	var pulsar := InputEventAction.new()
	pulsar.action = "ui_accept"
	pulsar.pressed = true
	Input.parse_input_event(pulsar)
	var soltar := InputEventAction.new()
	soltar.action = "ui_accept"
	soltar.pressed = false
	Input.parse_input_event(soltar)
	await get_tree().create_timer(1.6).timeout

	_comprobar(panel_demo == null or not panel_demo.visible, "el panel deja paso al mensaje final")
	var boton: Button = final.get_node("Centro/Contenido/Boton")
	_comprobar(boton.text.contains("VOLVER AL MENÚ"), "el botón vuelve al menú")
	_comprobar(boton.has_focus(), "el botón final recibe el foco")
	_comprobar(get_tree().paused, "el árbol queda pausado en el final")

	await _terminar(nivel)


func _terminar(nivel) -> void:
	get_tree().paused = false
	if nivel != null:
		nivel.queue_free()
		await get_tree().process_frame
	EstadoJuego.reiniciar_estado()

	if _fallos.is_empty():
		print("PRUEBA FINAL OK")
	else:
		print("PRUEBA FINAL FALLIDA: %s" % [_fallos])
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK: ", mensaje)
	else:
		_fallos.append(mensaje)
