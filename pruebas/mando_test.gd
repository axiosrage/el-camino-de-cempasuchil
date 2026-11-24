extends Control

## Prueba del soporte de mando: mapa de entrada, navegación de menús
## y pausa con Start/B.
## Uso: godot --headless --path . pruebas/mando_test.tscn

const PAUSA = preload("res://escenas/pausa.tscn")

var _fallos: Array[String] = []
var _pausa: CanvasLayer
var _boton_uno: Button
var _boton_dos: Button
var _caja: VBoxContainer
var _activado := false


func _ready() -> void:
	await get_tree().process_frame
	get_viewport().size = Vector2i(1152, 648)
	await get_tree().process_frame

	_comprobar_mapa()
	await _probar_ejes_y_botones()
	_probar_foco()
	await _probar_pausa()

	if _fallos.is_empty():
		print("PRUEBA MANDO OK")
	else:
		print("PRUEBA MANDO FALLIDA: %s" % [_fallos])
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _comprobar_mapa() -> void:
	_comprobar(_tiene_boton("salto", JOY_BUTTON_A), "A salta")
	_comprobar(_tiene_boton("lanzar", JOY_BUTTON_X), "X lanza")
	_comprobar(_tiene_boton("pausa", JOY_BUTTON_START), "Start pausa")
	_comprobar(_tiene_boton("ui_accept", JOY_BUTTON_A), "A acepta en menús")
	_comprobar(_tiene_boton("ui_cancel", JOY_BUTTON_B), "B cancela en menús")
	_comprobar(_tiene_eje("mov_izquierda", JOY_AXIS_LEFT_X, -1.0), "stick izquierda")
	_comprobar(_tiene_eje("mov_derecha", JOY_AXIS_LEFT_X, 1.0), "stick derecha")
	_comprobar(_tiene_boton("mov_izquierda", JOY_BUTTON_DPAD_LEFT), "D-pad izquierda")
	_comprobar(_tiene_boton("mov_derecha", JOY_BUTTON_DPAD_RIGHT), "D-pad derecha")


func _probar_ejes_y_botones() -> void:
	_enviar_eje(JOY_AXIS_LEFT_X, -1.0)
	await get_tree().process_frame
	_comprobar(Input.get_axis("mov_izquierda", "mov_derecha") < -0.9, "eje izquierdo mueve")
	_enviar_eje(JOY_AXIS_LEFT_X, 1.0)
	await get_tree().process_frame
	_comprobar(Input.get_axis("mov_izquierda", "mov_derecha") > 0.9, "eje derecho mueve")
	_enviar_eje(JOY_AXIS_LEFT_X, 0.0)
	await get_tree().process_frame
	_comprobar(is_zero_approx(Input.get_axis("mov_izquierda", "mov_derecha")), "eje centrado se detiene")

	_enviar_boton(JOY_BUTTON_DPAD_LEFT, true)
	await get_tree().process_frame
	_comprobar(Input.is_action_pressed("mov_izquierda"), "D-pad izquierda mueve")
	_enviar_boton(JOY_BUTTON_DPAD_LEFT, false)
	await get_tree().process_frame
	_comprobar(not Input.is_action_pressed("mov_izquierda"), "D-pad izquierda se suelta")

	_enviar_boton(JOY_BUTTON_A, true)
	await get_tree().process_frame
	_comprobar(Input.is_action_pressed("salto"), "A pulsado")
	_enviar_boton(JOY_BUTTON_A, false)
	await get_tree().process_frame
	_comprobar(not Input.is_action_pressed("salto"), "A liberado")

	_enviar_boton(JOY_BUTTON_X, true)
	await get_tree().process_frame
	_comprobar(Input.is_action_pressed("lanzar"), "X pulsado")
	_enviar_boton(JOY_BUTTON_X, false)
	await get_tree().process_frame
	_comprobar(not Input.is_action_pressed("lanzar"), "X liberado")


