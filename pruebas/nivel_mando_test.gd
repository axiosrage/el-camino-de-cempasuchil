extends Node

## Prueba de integración: el jugador real responde a eventos de mando.
## Uso: godot --headless --path . pruebas/nivel_mando_test.tscn

const NIVEL = preload("res://escenas/Nivel1.tscn")

var _fallos: Array[String] = []
var _nivel: Node2D
var _player


func _ready() -> void:
	await get_tree().process_frame
	get_viewport().size = Vector2i(1152, 648)
	await get_tree().process_frame

	# La prueba no debe alterar la configuración persistente del jugador.
	var camara_original := Configuracion.pausa_camara
	var foco_original := Configuracion.pausa_foco
	Configuracion.pausa_camara = false
	Configuracion.pausa_foco = false

	_nivel = NIVEL.instantiate()
	add_child(_nivel)
	await get_tree().process_frame
	_player = _nivel.get_node("%Player")
	_comprobar(_player != null, "jugador instanciado")

	var inicio := Time.get_ticks_msec()
	while not _player.is_on_floor() and Time.get_ticks_msec() - inicio < 4000:
		await get_tree().physics_frame
	_comprobar(_player.is_on_floor(), "jugador en el suelo")

	# El salto se prueba antes de moverse: el jugador empieza sobre una
	# cornisa estrecha y, al avanzar a la derecha, cae al agua.
	# Se deja asentar la máquina de estados y se espera al impulso real,
	# porque is_action_just_pressed solo vale durante un frame físico.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_enviar_boton(JOY_BUTTON_A, false)
	await get_tree().process_frame
	var y_antes: float = _player.velocity.y
	_enviar_boton(JOY_BUTTON_A, true)
	var salto_iniciado := false
	var limite_salto := Time.get_ticks_msec() + 1500
	while not salto_iniciado and Time.get_ticks_msec() < limite_salto:
		await get_tree().physics_frame
		salto_iniciado = _player.velocity.y < y_antes
	_comprobar(salto_iniciado, "A inicia el salto (vy=%.1f)" % _player.velocity.y)
	_enviar_boton(JOY_BUTTON_A, false)
	await get_tree().process_frame

	inicio = Time.get_ticks_msec()
	while not _player.is_on_floor() and Time.get_ticks_msec() - inicio < 4000:
		await get_tree().physics_frame
	_comprobar(_player.is_on_floor(), "jugador vuelve al suelo tras el salto")

	# El stick se prueba primero y hacia la izquierda: justo a la derecha de la
	# aparición hay un charco, así que conviene medir antes de acercarse a él.
	var x_inicial: float = _player.global_position.x
	_enviar_eje(JOY_AXIS_LEFT_X, -1.0)
	await get_tree().create_timer(0.25).timeout
	_enviar_eje(JOY_AXIS_LEFT_X, 0.0)
	await get_tree().physics_frame
	_comprobar(
		_player.global_position.x < x_inicial - 2.0,
		"el stick mueve al jugador (%.1f -> %.1f)" % [x_inicial, _player.global_position.x]
	)

	var x_tras_stick: float = _player.global_position.x
	_enviar_boton(JOY_BUTTON_DPAD_RIGHT, true)
	await get_tree().create_timer(0.5).timeout
	_enviar_boton(JOY_BUTTON_DPAD_RIGHT, false)
	await get_tree().physics_frame
	_comprobar(
		_player.global_position.x > x_tras_stick + 4.0,
		"el D-pad mueve al jugador (%.1f -> %.1f)" % [x_tras_stick, _player.global_position.x]
	)

	_enviar_boton(JOY_BUTTON_START, true)
	await get_tree().process_frame
	_enviar_boton(JOY_BUTTON_START, false)
	await get_tree().process_frame
	_comprobar(get_tree().paused, "Start pausa el nivel real")
	_enviar_boton(JOY_BUTTON_START, true)
	await get_tree().process_frame
	_enviar_boton(JOY_BUTTON_START, false)
	await get_tree().process_frame
	_comprobar(not get_tree().paused, "Start reanuda el nivel real")

	if _fallos.is_empty():
		print("PRUEBA NIVEL MANDO OK")
	else:
		print("PRUEBA NIVEL MANDO FALLIDA: %s" % [_fallos])
	Configuracion.pausa_camara = camara_original
	Configuracion.pausa_foco = foco_original
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _enviar_boton(boton: JoyButton, presionado: bool) -> void:
	var evento := InputEventJoypadButton.new()
	evento.device = -1
	evento.button_index = boton
	evento.pressed = presionado
	Input.parse_input_event(evento)


func _enviar_eje(eje: JoyAxis, valor: float) -> void:
	var evento := InputEventJoypadMotion.new()
	evento.device = -1
	evento.axis = eje
	evento.axis_value = valor
	Input.parse_input_event(evento)


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		print("  OK: ", descripcion)
	else:
		_fallos.append(descripcion)
		print("  FALLO: ", descripcion)
