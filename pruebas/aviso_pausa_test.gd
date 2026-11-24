extends Node

## Prueba del aviso de pausa automática del menú principal.
## Uso: godot --headless --path . pruebas/aviso_pausa_test.tscn

const MENU = preload("res://escenas/menu.tscn")
const GUION_AVISO = preload("res://escenas/aviso_pausa.gd")
const BOTONES_MENU := ["Continuar", "NuevaPartida", "Opciones", "Salir"]

var _fallos: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	get_viewport().size = Vector2i(1152, 648)

	GUION_AVISO.reiniciar_para_prueba()

	var menu: Control = await _abrir_menu()
	var aviso = menu.get_node("AvisoPausa")
	var entendido: Button = aviso.entendido
	var ver_opciones: Button = aviso.ver_opciones

	_comprobar(aviso.visible, "el aviso aparece al abrir el menú")
	_comprobar(entendido.has_focus(), "el foco empieza en ENTENDIDO")
	_comprobar(_foco_atrapado(aviso), "el foco queda atrapado entre los botones del aviso")
	for nombre in BOTONES_MENU:
		var boton: TextureButton = menu.get_node("Botones/" + nombre)
		_comprobar(
			boton.focus_mode == Control.FOCUS_NONE,
			"%s no recibe foco mientras el aviso está abierto" % nombre
		)

	await _pulsar(JOY_BUTTON_DPAD_DOWN)
	_comprobar(ver_opciones.has_focus(), "el D-pad baja el foco a VER OPCIONES")
	await _pulsar(JOY_BUTTON_DPAD_DOWN)
	_comprobar(entendido.has_focus(), "el foco vuelve a ENTENDIDO sin salir del aviso")

	await _pulsar(JOY_BUTTON_A)
	_comprobar(not aviso.visible, "A / ENTER cierra el aviso")
	_comprobar(
		_es_boton_menu(menu, get_viewport().gui_get_focus_owner()),
		"el foco vuelve a un botón del menú"
	)

	menu.queue_free()
	await get_tree().process_frame

	# Segunda apertura del menú en la misma sesión simulada: el aviso debe
	# salir otra vez solo porque la prueba reinició la marca de sesión.
	GUION_AVISO.reiniciar_para_prueba()
	menu = await _abrir_menu()
	aviso = menu.get_node("AvisoPausa")
	ver_opciones = aviso.ver_opciones
	var opciones_panel = menu.get_node("Opciones")

	_comprobar(aviso.visible, "el aviso vuelve a aparecer en una sesión nueva")

	await _pulsar(JOY_BUTTON_DPAD_DOWN)
	_comprobar(ver_opciones.has_focus(), "VER OPCIONES recibe el foco con el D-pad")
	await _pulsar(JOY_BUTTON_A)
	_comprobar(not aviso.visible, "VER OPCIONES cierra el aviso")
	_comprobar(opciones_panel.visible, "VER OPCIONES abre el panel de Opciones")
	# Opciones da el foco después de su propio frame de apertura.
	await get_tree().process_frame
	_comprobar(opciones_panel.volumen_slider.has_focus(), "Opciones toma el foco al abrirse")

	await _pulsar(JOY_BUTTON_B)
	_comprobar(not opciones_panel.visible, "B / ESC cierra Opciones")
	_comprobar(
		get_viewport().gui_get_focus_owner() == menu.get_node("Botones/Opciones"),
		"al cerrar Opciones el foco vuelve al menú"
	)

	# Reabrimos Opciones y la saltamos con Espacio desde el control de volumen.
	await _pulsar(JOY_BUTTON_A)
	_comprobar(opciones_panel.visible, "A reabre Opciones")
	await get_tree().process_frame
	_comprobar(opciones_panel.volumen_slider.has_focus(), "Opciones vuelve a tomar el foco")
	await _pulsar_tecla(KEY_SPACE)
	_comprobar(not opciones_panel.visible, "ESPACIO salta el panel de Opciones")
	_comprobar(
		get_viewport().gui_get_focus_owner() == menu.get_node("Botones/Opciones"),
		"tras saltar Opciones el foco vuelve al menú"
	)

	menu.queue_free()
	await get_tree().process_frame

	# Tercera sesión: Espacio también cierra el aviso.
	GUION_AVISO.reiniciar_para_prueba()
	menu = await _abrir_menu()
	aviso = menu.get_node("AvisoPausa")
	_comprobar(aviso.visible, "el aviso vuelve a aparecer para probar ESPACIO")
	await _pulsar_tecla(KEY_SPACE)
	_comprobar(not aviso.visible, "ESPACIO cierra el aviso")
	_comprobar(
		_es_boton_menu(menu, get_viewport().gui_get_focus_owner()),
		"tras cerrar con ESPACIO el foco vuelve al menú"
	)

	menu.queue_free()
	await get_tree().process_frame

	# Cuarta sesión: B / ESC también cierra el aviso.
	GUION_AVISO.reiniciar_para_prueba()
	menu = await _abrir_menu()
	aviso = menu.get_node("AvisoPausa")
	_comprobar(aviso.visible, "el aviso vuelve a aparecer para probar B")
	await _pulsar(JOY_BUTTON_B)
	_comprobar(not aviso.visible, "B / ESC cierra el aviso")
	_comprobar(
		_es_boton_menu(menu, get_viewport().gui_get_focus_owner()),
		"tras cerrar con B el foco vuelve al menú"
	)

	menu.queue_free()
	await get_tree().process_frame

	# Quinta apertura sin reiniciar la marca: ya no debe salir el aviso.
	var menu_repetido: Control = await _abrir_menu()
	var aviso_repetido = menu_repetido.get_node("AvisoPausa")
	_comprobar(
		not aviso_repetido.visible,
		"el aviso no se repite al volver al menú en la misma sesión"
	)
	_comprobar(
		_es_boton_menu(menu_repetido, get_viewport().gui_get_focus_owner()),
		"sin aviso, el menú recupera el foco directamente"
	)

	GUION_AVISO.reiniciar_para_prueba()
	if _fallos.is_empty():
		print("PRUEBA AVISO PAUSA OK")
	else:
		print("PRUEBA AVISO PAUSA FALLIDA: %s" % [_fallos])
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _abrir_menu() -> Control:
	var menu: Control = MENU.instantiate()
	add_child(menu)
	# El menú funde la entrada (0.35 s) y solo después abre el aviso.
	await get_tree().create_timer(0.6).timeout
	return menu


