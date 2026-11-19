extends CanvasLayer

@onready var boton_reanudar: Button = $Centro/Panel/Margen/VBox/Reanudar
@onready var boton_opciones: Button = $Centro/Panel/Margen/VBox/Opciones
@onready var boton_menu: Button = $Centro/Panel/Margen/VBox/Menu
@onready var centro: CenterContainer = $Centro
@onready var fondo: ColorRect = $Fondo
@onready var opciones_panel = $Opciones

var _botones: Array[Button] = []


func _ready() -> void:
	visible = false
	_botones = [boton_reanudar, boton_opciones, boton_menu]
	boton_reanudar.pressed.connect(_on_reanudar_pressed)
	boton_opciones.pressed.connect(_on_opciones_pressed)
	boton_menu.pressed.connect(_on_menu_pressed)
	opciones_panel.cerrado.connect(_on_opciones_cerrado)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Con Opciones abierto, ese panel se encarga de cerrarse.
		if opciones_panel.visible:
			return
		if visible:
			reanudar()
		else:
			pausar()
		get_viewport().set_input_as_handled()


func pausar() -> void:
	visible = true
	centro.visible = true
	fondo.visible = true
	get_tree().paused = true
	boton_reanudar.grab_focus()


func reanudar() -> void:
	visible = false
	get_tree().paused = false


func _on_reanudar_pressed() -> void:
	reanudar()


func _on_opciones_pressed() -> void:
	_set_foco_botones(false)
	centro.visible = false
	fondo.visible = false
	opciones_panel.abrir()


func _on_opciones_cerrado() -> void:
	centro.visible = true
	fondo.visible = true
	_set_foco_botones(true)
	boton_opciones.grab_focus()


func _set_foco_botones(activo: bool) -> void:
	for boton in _botones:
		boton.focus_mode = Control.FOCUS_ALL if activo else Control.FOCUS_NONE


func _on_menu_pressed() -> void:
	get_tree().paused = false

	# Guardamos el checkpoint antes de abandonar el nivel.
	var nivel := get_parent()
	if nivel != null and nivel.has_method("guardar_partida_actual"):
		nivel.guardar_partida_actual(true)

	get_tree().change_scene_to_file("res://escenas/menu.tscn")
