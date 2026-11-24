extends Control

@onready var continuar: TextureButton = $Botones/Continuar
@onready var nueva: TextureButton = $Botones/NuevaPartida
@onready var opciones: TextureButton = $Botones/Opciones
@onready var salir: TextureButton = $Botones/Salir
@onready var sin_partida: Label = $SinPartida
@onready var foco: Panel = $Foco
@onready var fade_rect: ColorRect = $FadeRect
@onready var opciones_panel = $Opciones
@onready var seleccion_panel = $SeleccionPartidas
@onready var aviso_pausa = $AvisoPausa

var _botones: Array[TextureButton] = []
var _transicionando: bool = false
var _boton_origen_panel: TextureButton


func _ready() -> void:
	Musica.reproducir_menu()
	_botones = [continuar, nueva, opciones, salir]

	for boton in _botones:
		boton.mouse_entered.connect(_on_boton_mouse_entered.bind(boton))
		boton.mouse_exited.connect(_on_boton_mouse_exited.bind(boton))
		boton.focus_entered.connect(_on_boton_focus_entered.bind(boton))
		boton.focus_exited.connect(_on_boton_focus_exited.bind(boton))

	continuar.pressed.connect(_on_continuar_pressed)
	nueva.pressed.connect(_on_nueva_pressed)
	opciones.pressed.connect(_on_opciones_pressed)
	salir.pressed.connect(_on_salir_pressed)

	opciones_panel.cerrado.connect(_on_opciones_cerrado)
	seleccion_panel.cerrado.connect(_on_seleccion_cerrado)
	seleccion_panel.cargar_solicitado.connect(_on_cargar_solicitado)
	seleccion_panel.nueva_solicitada.connect(_on_nueva_solicitada)
	aviso_pausa.cerrado.connect(_on_aviso_cerrado)
	aviso_pausa.opciones_solicitadas.connect(_on_aviso_opciones)

	get_viewport().size_changed.connect(_on_viewport_size_changed)

	fade_rect.modulate.a = 1.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_actualizar_continuar()

	await get_tree().process_frame
	if not is_inside_tree():
		return

	_actualizar_pivotes()
	_configurar_focos()

	var mostrar_aviso: bool = aviso_pausa.debe_mostrarse()
	if mostrar_aviso:
		# Los botones del menú no deben recibir foco mientras el aviso
		# modal está abierto.
		_set_foco_botones(false)
	else:
		_foco_inicial_menu()

	await _fundir_entrada()
	if not is_inside_tree():
		return

	if mostrar_aviso:
		aviso_pausa.abrir()
		_actualizar_foco()


func _foco_inicial_menu() -> void:
	if continuar.disabled:
		nueva.grab_focus()
	else:
		continuar.grab_focus()


func _on_viewport_size_changed() -> void:
	_actualizar_pivotes()
	_actualizar_foco()


func _actualizar_pivotes() -> void:
	for boton in _botones:
		boton.pivot_offset = boton.size / 2.0


func _actualizar_continuar() -> void:
	var hay_guardado := EstadoJuego.hay_partida_guardada()
	continuar.disabled = not hay_guardado
	continuar.focus_mode = Control.FOCUS_ALL if hay_guardado else Control.FOCUS_NONE
	continuar.modulate = Color.WHITE if hay_guardado else Color(1.0, 1.0, 1.0, 0.0)
	continuar.mouse_filter = Control.MOUSE_FILTER_STOP if hay_guardado else Control.MOUSE_FILTER_IGNORE
	sin_partida.visible = not hay_guardado


func _configurar_focos() -> void:
	if continuar.disabled:
		nueva.focus_neighbor_top = nueva.get_path_to(salir)
		salir.focus_neighbor_bottom = salir.get_path_to(nueva)
	else:
		continuar.focus_neighbor_top = continuar.get_path_to(salir)
		continuar.focus_neighbor_bottom = continuar.get_path_to(nueva)
		nueva.focus_neighbor_top = nueva.get_path_to(continuar)
		salir.focus_neighbor_bottom = salir.get_path_to(continuar)

	nueva.focus_neighbor_bottom = nueva.get_path_to(opciones)
	opciones.focus_neighbor_top = opciones.get_path_to(nueva)
	opciones.focus_neighbor_bottom = opciones.get_path_to(salir)
	salir.focus_neighbor_top = salir.get_path_to(opciones)


func _fundir_entrada() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.35)
	await tween.finished
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_boton_mouse_entered(boton: TextureButton) -> void:
	if _transicionando or boton.disabled:
		return
	if not boton.has_focus():
		boton.grab_focus()
	_resaltar(boton, true)


func _on_boton_mouse_exited(boton: TextureButton) -> void:
	if _transicionando or boton.disabled:
		return
	if not boton.has_focus():
		_resaltar(boton, false)


