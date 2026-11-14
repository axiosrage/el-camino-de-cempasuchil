extends Control

signal cerrado
signal cargar_solicitado(slot: int)
signal nueva_solicitada(slot: int)

const COLOR_DORADO := Color(0.9686, 0.7882, 0.2824, 1.0)
const COLOR_CREMA := Color(0.9608, 0.902, 0.7843, 1.0)

@onready var titulo: Label = %Titulo
@onready var subtitulo: Label = %Subtitulo
@onready var ranuras: VBoxContainer = %Ranuras
@onready var volver: Button = %Volver
@onready var confirmacion: Control = %Confirmacion
@onready var texto_confirm: Label = %TextoConfirm
@onready var aviso_confirm: Label = %AvisoConfirm
@onready var boton_si: Button = %Si
@onready var boton_no: Button = %No

var _filas: Array[Dictionary] = []
var _modo_nueva: bool = false
var _accion_confirmada := Callable()
var _foco_previo: Control


func _ready() -> void:
	volver.pressed.connect(cerrar)
	boton_si.pressed.connect(_on_confirmar)
	boton_no.pressed.connect(_cerrar_confirmacion)
	confirmacion.visible = false
	_crear_filas()
	visible = false


func abrir(modo_nueva: bool) -> void:
	_modo_nueva = modo_nueva
	_accion_confirmada = Callable()
	confirmacion.visible = false
	visible = true

	titulo.text = "NUEVA PARTIDA" if modo_nueva else "CONTINUAR PARTIDA"
	subtitulo.text = "ELIGE UNA RANURA PARA EMPEZAR" if modo_nueva else "ELIGE UNA RANURA PARA CARGAR"
	refrescar()

	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

	var objetivo := _primer_control_enfocable()
	if objetivo != null:
		objetivo.grab_focus()
	else:
		volver.grab_focus()


func cerrar() -> void:
	if not visible:
		return
	confirmacion.visible = false
	_accion_confirmada = Callable()
	_restaurar_foco_filas()
	visible = false
	cerrado.emit()


func refrescar() -> void:
	for fila in _filas:
		var slot: int = fila["slot"]
		var info := EstadoJuego.info_slot(slot)
		var existe := bool(info.get("existe", false))
		var danada := bool(info.get("danada", false))

		var boton: Button = fila["boton"]
		var borrar: Button = fila["borrar"]
		var titulo_fila: Label = fila["titulo"]
		var detalle: Label = fila["detalle"]

		titulo_fila.text = "RANURA %d" % slot
		if not existe:
			if _modo_nueva:
				detalle.text = "VACIA  ·  TOCA PARA EMPEZAR"
				detalle.add_theme_color_override("font_color", Color(0.9608, 0.902, 0.7843, 0.9))
			else:
				detalle.text = "VACIA"
				detalle.add_theme_color_override("font_color", Color(0.75, 0.70, 0.62, 0.75))
			boton.disabled = not _modo_nueva
			borrar.disabled = true
			boton.modulate = Color.WHITE if _modo_nueva else Color(0.75, 0.75, 0.75, 0.8)
		elif danada:
			detalle.text = "RANURA DANADA"
			detalle.add_theme_color_override("font_color", Color(0.9, 0.45, 0.35, 1.0))
			boton.disabled = not _modo_nueva
			borrar.disabled = false
			boton.modulate = Color.WHITE if _modo_nueva else Color(0.75, 0.75, 0.75, 0.8)
		else:
			var nivel := str(info.get("nivel", "NIVEL 1"))
			var vida := int(info.get("vida_media", 0))
			var vida_max := int(info.get("vida_maxima_media", 0))
			var jades := int(info.get("jades", 0))
			var fecha := str(info.get("fecha", ""))
			detalle.text = "%s   ·   VIDA %d/%d   ·   %d JADES   ·   %s" % [nivel, vida, vida_max, jades, fecha]
			detalle.add_theme_color_override("font_color", COLOR_CREMA)
			boton.disabled = false
			borrar.disabled = false
			boton.modulate = Color.WHITE


func _crear_filas() -> void:
	for slot in range(1, EstadoJuego.NUM_RANURAS + 1):
		var panel := PanelContainer.new()
		panel.name = "FilaRanura%d" % slot
		panel.custom_minimum_size = Vector2(0, 78)
		panel.add_theme_stylebox_override("panel", _estilo_fila())
		ranuras.add_child(panel)

		var margen := MarginContainer.new()
		margen.name = "Margen"
		margen.add_theme_constant_override("margin_left", 14)
		margen.add_theme_constant_override("margin_top", 8)
		margen.add_theme_constant_override("margin_right", 12)
		margen.add_theme_constant_override("margin_bottom", 8)
		panel.add_child(margen)

		var hbox := HBoxContainer.new()
		hbox.name = "HBox"
		hbox.add_theme_constant_override("separation", 10)
		margen.add_child(hbox)

		var boton := Button.new()
		boton.name = "Elegir"
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.custom_minimum_size = Vector2(0, 62)
		boton.focus_mode = Control.FOCUS_ALL
		boton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		boton.add_theme_stylebox_override("normal", _estilo_boton_fila(Color(1, 1, 1, 0)))
		boton.add_theme_stylebox_override("hover", _estilo_boton_fila(Color(1, 1, 1, 0.06)))
		boton.add_theme_stylebox_override("pressed", _estilo_boton_fila(Color(0, 0, 0, 0.18)))
		boton.add_theme_stylebox_override("disabled", _estilo_boton_fila(Color(1, 1, 1, 0.02)))
		boton.add_theme_stylebox_override("focus", _estilo_foco_fila())
		boton.pressed.connect(_on_ranura_pressed.bind(slot))
		hbox.add_child(boton)

		var info := VBoxContainer.new()
		info.name = "Info"
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info.add_theme_constant_override("separation", 2)
		boton.add_child(info)
		info.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		info.offset_left = 14
		info.offset_top = 6
		info.offset_right = -14
		info.offset_bottom = -6

		var titulo_fila := Label.new()
		titulo_fila.name = "Nombre"
		titulo_fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		titulo_fila.add_theme_font_size_override("font_size", 20)
		titulo_fila.add_theme_color_override("font_color", COLOR_DORADO)
		info.add_child(titulo_fila)

		var detalle := Label.new()
		detalle.name = "Detalle"
		detalle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		detalle.add_theme_font_size_override("font_size", 15)
		detalle.add_theme_color_override("font_color", COLOR_CREMA)
		info.add_child(detalle)

		var borrar := Button.new()
		borrar.name = "Borrar"
		borrar.text = "BORRAR"
		borrar.custom_minimum_size = Vector2(110, 42)
		borrar.focus_mode = Control.FOCUS_ALL
		borrar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		borrar.add_theme_font_size_override("font_size", 14)
		borrar.pressed.connect(_on_borrar_pressed.bind(slot))
		hbox.add_child(borrar)

		_filas.append({
			"slot": slot,
			"panel": panel,
			"boton": boton,
			"borrar": borrar,
			"titulo": titulo_fila,
			"detalle": detalle,
		})