func _probar_foco() -> void:
	_caja = VBoxContainer.new()
	_caja.position = Vector2(100, 100)
	_caja.size = Vector2(300, 160)
	add_child(_caja)
	_boton_uno = Button.new()
	_boton_uno.text = "UNO"
	_boton_uno.custom_minimum_size = Vector2(220, 50)
	_caja.add_child(_boton_uno)
	_boton_dos = Button.new()
	_boton_dos.text = "DOS"
	_boton_dos.custom_minimum_size = Vector2(220, 50)
	_caja.add_child(_boton_dos)
	_boton_uno.focus_neighbor_bottom = _boton_uno.get_path_to(_boton_dos)
	_boton_dos.focus_neighbor_top = _boton_dos.get_path_to(_boton_uno)
	_boton_uno.pressed.connect(func() -> void: _activado = true)
	_boton_dos.pressed.connect(func() -> void: _activado = true)
	_boton_uno.grab_focus()
	_comprobar(_boton_uno.has_focus(), "foco inicial")


func _probar_pausa() -> void:
	# Navegación con D-pad y activación con A.
	_enviar_boton(JOY_BUTTON_DPAD_DOWN, true)
	await get_tree().process_frame
	_enviar_boton(JOY_BUTTON_DPAD_DOWN, false)
	await get_tree().process_frame
	_comprobar(_boton_dos.has_focus(), "D-pad baja el foco")
	_enviar_boton(JOY_BUTTON_A, true)
	await get_tree().process_frame
	_enviar_boton(JOY_BUTTON_A, false)
	await get_tree().process_frame
	_comprobar(_activado, "A activa el botón enfocado")

	# Quitamos la UI de prueba para no interferir con la pausa.
	if get_viewport().gui_get_focus_owner() != null:
		get_viewport().gui_get_focus_owner().release_focus()
	_caja.queue_free()
	await get_tree().process_frame

	# La pausa real, con Start y B. La prueba no debe alterar la
	# configuración persistente del jugador.
	var camara_original := Configuracion.pausa_camara
	Configuracion.pausa_camara = false
	_pausa = PAUSA.instantiate()
	add_child(_pausa)
	await get_tree().process_frame
	_comprobar(not _pausa.visible, "pausa empieza cerrada")

	_enviar_boton(JOY_BUTTON_START, true)
	await get_tree().process_frame
	_enviar_boton(JOY_BUTTON_START, false)
	await get_tree().process_frame
	_comprobar(_pausa.visible, "Start abre la pausa")
	_comprobar(get_tree().paused, "el árbol queda pausado")
	var reanudar: Button = _pausa.get_node("Centro/Panel/Margen/VBox/Reanudar")
	_comprobar(reanudar.has_focus(), "Reanudar recibe el foco")

	_enviar_boton(JOY_BUTTON_START, true)
	await get_tree().process_frame
	_enviar_boton(JOY_BUTTON_START, false)
	await get_tree().process_frame
	_comprobar(not _pausa.visible, "Start cierra la pausa")
	_comprobar(not get_tree().paused, "el árbol se reanuda")

	_enviar_boton(JOY_BUTTON_B, true)
	await get_tree().process_frame
	_enviar_boton(JOY_BUTTON_B, false)
	await get_tree().process_frame
	_comprobar(not _pausa.visible, "B no abre la pausa")

	_enviar_boton(JOY_BUTTON_START, true)
	await get_tree().process_frame
	_enviar_boton(JOY_BUTTON_START, false)
	await get_tree().process_frame
	_comprobar(_pausa.visible, "Start vuelve a abrir")
	_enviar_boton(JOY_BUTTON_B, true)
	await get_tree().process_frame
	_enviar_boton(JOY_BUTTON_B, false)
	await get_tree().process_frame
	_comprobar(not _pausa.visible, "B cierra la pausa")
	_comprobar(not get_tree().paused, "B reanuda el árbol")
	_comprobar(get_viewport().gui_get_focus_owner() == null, "sin foco tras reanudar")

	_enviar_boton(JOY_BUTTON_A, true)
	await get_tree().process_frame
	_comprobar(Input.is_action_pressed("salto"), "A salta tras reanudar")
	_enviar_boton(JOY_BUTTON_A, false)
	await get_tree().process_frame
	Configuracion.pausa_camara = camara_original


func _tiene_boton(accion: String, boton: JoyButton) -> bool:
	for evento in InputMap.action_get_events(accion):
		if evento is InputEventJoypadButton and evento.button_index == boton:
			return true
	return false


func _tiene_eje(accion: String, eje: JoyAxis, valor: float) -> bool:
	for evento in InputMap.action_get_events(accion):
		if evento is InputEventJoypadMotion \
				and evento.axis == eje \
				and is_equal_approx(evento.axis_value, valor):
			return true
	return false


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
