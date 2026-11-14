extends Control

signal cerrado

@onready var volumen_slider: HSlider = %VolumenSlider
@onready var volumen_valor: Label = %VolumenValor
@onready var pantalla_check: CheckButton = %PantallaCheck
@onready var volver: Button = %Volver


func _ready() -> void:
	volver.pressed.connect(cerrar)
	volumen_slider.value_changed.connect(_on_volumen_cambiado)
	pantalla_check.toggled.connect(_on_pantalla_cambiada)
	visible = false


func abrir() -> void:
	visible = true
	_cargar_ui()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	volver.grab_focus()


func cerrar() -> void:
	if not visible:
		return
	visible = false
	cerrado.emit()


func _cargar_ui() -> void:
	volumen_slider.set_value_no_signal(Configuracion.volumen * 100.0)
	volumen_valor.text = "%d%%" % roundi(Configuracion.volumen * 100.0)
	pantalla_check.set_pressed_no_signal(Configuracion.pantalla_completa)
	pantalla_check.text = "SI" if Configuracion.pantalla_completa else "NO"


func _on_volumen_cambiado(valor: float) -> void:
	Configuracion.set_volumen(valor / 100.0)
	volumen_valor.text = "%d%%" % roundi(valor)


func _on_pantalla_cambiada(activa: bool) -> void:
	pantalla_check.text = "SI" if activa else "NO"
	Configuracion.set_pantalla_completa(activa)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		cerrar()
		get_viewport().set_input_as_handled()
