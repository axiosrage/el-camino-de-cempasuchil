extends Node

## Detecta si hay alguien frente a la pantalla y avisa a la pausa.
## Capa común para web (MediaPipe) y Linux (movimiento con CameraServer).
## También vigila la pérdida de foco como respaldo universal.

signal estado_cambiado(estado: int)
signal pausa_automatica_solicitada(motivo: String)
signal reanudacion_automatica_solicitada(motivo: String)
signal permiso_resultado(ok: bool, mensaje: String)

enum Estado { APAGADO, SOLICITANDO, LISTO, ACTIVO, SIN_PERMISO, NO_DISPONIBLE, ERROR }

const MOTIVO_PRESENCIA := "presencia"
const MOTIVO_FOCO := "foco"

const RETENCION_PRESENCIA_MS := 600
const REANUDACION_PRESENCIA_MS := 2000
const REANUDACION_FOCO_MS := 400
const AVISO_RESTANTE_MS := 2000
const INTERVALO_FOCO_MS := 250

var _backend: Node = null
var _backend_forzado: Node = null
var _estado := Estado.APAGADO
var _estado_backend := "apagado"
var _mensaje_backend := ""

var _en_nivel := false
var _auto_pausado := false
var _motivo_auto := ""
var _foco_perdido := false
var _foco_recuperado_desde_ms := 0

var _ultimo_input_ms := 0
var _ultima_presencia_ms := 0
var _sin_presencia_desde_ms := 0
var _presencia := true
var _confianza := 0.0
var _latencia_ms := 0
var _fps := 0.0

var _reanudacion_desde_ms := 0
var _restante_reanudacion := 0.0
var _aviso_visible := false
var _restante_pausa := 0.0
var _ultimo_chequeo_foco_ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ultimo_input_ms = Time.get_ticks_msec()
	_ultima_presencia_ms = _ultimo_input_ms
	Configuracion.pausa_cambiada.connect(_on_config_pausa_cambiada)


func _exit_tree() -> void:
	_detener_backend()
	if _backend != null:
		_backend.liberar()
		_backend = null


func activar_en_nivel() -> void:
	var ahora := Time.get_ticks_msec()
	_en_nivel = true
	_auto_pausado = false
	_motivo_auto = ""
	_foco_perdido = false
	_foco_recuperado_desde_ms = 0
	_reanudacion_desde_ms = 0
	_restante_reanudacion = 0.0
	_aviso_visible = false
	_restante_pausa = 0.0
	_ultimo_input_ms = ahora
	_ultima_presencia_ms = ahora
	_sin_presencia_desde_ms = 0
	_presencia = true

	if Configuracion.pausa_camara:
		_asegurar_backend()
		if _backend != null and not _backend.esta_activo():
			_backend.iniciar()
	else:
		_detener_backend()
		_estado = Estado.APAGADO
		estado_cambiado.emit(_estado)


func desactivar_en_nivel(liberar_backend: bool = false) -> void:
	_en_nivel = false
	_auto_pausado = false
	_motivo_auto = ""
	_foco_perdido = false
	_foco_recuperado_desde_ms = 0
	_reanudacion_desde_ms = 0
	_restante_reanudacion = 0.0
	_aviso_visible = false
	_restante_pausa = 0.0
	_detener_backend()
	if liberar_backend:
		if _backend != null:
			_backend.liberar()
			_backend.queue_free()
			_backend = null
		_estado = Estado.APAGADO
		estado_cambiado.emit(_estado)


func solicitar_permiso() -> void:
	_asegurar_backend()
	if _backend == null:
		permiso_resultado.emit(false, "La cámara no está disponible.")
		return
	_backend.probar_permiso()


func detener_camara() -> void:
	_detener_backend()
	_estado = Estado.APAGADO
	estado_cambiado.emit(_estado)