func _on_boton_focus_entered(boton: TextureButton) -> void:
	if _transicionando or boton.disabled:
		return
	_resaltar(boton, true)
	_actualizar_foco()


func _on_boton_focus_exited(boton: TextureButton) -> void:
	if not boton.is_hovered():
		_resaltar(boton, false)
	call_deferred("_actualizar_foco")


func _resaltar(boton: TextureButton, activo: bool) -> void:
	if boton.disabled:
		return

	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var color := Color(1.12, 1.08, 0.95) if activo else Color.WHITE
	var escala := Vector2(1.02, 1.02) if activo else Vector2.ONE
	tween.tween_property(boton, "modulate", color, 0.08)
	tween.tween_property(boton, "scale", escala, 0.08)


func _actualizar_foco() -> void:
	if not is_inside_tree():
		return
	var viewport := get_viewport()
	if viewport == null:
		return

	var dueno := viewport.gui_get_focus_owner()
	if dueno is TextureButton and _botones.has(dueno) and not dueno.disabled:
		var rect := dueno.get_global_rect()
		foco.global_position = rect.position - Vector2(4.0, 4.0)
		foco.size = rect.size + Vector2(8.0, 8.0)
		foco.visible = true
	else:
		foco.visible = false


func _set_foco_botones(activo: bool) -> void:
	for boton in _botones:
		boton.focus_mode = Control.FOCUS_ALL if activo else Control.FOCUS_NONE
	if not activo:
		foco.visible = false


func _restaurar_foco_menu(boton: TextureButton) -> void:
	if _transicionando:
		return

	for item in _botones:
		item.focus_mode = Control.FOCUS_ALL
	_actualizar_continuar()
	_configurar_focos()

	if boton == null or boton.disabled:
		nueva.grab_focus()
	else:
		boton.grab_focus()


func _on_continuar_pressed() -> void:
	if _transicionando or continuar.disabled:
		return
	_abrir_seleccion(false)


func _on_nueva_pressed() -> void:
	if _transicionando:
		return
	_abrir_seleccion(true)


func _on_opciones_pressed() -> void:
	if _transicionando:
		return
	_boton_origen_panel = opciones
	_set_foco_botones(false)
	opciones_panel.abrir()


func _on_salir_pressed() -> void:
	if _transicionando:
		return
	SalidaWeb.salir()


func _abrir_seleccion(modo_nueva: bool) -> void:
	_boton_origen_panel = nueva if modo_nueva else continuar
	_set_foco_botones(false)
	seleccion_panel.abrir(modo_nueva)


func _on_opciones_cerrado() -> void:
	_restaurar_foco_menu(opciones)


func _on_aviso_cerrado() -> void:
	_restaurar_foco_menu(null)


func _on_aviso_opciones() -> void:
	_boton_origen_panel = opciones
	_set_foco_botones(false)
	opciones_panel.abrir()


## Espacio, Enter y A saltan el panel que esté abierto en el menú. Si el
## control enfocado usa «aceptar» (un botón, un check, etc.), ese control
## tiene prioridad y el evento no llega hasta aquí.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return

	# Si el foco está en un botón, ese botón se encarga de «aceptar»; no
	# debemos saltarnos el panel antes de que reciba el evento.
	if get_viewport().gui_get_focus_owner() is BaseButton:
		return

	if aviso_pausa.visible:
		aviso_pausa.cerrar()
	elif opciones_panel.visible:
		opciones_panel.cerrar()
	elif seleccion_panel.visible:
		seleccion_panel.cerrar()
	else:
		return

	get_viewport().set_input_as_handled()


func _on_seleccion_cerrado() -> void:
	if _transicionando:
		return
	_restaurar_foco_menu(_boton_origen_panel)


func _on_cargar_solicitado(slot: int) -> void:
	if _transicionando:
		return

	if not EstadoJuego.cargar_slot(slot):
		seleccion_panel.refrescar()
		return

	var escena := EstadoJuego.checkpoint_escena
	if escena.is_empty() or not ResourceLoader.exists(escena):
		escena = "res://escenas/Nivel1.tscn"

	_transicionando = true
	seleccion_panel.cerrar()
	_transicionar(escena)


func _on_nueva_solicitada(slot: int) -> void:
	if _transicionando:
		return

	if not EstadoJuego.nueva_partida_en_slot(slot):
		return

	_transicionando = true
	seleccion_panel.cerrar()
	_transicionar("res://escenas/intro.tscn")


func _transicionar(ruta: String) -> void:
	_transicionando = true
	foco.visible = false
	for boton in _botones:
		boton.disabled = true

	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.35)
	await tween.finished
	get_tree().change_scene_to_file(ruta)