func _estilo_fila() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.09, 0.07, 0.12, 0.92)
	estilo.border_width_left = 1
	estilo.border_width_top = 1
	estilo.border_width_right = 1
	estilo.border_width_bottom = 1
	estilo.border_color = Color(0.9686, 0.7882, 0.2824, 0.35)
	estilo.corner_radius_top_left = 4
	estilo.corner_radius_top_right = 4
	estilo.corner_radius_bottom_right = 4
	estilo.corner_radius_bottom_left = 4
	return estilo


func _estilo_boton_fila(color: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.corner_radius_top_left = 3
	estilo.corner_radius_top_right = 3
	estilo.corner_radius_bottom_right = 3
	estilo.corner_radius_bottom_left = 3
	return estilo


func _estilo_foco_fila() -> StyleBoxFlat:
	var estilo := _estilo_boton_fila(Color(0, 0, 0, 0))
	estilo.border_width_left = 2
	estilo.border_width_top = 2
	estilo.border_width_right = 2
	estilo.border_width_bottom = 2
	estilo.border_color = COLOR_DORADO
	return estilo


func _primer_control_enfocable() -> Control:
	for fila in _filas:
		var boton: Button = fila["boton"]
		if not boton.disabled:
			return boton
	return volver


func _on_ranura_pressed(slot: int) -> void:
	var info := EstadoJuego.info_slot(slot)
	var existe := bool(info.get("existe", false))
	var danada := bool(info.get("danada", false))

	if _modo_nueva:
		if existe:
			_pedir_confirmacion(
				"SOBRESCRIBIR RANURA %d?" % slot,
				"SE PERDERA LA PARTIDA GUARDADA.",
				_nueva_slot_confirmada.bind(slot)
			)
		else:
			nueva_solicitada.emit(slot)
	else:
		if existe and not danada:
			cargar_solicitado.emit(slot)


func _on_borrar_pressed(slot: int) -> void:
	if not bool(EstadoJuego.info_slot(slot).get("existe", false)):
		return
	_pedir_confirmacion(
		"BORRAR RANURA %d?" % slot,
		"ESTA ACCION NO SE PUEDE DESHACER.",
		_borrar_slot_confirmado.bind(slot)
	)


func _nueva_slot_confirmada(slot: int) -> void:
	nueva_solicitada.emit(slot)


func _borrar_slot_confirmado(slot: int) -> void:
	EstadoJuego.borrar_slot(slot)
	refrescar()
	var boton_previo := _foco_previo as Button
	if boton_previo != null and is_instance_valid(boton_previo) and not boton_previo.disabled:
		boton_previo.grab_focus()
	else:
		_primer_control_enfocable().grab_focus()


func _pedir_confirmacion(texto: String, aviso: String, accion: Callable) -> void:
	_accion_confirmada = accion
	texto_confirm.text = texto
	aviso_confirm.text = aviso
	_foco_previo = get_viewport().gui_get_focus_owner()
	_bloquear_foco_filas()
	confirmacion.visible = true
	boton_si.grab_focus()


func _on_confirmar() -> void:
	confirmacion.visible = false
	_restaurar_foco_filas()
	var accion := _accion_confirmada
	_accion_confirmada = Callable()
	if accion.is_valid():
		accion.call()


func _cerrar_confirmacion() -> void:
	confirmacion.visible = false
	_accion_confirmada = Callable()
	_restaurar_foco_filas()
	if _foco_previo != null and is_instance_valid(_foco_previo):
		_foco_previo.grab_focus()


func _bloquear_foco_filas() -> void:
	for fila in _filas:
		(fila["boton"] as Control).focus_mode = Control.FOCUS_NONE
		(fila["borrar"] as Control).focus_mode = Control.FOCUS_NONE
	volver.focus_mode = Control.FOCUS_NONE


func _restaurar_foco_filas() -> void:
	for fila in _filas:
		(fila["boton"] as Control).focus_mode = Control.FOCUS_ALL
		(fila["borrar"] as Control).focus_mode = Control.FOCUS_ALL
	volver.focus_mode = Control.FOCUS_ALL


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if confirmacion.visible:
			_cerrar_confirmacion()
		else:
			cerrar()
		get_viewport().set_input_as_handled()
