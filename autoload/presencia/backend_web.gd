extends Node

## Backend de cámara para la exportación web.
## Todo ocurre en JavaScript: getUserMedia + MediaPipe Face Detector.
## GDScript solo consulta el estado y recibe los datos ya procesados.

signal estado_cambiado(estado: String, mensaje: String)
signal datos_actualizados(presencia: bool, confianza: float, latencia_ms: int, fps: float)
signal permiso_resultado(ok: bool, mensaje: String)

const INTERVALO_CONSULTA_MS := 200
const TIEMPO_MAXIMO_CARGA_MS := 12000

var _estado := "apagado"
var _mensaje := ""
var _presencia := false
var _confianza := 0.0
var _latencia_ms := 0
var _fps := 0.0
var _ultimo_poll_ms := 0
var _permiso_pendiente := false
var _inicio_solicitud_ms := 0
var _estado_js_anterior := ""


func _ready() -> void:
	set_process(false)


func esta_activo() -> bool:
	return _estado in ["solicitando", "cargando", "activo"]


func get_estado() -> String:
	return _estado


func get_mensaje() -> String:
	return _mensaje


func get_presencia() -> bool:
	return _presencia


func get_confianza() -> float:
	return _confianza


func get_latencia_ms() -> int:
	return _latencia_ms


func get_fps() -> float:
	return _fps


func get_nombre() -> String:
	return "MediaPipe Face Detector"


func probar_permiso() -> void:
	_estado = "solicitando"
	_mensaje = "Solicitando permiso…"
	_presencia = false
	_permiso_pendiente = true
	_inicio_solicitud_ms = Time.get_ticks_msec()
	estado_cambiado.emit(_estado, _mensaje)
	_llamar_js("solicitarPermiso")
	set_process(true)


func iniciar() -> void:
	if esta_activo():
		return

	_estado = "solicitando"
	_mensaje = "Iniciando cámara…"
	_inicio_solicitud_ms = Time.get_ticks_msec()
	estado_cambiado.emit(_estado, _mensaje)
	_llamar_js("iniciar")
	set_process(true)


func detener() -> void:
	_llamar_js("detener")
	set_process(false)
	_estado = "apagado"
	_mensaje = ""
	_presencia = false
	_confianza = 0.0
	_latencia_ms = 0
	_fps = 0.0
	_estado_js_anterior = ""
	estado_cambiado.emit(_estado, _mensaje)


func liberar() -> void:
	_llamar_js("liberar")
	set_process(false)
	_estado = "apagado"
	_mensaje = ""
	_presencia = false
	_confianza = 0.0
	_latencia_ms = 0
	_fps = 0.0
	_estado_js_anterior = ""


func _llamar_js(metodo: String) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(
		"if (window.PresenciaCamara) { window.PresenciaCamara.%s(); }" % metodo,
		true
	)


func _process(_delta: float) -> void:
	var ahora := Time.get_ticks_msec()

	if _permiso_pendiente and ahora - _inicio_solicitud_ms > TIEMPO_MAXIMO_CARGA_MS:
		_permiso_pendiente = false
		_estado = "error"
		_mensaje = "La cámara no respondió. Revisa el navegador."
		estado_cambiado.emit(_estado, _mensaje)
		permiso_resultado.emit(false, _mensaje)
		set_process(false)
		return

	if ahora - _ultimo_poll_ms < INTERVALO_CONSULTA_MS:
		return
	_ultimo_poll_ms = ahora

	var crudo = JavaScriptBridge.eval(
		"window.PresenciaCamara ? window.PresenciaCamara.estadoJSON() : ''",
		true
	)
	if typeof(crudo) != TYPE_STRING or String(crudo).is_empty():
		return

	var datos = JSON.parse_string(String(crudo))
	if typeof(datos) != TYPE_DICTIONARY:
		return

	var estado_js := str(datos.get("estado", "error"))
	var mensaje := str(datos.get("mensaje", ""))
	var presencia := bool(datos.get("presencia", false))
	var confianza := float(datos.get("confianza", 0.0))
	var latencia := int(datos.get("latencia_ms", 0))
	var fps := float(datos.get("fps", 0.0))

	_presencia = presencia
	_confianza = confianza
	_latencia_ms = latencia
	_fps = fps
	_mensaje = mensaje

	if estado_js != _estado_js_anterior:
		_estado_js_anterior = estado_js
		_estado = estado_js
		estado_cambiado.emit(_estado, _mensaje)

	if _permiso_pendiente:
		if estado_js == "listo" or estado_js == "activo":
			_permiso_pendiente = false
			_estado = "listo"
			_mensaje = "Permiso concedido."
			estado_cambiado.emit(_estado, _mensaje)
			permiso_resultado.emit(true, _mensaje)
			set_process(false)
		elif estado_js in ["sin_permiso", "no_disponible", "error"]:
			_permiso_pendiente = false
			permiso_resultado.emit(false, _mensaje)
			set_process(false)

	if estado_js == "activo":
		datos_actualizados.emit(presencia, confianza, latencia, fps)
