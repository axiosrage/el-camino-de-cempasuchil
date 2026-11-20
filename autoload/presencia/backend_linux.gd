extends Node

## Backend de cámara para Linux usando CameraServer (V4L2).
## La presencia se estima con visión clásica: diferencia entre fotogramas
## reducidos, compensando los cambios globales de brillo.

signal estado_cambiado(estado: String, mensaje: String)
signal datos_actualizados(presencia: bool, confianza: float, latencia_ms: int, fps: float)
signal permiso_resultado(ok: bool, mensaje: String)

const ANCHO_MUESTRA := 64
const ALTO_MUESTRA := 48
const INTERVALO_CAPTURA_MS := 200
const UMBRAL_MOVIMIENTO := 0.08
const CUADROS_PARA_PRESENCIA := 2
const CUADROS_PARA_AUSENCIA := 3
const DIFERENCIA_PIXEL := 20
const CALENTAMIENTO_MS := 1500
const ESPERA_FEED_MS := 5000
const ESPERA_FRAME_MS := 3000

var _feed: CameraFeed
var _textura: CameraTexture
var _rect: TextureRect
var _capa: CanvasLayer
var _activo := false
var _estado := "apagado"
var _mensaje := ""
var _presencia := true
var _confianza := 0.0
var _latencia_ms := 0
var _fps := 0.0
var _anterior := PackedByteArray()
var _luma_anterior := 0.0
var _inicio_captura_ms := 0
var _ultima_captura_ms := 0
var _ultimo_frame_ms := 0
var _frames := 0
var _cuadros_movimiento := 0
var _cuadros_quieto := 0


func _ready() -> void:
	set_process(false)


func esta_activo() -> bool:
	return _activo


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
	return "Movimiento (CameraServer)"


func probar_permiso() -> void:
	_estado = "solicitando"
	_mensaje = "Buscando cámara…"
	estado_cambiado.emit(_estado, _mensaje)

	var ok := await _abrir_camara(false)
	if not ok:
		_estado = "no_disponible"
		_mensaje = "No se encontró una cámara utilizable."
		estado_cambiado.emit(_estado, _mensaje)
		permiso_resultado.emit(false, _mensaje)
		return

	await _cerrar_camara()
	_estado = "listo"
	_mensaje = "Cámara disponible."
	estado_cambiado.emit(_estado, _mensaje)
	permiso_resultado.emit(true, _mensaje)


func iniciar() -> void:
	if _activo:
		return

	_estado = "solicitando"
	_mensaje = "Iniciando cámara…"
	estado_cambiado.emit(_estado, _mensaje)

	var ok := await _abrir_camara(true)
	if not ok:
		_estado = "no_disponible"
		_mensaje = "No se pudo abrir la cámara."
		estado_cambiado.emit(_estado, _mensaje)
		return

	_activo = true
	_inicio_captura_ms = Time.get_ticks_msec()
	_ultima_captura_ms = 0
	_ultimo_frame_ms = _inicio_captura_ms
	_frames = 0
	_fps = 0.0
	_presencia = true
	_confianza = 0.0
	_cuadros_movimiento = 0
	_cuadros_quieto = 0
	_estado = "activo"
	_mensaje = ""
	estado_cambiado.emit(_estado, _mensaje)
	set_process(true)


func detener() -> void:
	if not _activo and _feed == null:
		_estado = "apagado"
		return
	await _cerrar_camara()
	_estado = "apagado"
	_mensaje = ""
	estado_cambiado.emit(_estado, _mensaje)


func liberar() -> void:
	await detener()
	if _capa != null:
		_capa.queue_free()
		_capa = null
		_rect = null


func _abrir_camara(_para_monitoreo: bool) -> bool:
	await _cerrar_camara()
	CameraServer.monitoring_feeds = true

	var inicio := Time.get_ticks_msec()
	var cantidad := 0
	while Time.get_ticks_msec() - inicio < ESPERA_FEED_MS:
		cantidad = CameraServer.get_feed_count()
		if cantidad > 0:
			break
		await get_tree().create_timer(0.1).timeout

	if cantidad == 0:
		CameraServer.monitoring_feeds = false
		return false

	var indice_formato := -1
	for i in cantidad:
		var feed := CameraServer.get_feed(i)
		var formato := _elegir_formato(feed)
		if formato >= 0:
			_feed = feed
			indice_formato = formato
			break

	if _feed == null:
		CameraServer.monitoring_feeds = false
		return false

	_feed.set_format(indice_formato, {})
	_feed.set_active(true)

	_textura = CameraTexture.new()
	_textura.camera_feed_id = _feed.get_id()
	_textura.which_feed = CameraServer.FEED_RGBA_IMAGE

	if _capa == null:
		_capa = CanvasLayer.new()
		_capa.layer = -100
		add_child(_capa)
		_rect = TextureRect.new()
		_rect.size = Vector2(2, 2)
		_rect.modulate = Color(1, 1, 1, 0.01)
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_capa.add_child(_rect)
	_rect.texture = _textura

	var inicio_frame := Time.get_ticks_msec()
	while Time.get_ticks_msec() - inicio_frame < ESPERA_FRAME_MS:
		var imagen := _textura.get_image()
		if imagen != null and not imagen.is_empty():
			_anterior = PackedByteArray()
			_luma_anterior = 0.0
			return true
		await get_tree().create_timer(0.1).timeout

	await _cerrar_camara()
	return false