## Reactiva la cámara si la opción está encendida. Se usa al volver de una
## pausa manual; si la cámara ya estaba activa (pausa automática) no hace nada.
func reanudar_camara() -> void:
	if not _en_nivel or not Configuracion.pausa_camara:
		return
	if get_tree().paused:
		return
	_asegurar_backend()
	if _backend != null and not _backend.esta_activo():
		_backend.iniciar()


func cancelar_automatico() -> void:
	_auto_pausado = false
	_motivo_auto = ""
	_reanudacion_desde_ms = 0
	_restante_reanudacion = 0.0
	_foco_recuperado_desde_ms = 0


func _asegurar_backend() -> void:
	if _backend != null:
		return
	if _backend_forzado != null:
		_backend = _backend_forzado
	else:
		if OS.has_feature("web"):
			_backend = preload("res://autoload/presencia/backend_web.gd").new()
		elif OS.get_name() == "Linux":
			_backend = preload("res://autoload/presencia/backend_linux.gd").new()
		else:
			_backend = preload("res://autoload/presencia/backend_nulo.gd").new()

	if _backend.get_parent() == null:
		add_child(_backend)

	if not _backend.estado_cambiado.is_connected(_on_backend_estado):
		_backend.estado_cambiado.connect(_on_backend_estado)
	if not _backend.datos_actualizados.is_connected(_on_backend_datos):
		_backend.datos_actualizados.connect(_on_backend_datos)
	if not _backend.permiso_resultado.is_connected(_on_permiso_resultado):
		_backend.permiso_resultado.connect(_on_permiso_resultado)


func _detener_backend() -> void:
	if _backend != null:
		_backend.detener()
		_estado_backend = "apagado"


func _on_backend_estado(estado: String, mensaje: String) -> void:
	_estado_backend = estado
	_mensaje_backend = mensaje
	_estado = _mapear_estado(estado)
	if estado == "activo":
		var ahora := Time.get_ticks_msec()
		_ultima_presencia_ms = ahora
		_sin_presencia_desde_ms = 0
		_presencia = true
	estado_cambiado.emit(_estado)


func _on_backend_datos(presencia: bool, confianza: float, latencia_ms: int, fps: float) -> void:
	_confianza = confianza
	_latencia_ms = latencia_ms
	_fps = fps
	if presencia:
		_ultima_presencia_ms = Time.get_ticks_msec()


func _on_permiso_resultado(ok: bool, mensaje: String) -> void:
	permiso_resultado.emit(ok, mensaje)


func _mapear_estado(estado: String) -> Estado:
	match estado:
		"apagado":
			return Estado.APAGADO
		"solicitando", "cargando":
			return Estado.SOLICITANDO
		"listo":
			return Estado.LISTO
		"activo":
			return Estado.ACTIVO
		"sin_permiso":
			return Estado.SIN_PERMISO
		"no_disponible":
			return Estado.NO_DISPONIBLE
		_:
			return Estado.ERROR


func _input(event: InputEvent) -> void:
	if event is InputEventKey \
			or event is InputEventMouseButton \
			or event is InputEventMouseMotion \
			or event is InputEventJoypadButton \
			or event is InputEventJoypadMotion \
			or event is InputEventScreenTouch:
		_ultimo_input_ms = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	var ahora := Time.get_ticks_msec()

	if _accion_juego_presionada():
		_ultimo_input_ms = ahora

	_actualizar_presencia(ahora)
	_actualizar_aviso(ahora)
	_actualizar_reanudacion(ahora)
	_actualizar_foco_web(ahora)


func _accion_juego_presionada() -> bool:
	return (
		Input.is_action_pressed("mov_izquierda")
		or Input.is_action_pressed("mov_derecha")
		or Input.is_action_pressed("salto")
		or Input.is_action_pressed("lanzar")
	)