func _foco_atrapado(aviso) -> bool:
	var entendido: Button = aviso.entendido
	var ver_opciones: Button = aviso.ver_opciones
	var a_entendido := ver_opciones.get_path_to(entendido)
	var a_ver_opciones := entendido.get_path_to(ver_opciones)
	return (
		entendido.focus_neighbor_top == a_ver_opciones
		and entendido.focus_neighbor_bottom == a_ver_opciones
		and entendido.focus_next == a_ver_opciones
		and entendido.focus_previous == a_ver_opciones
		and ver_opciones.focus_neighbor_top == a_entendido
		and ver_opciones.focus_neighbor_bottom == a_entendido
		and ver_opciones.focus_next == a_entendido
		and ver_opciones.focus_previous == a_entendido
	)


func _es_boton_menu(menu: Control, control: Control) -> bool:
	if control == null:
		return false
	for nombre in BOTONES_MENU:
		if control == menu.get_node("Botones/" + nombre):
			return true
	return false


func _pulsar(boton: JoyButton) -> void:
	_enviar_boton(boton, true)
	await get_tree().process_frame
	_enviar_boton(boton, false)
	await get_tree().process_frame


func _pulsar_tecla(codigo: Key) -> void:
	_enviar_tecla(codigo, true)
	await get_tree().process_frame
	_enviar_tecla(codigo, false)
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
