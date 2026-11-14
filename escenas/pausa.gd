extends CanvasLayer

@onready var boton_reanudar: Button = $Centro/Panel/Margen/VBox/Reanudar
@onready var boton_menu: Button = $Centro/Panel/Margen/VBox/Menu


func _ready() -> void:
	visible = false
	boton_reanudar.pressed.connect(_on_reanudar_pressed)
	boton_menu.pressed.connect(_on_menu_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			reanudar()
		else:
			pausar()
		get_viewport().set_input_as_handled()


func pausar() -> void:
	visible = true
	get_tree().paused = true
	boton_reanudar.grab_focus()


func reanudar() -> void:
	visible = false
	get_tree().paused = false


func _on_reanudar_pressed() -> void:
	reanudar()


func _on_menu_pressed() -> void:
	get_tree().paused = false

	# Guardamos el checkpoint antes de abandonar el nivel.
	var nivel := get_parent()
	if nivel != null and nivel.has_method("guardar_partida_actual"):
		nivel.guardar_partida_actual(true)

	get_tree().change_scene_to_file("res://escenas/menu.tscn")