func _actualizar_presencia(ahora: int) -> void:
	if not _en_nivel or not Configuracion.pausa_camara:
		_presencia = true
		_sin_presencia_desde_ms = 0
		return
	if get_tree().paused and not _auto_pausado:
		_presencia = true
		_sin_presencia_desde_ms = 0
		return

	if _estado_backend != "activo":
		# La cámara todavía no está lista: no se cuenta como ausencia.
		_presencia = true
		_ultima_presencia_ms = ahora
		_sin_presencia_desde_ms = 0
		return

	_presencia = (ahora - _ultima_presencia_ms) <= RETENCION_PRESENCIA_MS

	if _presencia:
		_sin_presencia_desde_ms = 0
		return

	if _sin_presencia_desde_ms == 0:
		_sin_presencia_desde_ms = ahora
		return

	if _auto_pausado:
		return

	var tiempo_ms := Configuracion.pausa_tiempo * 1000
	var sin_presencia := ahora - _sin_presencia_desde_ms
	var sin_entrada := ahora - _ultimo_input_ms
	if sin_presencia >= tiempo_ms and sin_entrada >= tiempo_ms:
		_solicitar_pausa_automatica(MOTIVO_PRESENCIA)


func _actualizar_aviso(ahora: int) -> void:
	if not _en_nivel or not Configuracion.pausa_camara or _auto_pausado or get_tree().paused:
		_ocultar_aviso()
		return
	if _estado_backend != "activo":
		_ocultar_aviso()
		return
	if _sin_presencia_desde_ms == 0:
		_ocultar_aviso()
		return

	var tiempo_ms := Configuracion.pausa_tiempo * 1000
	var sin_presencia := ahora - _sin_presencia_desde_ms
	var sin_entrada := ahora - _ultimo_input_ms
	var restante := mini(tiempo_ms - sin_presencia, tiempo_ms - sin_entrada)
	if restante > 0 and restante <= AVISO_RESTANTE_MS:
		_aviso_visible = true
		_restante_pausa = restante / 1000.0
	else:
		_ocultar_aviso()


func _ocultar_aviso() -> void:
	_aviso_visible = false
	_restante_pausa = 0.0


func _actualizar_reanudacion(ahora: int) -> void:
	if not _auto_pausado:
		_reanudacion_desde_ms = 0
		_restante_reanudacion = 0.0
		return

	if _motivo_auto == MOTIVO_FOCO:
		if _foco_recuperado_desde_ms > 0 \
				and ahora - _foco_recuperado_desde_ms >= REANUDACION_FOCO_MS:
			_reanudar_automatico(MOTIVO_FOCO)
		return

	if _motivo_auto != MOTIVO_PRESENCIA:
		return

	if not _presencia:
		_reanudacion_desde_ms = 0
		_restante_reanudacion = 0.0
		return

	if _reanudacion_desde_ms == 0:
		_reanudacion_desde_ms = ahora

	var transcurrido := ahora - _reanudacion_desde_ms
	_restante_reanudacion = maxf(0.0, (REANUDACION_PRESENCIA_MS - transcurrido) / 1000.0)
	if transcurrido >= REANUDACION_PRESENCIA_MS:
		_reanudar_automatico(MOTIVO_PRESENCIA)


func _solicitar_pausa_automatica(motivo: String) -> void:
	if _auto_pausado or get_tree().paused:
		return
	_auto_pausado = true
	_motivo_auto = motivo
	_reanudacion_desde_ms = 0
	_restante_reanudacion = 0.0
	_ocultar_aviso()
	pausa_automatica_solicitada.emit(motivo)


func _reanudar_automatico(motivo: String) -> void:
	if not _auto_pausado or _motivo_auto != motivo:
		return
	_auto_pausado = false
	_motivo_auto = ""
	_reanudacion_desde_ms = 0
	_restante_reanudacion = 0.0
	reanudacion_automatica_solicitada.emit(motivo)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_al_perder_foco()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_al_recuperar_foco()
		NOTIFICATION_WM_CLOSE_REQUEST:
			desactivar_en_nivel(true)


