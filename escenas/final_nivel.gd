extends CanvasLayer

## Pantalla final del nivel.
##
## Al entrar al portal se muestra primero el panel `finalDemo` de la carpeta
## de la intro. Se puede avanzar con Espacio/Enter/A o esperar su duración;
## después aparece el mensaje de nivel completado y el botón de volver al menú.

signal volver_al_menu

# Tiempo que permanece el panel antes de pasar al mensaje.
const DURACION_PANEL_DEMO: float = 4.0
const MARGEN_PANEL_DEMO: float = 32.0
const DURACION_FADE_PANEL: float = 0.35

@onready var contenido: VBoxContainer = $Centro/Contenido
@onready var boton: Button = $Centro/Contenido/Boton
@onready var panel_demo: TextureRect = $PanelDemo

var _saliendo: bool = false
var _panel_demo_activo: bool = false
var _avanzar_panel: bool = false


func _ready() -> void:
	contenido.modulate.a = 0.0
	boton.pressed.connect(_on_volver)
	get_viewport().size_changed.connect(_ajustar_panel_demo)
	_ajustar_panel_demo()
	_mostrar_panel_demo()


func _ajustar_panel_demo() -> void:
	if panel_demo == null or panel_demo.texture == null:
		return

	var tamano := panel_demo.texture.get_size()
	if tamano.x <= 0.0 or tamano.y <= 0.0:
		return

	var area: Vector2 = get_viewport().get_visible_rect().size
	var disponible: Vector2 = area - Vector2(MARGEN_PANEL_DEMO * 2.0, MARGEN_PANEL_DEMO * 2.0)
	var escala := minf(disponible.x / tamano.x, disponible.y / tamano.y)
	panel_demo.size = (tamano * escala).floor()
	panel_demo.position = ((area - panel_demo.size) / 2.0).floor()


func _mostrar_panel_demo() -> void:
	_panel_demo_activo = true
	_avanzar_panel = false
	panel_demo.visible = true
	panel_demo.modulate.a = 0.0

	var entrada := create_tween()
	entrada.tween_property(panel_demo, "modulate:a", 1.0, 0.4)
	await entrada.finished
	if not _panel_demo_activo or _saliendo:
		return

	var restante := DURACION_PANEL_DEMO
	while restante > 0.0 and not _avanzar_panel:
		await get_tree().create_timer(0.1).timeout
		restante -= 0.1
	if not _panel_demo_activo or _saliendo:
		return

	var salida := create_tween()
	salida.tween_property(panel_demo, "modulate:a", 0.0, DURACION_FADE_PANEL)
	await salida.finished
	if not _panel_demo_activo or _saliendo:
		return

	_panel_demo_activo = false
	panel_demo.visible = false
	_mostrar_mensaje()


func _mostrar_mensaje() -> void:
	boton.grab_focus()
	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(contenido, "modulate:a", 1.0, 1.1)


func _unhandled_input(event: InputEvent) -> void:
	if _panel_demo_activo:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_avanzar_panel = true
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		_on_volver()
		get_viewport().set_input_as_handled()


func _on_volver() -> void:
	if _saliendo:
		return

	_saliendo = true
	_avanzar_panel = true
	boton.disabled = true
	volver_al_menu.emit()
	get_tree().paused = false
	Musica.reproducir_menu()
	get_tree().change_scene_to_file("res://escenas/menu.tscn")