func _cerrar_camara() -> void:
	set_process(false)
	_activo = false
	_presencia = false
	_confianza = 0.0
	_fps = 0.0
	_anterior = PackedByteArray()
	_luma_anterior = 0.0
	_cuadros_movimiento = 0
	_cuadros_quieto = 0

	if _rect != null:
		_rect.texture = null
	_textura = null
	if _feed != null:
		_feed.set_active(false)
		_feed = null

	if is_inside_tree():
		await get_tree().process_frame
	CameraServer.monitoring_feeds = false


func _elegir_formato(feed: CameraFeed) -> int:
	var formatos := feed.get_formats()
	if formatos.is_empty():
		return -1

	for i in formatos.size():
		var formato: Dictionary = formatos[i]
		if int(formato.get("width", 0)) == 640 \
				and int(formato.get("height", 0)) == 480 \
				and str(formato.get("format", "")).contains("YUYV"):
			return i

	for i in formatos.size():
		var formato: Dictionary = formatos[i]
		if str(formato.get("format", "")).contains("YUYV"):
			return i

	return 0


func _process(_delta: float) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - _ultima_captura_ms < INTERVALO_CAPTURA_MS:
		return
	_ultima_captura_ms = ahora

	if _textura == null:
		return

	var inicio := Time.get_ticks_msec()
	var imagen := _textura.get_image()
	if imagen == null or imagen.is_empty():
		return

	imagen.convert(Image.FORMAT_RGBA8)
	imagen.resize(ANCHO_MUESTRA, ALTO_MUESTRA, Image.INTERPOLATE_BILINEAR)
	var datos := imagen.get_data()

	var luma := 0.0
	var fraccion := 0.0
	if _anterior.size() == datos.size():
		var suma_luma := 0.0
		var cuenta := 0
		for i in range(0, datos.size(), 4):
			suma_luma += (datos[i] + datos[i + 1] + datos[i + 2]) / 3.0
			cuenta += 1
		luma = suma_luma / float(cuenta)

		var delta_global := 0.0
		if _luma_anterior > 0.0:
			delta_global = luma - _luma_anterior

		var cambiados := 0
		for i in range(0, datos.size(), 4):
			var dr := absi(clampi(int(datos[i] - delta_global), 0, 255) - _anterior[i])
			var dg := absi(clampi(int(datos[i + 1] - delta_global), 0, 255) - _anterior[i + 1])
			var db := absi(clampi(int(datos[i + 2] - delta_global), 0, 255) - _anterior[i + 2])
			if maxi(dr, maxi(dg, db)) > DIFERENCIA_PIXEL:
				cambiados += 1
		fraccion = float(cambiados) / float(cuenta)

		if ahora - _inicio_captura_ms >= CALENTAMIENTO_MS:
			if fraccion >= UMBRAL_MOVIMIENTO:
				_cuadros_movimiento += 1
				_cuadros_quieto = 0
			else:
				_cuadros_quieto += 1
				_cuadros_movimiento = 0

			if _cuadros_movimiento >= CUADROS_PARA_PRESENCIA:
				_presencia = true
			elif _cuadros_quieto >= CUADROS_PARA_AUSENCIA:
				_presencia = false

			_confianza = fraccion

	_luma_anterior = luma
	_anterior = datos
	_latencia_ms = Time.get_ticks_msec() - inicio

	_frames += 1
	var transcurrido := ahora - _ultimo_frame_ms
	if transcurrido >= 1000:
		_fps = _frames * 1000.0 / float(transcurrido)
		_frames = 0
		_ultimo_frame_ms = ahora

	datos_actualizados.emit(_presencia, _confianza, _latencia_ms, _fps)
