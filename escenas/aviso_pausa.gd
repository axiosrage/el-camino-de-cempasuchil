extends Control

## Aviso que se muestra una sola vez por sesión, al abrir el juego.
## No se guarda en la configuración: si se cierra el juego, vuelve a salir.

signal cerrado
signal opciones_solicitadas

static var _mostrado_en_sesion: bool = false

@onready var texto: Label = %Texto
@onready var entendido: Button = %Entendido
@onready var ver_opciones: Button = %VerOpciones


func _ready() -> void:
	visible = false
	_configurar_texto()
	_configurar_foco_atrapado()
	entendido.pressed.connect(cerrar)
	ver_opciones.pressed.connect(_abrir_opciones)


func debe_mostrarse() -> bool:
	return not _mostrado_en_sesion


func abrir() -> void:
	if _mostrado_en_sesion:
		return

	_mostrado_en_sesion = true
	visible = true
	modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

	# Esperamos a que el panel se coloque antes de darle el foco.
	await get_tree().process_frame
	if visible and is_inside_tree():
		entendido.grab_focus()


func cerrar() -> void:
	if not visible:
		return
	visible = false
	cerrado.emit()


func _abrir_opciones() -> void:
	if not visible:
		return
	visible = false
	opciones_solicitadas.emit()


func _configurar_texto() -> void:
	# En Linux y en la web se puede usar la cámara; en el resto de
	# plataformas (Windows incluido) solo existe la pausa por foco.
	if OS.has_feature("web") or OS.get_name() == "Linux":
		texto.text = (
			"EL JUEGO SE PAUSA SOLO SI DEJAS DE ESTAR FRENTE A LA CÁMARA "
			+ "O SI LA VENTANA PIERDE EL FOCO.\n\n"
			+ "LA CÁMARA NO GUARDA IMÁGENES. PUEDES DESACTIVAR ESTAS PAUSAS "
			+ "EN OPCIONES."
		)
	else:
		texto.text = (
			"EL JUEGO SE PAUSA SOLO SI LA VENTANA PIERDE EL FOCO.\n\n"
			+ "PUEDES DESACTIVAR ESTA PAUSA EN OPCIONES."
		)


func _configurar_foco_atrapado() -> void:
	var botones: Array[Button] = [entendido, ver_opciones]
	for boton in botones:
		var otro := ver_opciones if boton == entendido else entendido
		boton.focus_neighbor_top = boton.get_path_to(otro)
		boton.focus_neighbor_bottom = boton.get_path_to(otro)
		boton.focus_neighbor_left = boton.get_path_to(otro)
		boton.focus_neighbor_right = boton.get_path_to(otro)
		boton.focus_next = boton.get_path_to(otro)
		boton.focus_previous = boton.get_path_to(otro)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()


## Solo para las pruebas: permite simular una nueva ejecución del juego.
static func reiniciar_para_prueba() -> void:
	_mostrado_en_sesion = false
