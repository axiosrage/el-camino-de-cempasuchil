extends CanvasLayer

@onready var boton_reanudar: Button = $Centro/Panel/Margen/VBox/Reanudar
@onready var boton_opciones: Button = $Centro/Panel/Margen/VBox/Opciones
@onready var boton_menu: Button = $Centro/Panel/Margen/VBox/Menu
@onready var boton_salir: Button = $Centro/Panel/Margen/VBox/Salir
@onready var titulo: Label = $Centro/Panel/Margen/VBox/Titulo
@onready var motivo: Label = $Centro/Panel/Margen/VBox/Motivo
@onready var reanudacion: Label = $Centro/Panel/Margen/VBox/Reanudacion
@onready var centro: CenterContainer = $Centro
@onready var fondo: ColorRect = $Fondo
@onready var opciones_panel = $Opciones

var _botones: Array[Button] = []
var _pausa_automatica: bool = false


func _ready() -> void:
	visible = false
	_botones = [boton_reanudar, boton_opciones, boton_menu, boton_salir]
	boton_reanudar.pressed.connect(_on_reanudar_pressed)
	boton_opciones.pressed.connect(_on_opciones_pressed)
	boton_menu.pressed.connect(_on_menu_pressed)
	boton_salir.pressed.connect(_on_salir_pressed)
	opciones_panel.cerrado.connect(_on_opciones_cerrado)
	DetectorPresencia.pausa_automatica_solicitada.connect(_on_pausa_automatica)
	DetectorPresencia.reanudacion_automatica_solicitada.connect(_on_reanudacion_automatica)
	DetectorPresencia.activar_en_nivel()


func _exit_tree() -> void:
	DetectorPresencia.desactivar_en_nivel(true)


func _process(_delta: float) -> void:
	if not _pausa_automatica or not visible:
		return

	var motivo_auto := DetectorPresencia.get_motivo_auto()
	if motivo_auto == DetectorPresencia.MOTIVO_FOCO:
		reanudacion.text = "VUELVE A LA VENTANA PARA CONTINUAR"
		return

	var restante := DetectorPresencia.get_restante_reanudacion()
	if restante > 0.0:
		reanudacion.text = "REGRESO DETECTADO · %.1f s" % restante
	else:
		reanudacion.text = "ACÉRCATE A LA CÁMARA PARA CONTINUAR"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		# Con Opciones abierto, ese panel se encarga de cerrarse.
		if opciones_panel.visible:
			return
		if visible:
			reanudar()
		else:
			pausar()
		get_viewport().set_input_as_handled()
		return

	# B/atrás reanuda la pausa, pero no la abre: para eso está Start.
	if event.is_action_pressed("ui_cancel"):
		if opciones_panel.visible:
			return
		if visible:
			reanudar()
			get_viewport().set_input_as_handled()


## Pausa manual: detiene la cámara y cancela cualquier pausa automática.
func pausar() -> void:
	if visible:
		return
	_pausa_automatica = false
	DetectorPresencia.cancelar_automatico()
	DetectorPresencia.detener_camara()
	_mostrar_menu("PAUSA", "")


func pausar_automatico(motivo_pausa: String) -> void:
	if visible:
		return
	_pausa_automatica = true

	if motivo_pausa == DetectorPresencia.MOTIVO_FOCO:
		_mostrar_menu("PAUSA AUTOMÁTICA", "VENTANA SIN FOCO")
		reanudacion.text = "VUELVE A LA VENTANA PARA CONTINUAR"
	else:
		_mostrar_menu("PAUSA AUTOMÁTICA", "NO SE DETECTÓ PRESENCIA")
		reanudacion.text = "ACÉRCATE A LA CÁMARA PARA CONTINUAR"


func reanudar() -> void:
	if not visible:
		return

	var era_automatica := _pausa_automatica
	_pausa_automatica = false
	if era_automatica:
		DetectorPresencia.cancelar_automatico()

	_ocultar_menu()
	# Si la partida estaba en pausa manual la cámara se apagó; al volver
	# al juego la reactivamos sin volver a pedir permiso.
	DetectorPresencia.reanudar_camara()


func reanudar_automatico() -> void:
	if not visible or not _pausa_automatica:
		return
	_pausa_automatica = false
	_ocultar_menu()
	DetectorPresencia.reanudar_camara()


func _mostrar_menu(titulo_texto: String, motivo_texto: String) -> void:
	titulo.text = titulo_texto
	motivo.text = motivo_texto
	motivo.visible = not motivo_texto.is_empty()
	reanudacion.visible = _pausa_automatica
	visible = true
	centro.visible = true
	fondo.visible = true
	get_tree().paused = true
	boton_reanudar.grab_focus()


func _ocultar_menu() -> void:
	visible = false
	centro.visible = false
	fondo.visible = false
	motivo.visible = false
	reanudacion.visible = false
	titulo.text = "PAUSA"
	get_tree().paused = false


func _on_reanudar_pressed() -> void:
	reanudar()


func _on_opciones_pressed() -> void:
	if _pausa_automatica:
		# Abrir Opciones es una acción manual: la pausa deja de ser
		# automática y la cámara puede apagarse mientras se configura.
		_pausa_automatica = false
		DetectorPresencia.cancelar_automatico()
		DetectorPresencia.detener_camara()
		titulo.text = "PAUSA"

	_set_foco_botones(false)
	centro.visible = false
	fondo.visible = false
	motivo.visible = false
	reanudacion.visible = false
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
	DetectorPresencia.desactivar_en_nivel(true)

	# Guardamos el checkpoint antes de abandonar el nivel.
	var nivel := get_parent()
	if nivel != null and nivel.has_method("guardar_partida_actual"):
		nivel.guardar_partida_actual(true)

	get_tree().change_scene_to_file("res://escenas/menu.tscn")


func _on_salir_pressed() -> void:
	get_tree().paused = false
	DetectorPresencia.desactivar_en_nivel(true)

	# Guardamos el checkpoint antes de cerrar el juego.
	var nivel := get_parent()
	if nivel != null and nivel.has_method("guardar_partida_actual"):
		nivel.guardar_partida_actual(true)

	SalidaWeb.salir()


func _on_pausa_automatica(motivo_pausa: String) -> void:
	pausar_automatico(motivo_pausa)


func _on_reanudacion_automatica(_motivo_pausa: String) -> void:
	reanudar_automatico()
