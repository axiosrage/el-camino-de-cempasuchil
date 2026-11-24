extends Control

signal cerrado

@onready var volumen_slider: HSlider = %VolumenSlider
@onready var volumen_valor: Label = %VolumenValor
@onready var pantalla_check: CheckButton = %PantallaCheck
@onready var tiempo_pausa: HSlider = %TiempoPausa
@onready var tiempo_pausa_valor: Label = %TiempoPausaValor
@onready var camara_check: CheckButton = %CamaraCheck
@onready var foco_check: CheckButton = %FocoCheck
@onready var estado_camara: Label = %EstadoCamara
@onready var volver: Button = %Volver
@onready var foco: ReferenceRect = $Foco
@onready var panel: PanelContainer = $Centro/Panel

var _permiso_pendiente: bool = false


func _ready() -> void:
	volver.pressed.connect(cerrar)
	volumen_slider.value_changed.connect(_on_volumen_cambiado)
	pantalla_check.toggled.connect(_on_pantalla_cambiada)
	tiempo_pausa.value_changed.connect(_on_tiempo_pausa_cambiado)
	camara_check.toggled.connect(_on_camara_cambiada)
	foco_check.toggled.connect(_on_foco_cambiado)
	DetectorPresencia.estado_cambiado.connect(_on_detector_estado)
	DetectorPresencia.permiso_resultado.connect(_on_permiso_resultado)
	get_viewport().gui_focus_changed.connect(_on_foco_gui_cambiado)
	get_viewport().size_changed.connect(_actualizar_foco)
	panel.resized.connect(_actualizar_foco)
	visible = false


func abrir() -> void:
	visible = true
	_cargar_ui()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

	# Esperamos un frame a que el panel termine de recolocarse con los
	# textos actualizados; si no, el anillo de foco usa la posición vieja.
	await get_tree().process_frame
	if not visible:
		return

	# El primer control recibe el foco para que el mando pueda ajustar
	# opciones sin tener que navegar desde «Volver».
	volumen_slider.grab_focus()
	_actualizar_foco()


func cerrar() -> void:
	if not visible:
		return
	visible = false
	foco.visible = false
	cerrado.emit()


func _on_foco_gui_cambiado(_control: Control) -> void:
	_actualizar_foco()


func _actualizar_foco() -> void:
	if not visible:
		foco.visible = false
		return

	var control := get_viewport().gui_get_focus_owner()
	if control == null or not panel.is_ancestor_of(control):
		foco.visible = false
		return

	var rect := control.get_global_rect()
	var padre := control.get_parent()
	if padre is HBoxContainer and (control is HSlider or control is CheckButton):
		rect = (padre as Control).get_global_rect()

	foco.global_position = (rect.position - Vector2(4.0, 4.0)).floor()
	foco.size = (rect.size + Vector2(8.0, 8.0)).floor()
	foco.visible = true


func _cargar_ui() -> void:
	volumen_slider.set_value_no_signal(Configuracion.volumen * 100.0)
	volumen_valor.text = "%d%%" % roundi(Configuracion.volumen * 100.0)
	pantalla_check.set_pressed_no_signal(Configuracion.pantalla_completa)
	pantalla_check.text = "SI" if Configuracion.pantalla_completa else "NO"

	var indice := Configuracion.TIEMPOS_PAUSA.find(Configuracion.pausa_tiempo)
	if indice < 0:
		indice = Configuracion.TIEMPOS_PAUSA.find(Configuracion.TIEMPO_PAUSA_DEFECTO)
	tiempo_pausa.set_value_no_signal(float(indice))
	tiempo_pausa_valor.text = "%d s" % Configuracion.TIEMPOS_PAUSA[indice]

	camara_check.disabled = not _camara_soportada() or _permiso_pendiente
	camara_check.set_pressed_no_signal(Configuracion.pausa_camara)
	camara_check.text = "SI" if Configuracion.pausa_camara else "NO"

	foco_check.set_pressed_no_signal(Configuracion.pausa_foco)
	foco_check.text = "SI" if Configuracion.pausa_foco else "NO"

	_actualizar_estado_camara()


func _on_volumen_cambiado(valor: float) -> void:
	Configuracion.set_volumen(valor / 100.0)
	volumen_valor.text = "%d%%" % roundi(valor)


func _on_pantalla_cambiada(activa: bool) -> void:
	pantalla_check.text = "SI" if activa else "NO"
	Configuracion.set_pantalla_completa(activa)


func _on_tiempo_pausa_cambiado(valor: float) -> void:
	var indice := clampi(roundi(valor), 0, Configuracion.TIEMPOS_PAUSA.size() - 1)
	var segundos: int = Configuracion.TIEMPOS_PAUSA[indice]
	tiempo_pausa_valor.text = "%d s" % segundos
	Configuracion.set_pausa_tiempo(segundos)