func _al_perder_foco() -> void:
	if not _en_nivel or not Configuracion.pausa_foco:
		return
	if _auto_pausado:
		return
	_foco_perdido = true
	_foco_recuperado_desde_ms = 0
	_solicitar_pausa_automatica(MOTIVO_FOCO)


func _al_recuperar_foco() -> void:
	_foco_perdido = false
	if not _auto_pausado or _motivo_auto != MOTIVO_FOCO:
		return
	_foco_recuperado_desde_ms = Time.get_ticks_msec()


func _actualizar_foco_web(ahora: int) -> void:
	if not OS.has_feature("web"):
		return
	if not _en_nivel:
		return
	if ahora - _ultimo_chequeo_foco_ms < INTERVALO_FOCO_MS:
		return
	_ultimo_chequeo_foco_ms = ahora

	var enfocado := DisplayServer.window_is_focused()
	if not enfocado and not _foco_perdido:
		_al_perder_foco()
	elif enfocado and _foco_perdido:
		_al_recuperar_foco()


func _on_config_pausa_cambiada() -> void:
	if not _en_nivel:
		return
	if Configuracion.pausa_camara:
		if get_tree().paused:
			# Se activará al reanudar; durante el menú no usamos la cámara.
			return
		_asegurar_backend()
		if _backend != null and not _backend.esta_activo():
			_backend.iniciar()
	else:
		_detener_backend()
		_estado = Estado.APAGADO
		estado_cambiado.emit(_estado)


func instalar_backend_para_prueba(backend: Node) -> void:
	_backend_forzado = backend
	_backend = backend
	if backend.get_parent() == null:
		add_child(backend)
	if not backend.estado_cambiado.is_connected(_on_backend_estado):
		backend.estado_cambiado.connect(_on_backend_estado)
	if not backend.datos_actualizados.is_connected(_on_backend_datos):
		backend.datos_actualizados.connect(_on_backend_datos)
	if not backend.permiso_resultado.is_connected(_on_permiso_resultado):
		backend.permiso_resultado.connect(_on_permiso_resultado)


# --- Consultas para la interfaz y la depuración ---

func get_estado() -> Estado:
	return _estado


func get_estado_texto() -> String:
	match _estado:
		Estado.APAGADO:
			return "APAGADA"
		Estado.SOLICITANDO:
			return "SOLICITANDO"
		Estado.LISTO:
			return "LISTA"
		Estado.ACTIVO:
			return "ACTIVA"
		Estado.SIN_PERMISO:
			return "PERMISO DENEGADO"
		Estado.NO_DISPONIBLE:
			return "NO DISPONIBLE"
		_:
			return "ERROR"


func get_mensaje() -> String:
	return _mensaje_backend


func get_backend_nombre() -> String:
	if _backend != null and _backend.has_method("get_nombre"):
		return _backend.get_nombre()
	return "Sin cámara"


func get_presencia() -> bool:
	return _presencia


func get_confianza() -> float:
	return _confianza


func get_latencia_ms() -> int:
	return _latencia_ms


func get_fps() -> float:
	return _fps


func get_segundos_sin_presencia() -> float:
	if _sin_presencia_desde_ms == 0:
		return 0.0
	return (Time.get_ticks_msec() - _sin_presencia_desde_ms) / 1000.0


func get_segundos_sin_entrada() -> float:
	return (Time.get_ticks_msec() - _ultimo_input_ms) / 1000.0


func get_restante_pausa() -> float:
	return _restante_pausa


func get_aviso_visible() -> bool:
	return _aviso_visible


func get_restante_reanudacion() -> float:
	return _restante_reanudacion


func get_auto_pausado() -> bool:
	return _auto_pausado


func get_motivo_auto() -> String:
	return _motivo_auto


func get_en_nivel() -> bool:
	return _en_nivel


func get_tiempo_pausa() -> int:
	return Configuracion.pausa_tiempo
