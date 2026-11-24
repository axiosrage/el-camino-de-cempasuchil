extends Node

## Prueba de la intro: Espacio, Enter y A avanzan de panel; B salta la intro.
## Uso: godot --headless --path . pruebas/intro_test.tscn

const INTRO = preload("res://escenas/intro.tscn")

var _fallos: Array[String] = []
var _intro
var _intro_terminada: bool = false


func _ready() -> void:
	await get_tree().process_frame
	get_viewport().size = Vector2i(1152, 648)

	_intro = INTRO.instantiate()
	_intro.intro_terminada.connect(_on_intro_terminada)
	add_child(_intro)
	await get_tree().create_timer(0.75).timeout

	_comprobar(not _intro._bloqueado, "la intro termina su fundido de entrada")
	_comprobar(_intro._indice == 0, "empieza en el panel 1")
	_comprobar(_intro.PANELES.size() == 24, "la intro usa las 24 viñetas nuevas")
	var ruta_primera: String = _intro.PANELES[0]["imagen"].resource_path
	var ruta_ultima: String = _intro.PANELES[23]["imagen"].resource_path
	_comprobar(
		ruta_primera.begins_with("res://assets/intro/Historia_Mictlán/") and ruta_primera.ends_with("viñeta1.png"),
		"la primera viñeta viene de Historia_Mictlán"
	)
	_comprobar(ruta_ultima.ends_with("viñeta24.png"), "la última viñeta es la 24")
	_comprobar(
		_intro.panel_imagen.texture.resource_path == ruta_primera,
		"el panel 1 muestra la viñeta 1"
	)
	_comprobar(
		_intro.boton_saltar.focus_mode == Control.FOCUS_NONE,
		"el botón SALTAR INTRO no captura Espacio/A"
	)
	_comprobar(
		_intro.boton_siguiente.focus_mode == Control.FOCUS_NONE,
		"el botón SIGUIENTE no captura Espacio/A"
	)
	_comprobar(
		_intro.zona_toque != null,
		" existe la zona táctil sobre la viñeta"
	)

	await _pulsar_tecla(KEY_SPACE)
	await get_tree().create_timer(0.3).timeout
	_comprobar(_intro._indice == 1, "ESPACIO pasa al panel 2")
	_comprobar(
		_intro.contador.text.begins_with("PANEL 2 /"),
		"el contador se actualiza al avanzar"
	)

	await _pulsar_boton(JOY_BUTTON_A)
	await get_tree().create_timer(0.3).timeout
	_comprobar(_intro._indice == 2, "A pasa al panel 3")

	await _pulsar_tecla(KEY_ENTER)
	await get_tree().create_timer(0.3).timeout
	_comprobar(_intro._indice == 3, "ENTER pasa al panel 4")
	_comprobar(not _intro._saliendo, "la intro sigue activa tras avanzar")

	_intro.boton_siguiente.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	_comprobar(_intro._indice == 4, "el botón táctil pasa al panel 5")

	var toque := InputEventScreenTouch.new()
	toque.index = 0
	toque.position = Vector2(400, 200)
	toque.pressed = true
	_intro._on_zona_toque(toque)
	await get_tree().create_timer(0.3).timeout
	_comprobar(_intro._indice == 5, "tocar la viñeta pasa al panel 6")

	await _pulsar_boton(JOY_BUTTON_B)
	await get_tree().process_frame
	await get_tree().process_frame
	_comprobar(_intro_terminada, "B salta la intro completa")
	_comprobar(_intro._saliendo, "la intro queda cerrada")

	if _fallos.is_empty():
		print("PRUEBA INTRO OK")
	else:
		print("PRUEBA INTRO FALLIDA: %s" % [_fallos])
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _on_intro_terminada() -> void:
	_intro_terminada = true


func _pulsar_tecla(codigo: Key) -> void:
	_enviar_tecla(codigo, true)
	await get_tree().process_frame
	_enviar_tecla(codigo, false)
	await get_tree().process_frame


func _pulsar_boton(boton: JoyButton) -> void:
	_enviar_boton(boton, true)
	await get_tree().process_frame
	_enviar_boton(boton, false)
	await get_tree().process_frame


func _enviar_tecla(codigo: Key, presionada: bool) -> void:
	var evento := InputEventKey.new()
	evento.keycode = codigo
	evento.physical_keycode = codigo
	evento.pressed = presionada
	Input.parse_input_event(evento)


func _enviar_boton(boton: JoyButton, presionado: bool) -> void:
	var evento := InputEventJoypadButton.new()
	evento.device = -1
	evento.button_index = boton
	evento.pressed = presionado
	Input.parse_input_event(evento)


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		print("  OK: ", descripcion)
	else:
		_fallos.append(descripcion)
		print("  FALLO: ", descripcion)