func _on_camara_cambiada(activa: bool) -> void:
	camara_check.text = "SI" if activa else "NO"

	if not activa:
		_permiso_pendiente = false
		camara_check.disabled = not _camara_soportada()
		Configuracion.set_pausa_camara(false)
		DetectorPresencia.detener_camara()
		_actualizar_estado_camara()
		return

	if not _camara_soportada():
		camara_check.set_pressed_no_signal(false)
		camara_check.text = "NO"
		_actualizar_estado_camara()
		return

	# Primero guardamos la preferencia y luego pedimos permiso. Si se
	# deniega, la opción vuelve a quedar apagada automáticamente.
	_permiso_pendiente = true
	camara_check.disabled = true
	Configuracion.set_pausa_camara(true)
	DetectorPresencia.solicitar_permiso()
	_actualizar_estado_camara()


func _on_foco_cambiado(activa: bool) -> void:
	foco_check.text = "SI" if activa else "NO"
	Configuracion.set_pausa_foco(activa)


func _on_detector_estado(_estado: int) -> void:
	if visible:
		_actualizar_estado_camara()


func _on_permiso_resultado(ok: bool, _mensaje: String) -> void:
	if not _permiso_pendiente:
		return

	_permiso_pendiente = false
	camara_check.disabled = not _camara_soportada()

	if not ok:
		Configuracion.set_pausa_camara(false)
		camara_check.set_pressed_no_signal(false)
		camara_check.text = "NO"
	elif not Configuracion.pausa_camara:
		# El jugador apagó la opción mientras se pedía el permiso.
		camara_check.set_pressed_no_signal(false)
		camara_check.text = "NO"

	_actualizar_estado_camara()


func _actualizar_estado_camara() -> void:
	var texto := "CÁMARA: "

	if not _camara_soportada():
		texto += "NO DISPONIBLE EN ESTA PLATAFORMA"
		estado_camara.text = texto
		return

	var estado := DetectorPresencia.get_estado()

	if not Configuracion.pausa_camara:
		texto += "APAGADA"
		if estado == DetectorPresencia.Estado.SIN_PERMISO:
			texto = "CÁMARA: PERMISO DENEGADO"
		elif estado == DetectorPresencia.Estado.NO_DISPONIBLE:
			texto = "CÁMARA: NO DISPONIBLE"
		elif estado == DetectorPresencia.Estado.ERROR:
			texto = "CÁMARA: ERROR"
	else:
		match estado:
			DetectorPresencia.Estado.SOLICITANDO:
				texto += "SOLICITANDO PERMISO…"
			DetectorPresencia.Estado.SIN_PERMISO:
				texto += "PERMISO DENEGADO"
			DetectorPresencia.Estado.NO_DISPONIBLE:
				texto += "NO DISPONIBLE"
			DetectorPresencia.Estado.ERROR:
				texto += "ERROR"
			DetectorPresencia.Estado.ACTIVO:
				texto += "ACTIVA · %s" % DetectorPresencia.get_backend_nombre()
			DetectorPresencia.Estado.LISTO:
				if not DetectorPresencia.get_en_nivel():
					texto += "LISTA · SE ACTIVARÁ AL ENTRAR AL NIVEL"
				elif get_tree().paused:
					texto += "LISTA · SE ACTIVARÁ AL REANUDAR"
				else:
					texto += "LISTA"
			_:
				if get_tree().paused:
					texto += "SE ACTIVARÁ AL REANUDAR"
				elif not DetectorPresencia.get_en_nivel():
					texto += "SE ACTIVARÁ AL ENTRAR AL NIVEL"
				else:
					texto += "APAGADA"

	if _permiso_pendiente:
		texto = "CÁMARA: SOLICITANDO PERMISO…"
	elif estado in [
		DetectorPresencia.Estado.SIN_PERMISO,
		DetectorPresencia.Estado.NO_DISPONIBLE,
		DetectorPresencia.Estado.ERROR,
	]:
		var mensaje := DetectorPresencia.get_mensaje()
		if not mensaje.is_empty():
			texto = "CÁMARA: %s" % mensaje.to_upper()

	if OS.get_name() == "Linux" and Configuracion.pausa_camara and Configuracion.pausa_tiempo < 10:
		texto += " · SE RECOMIENDAN 10 s"

	estado_camara.text = texto + " · LA IMAGEN NO SE GUARDA"


func _camara_soportada() -> bool:
	return OS.has_feature("web") or OS.get_name() == "Linux"


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		cerrar()
		get_viewport().set_input_as_handled()
