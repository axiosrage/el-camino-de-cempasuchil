extends Node

## Prueba de la máquina de estados de DetectorPresencia.
## Uso: godot --headless --path . pruebas/detector_test.tscn

var _pausas: Array[String] = []
var _reanudaciones: Array[String] = []
var _fallos: Array[String] = []
var _backend


func _ready() -> void:
	_backend = preload("res://pruebas/backend_falso.gd").new()
	DetectorPresencia.instalar_backend_para_prueba(_backend)
	DetectorPresencia.pausa_automatica_solicitada.connect(_on_pausa)
	DetectorPresencia.reanudacion_automatica_solicitada.connect(_on_reanudacion)

	Configuracion.set_pausa_tiempo(3)
	Configuracion.set_pausa_camara(true)
	DetectorPresencia.activar_en_nivel()

	await _esperar(0.5)
	_comprobar(DetectorPresencia.get_estado() == DetectorPresencia.Estado.ACTIVO, "cámara activa")

	# Sin entrada y sin presencia: debe pausar a los 3 s.
	_backend.emitir_presencia(false)
	await _esperar(4.2)
	_comprobar(_pausas.size() == 1, "pausa por presencia")
	_comprobar(DetectorPresencia.get_motivo_auto() == DetectorPresencia.MOTIVO_PRESENCIA, "motivo presencia")
	get_tree().paused = true

	# Regreso: 2 s de presencia para reanudar. La cámara real emite datos
	# cada ~200 ms, así que la prueba también los repite.
	for i in 11:
		_backend.emitir_presencia(true)
		await _esperar(0.25)
		print(
			"    t=", Time.get_ticks_msec(),
			" auto=", DetectorPresencia.get_auto_pausado(),
			" presencia=", DetectorPresencia.get_presencia(),
			" restante=", DetectorPresencia.get_restante_reanudacion(),
			" estado=", DetectorPresencia.get_estado_texto(),
			" backend_activo=", _backend.esta_activo()
		)
	_comprobar(_reanudaciones.size() == 1, "reanudación por presencia")
	get_tree().paused = false

	# Con una acción de juego mantenida no debe pausar.
	Input.action_press("salto")
	await _esperar(0.4)
	_backend.emitir_presencia(false)
	await _esperar(4.0)
	_comprobar(_pausas.size() == 1, "la entrada evita la pausa")
	Input.action_release("salto")

	# Al soltar, la cuenta vuelve a correr.
	await _esperar(3.8)
	_comprobar(_pausas.size() == 2, "pausa tras soltar la entrada")
	get_tree().paused = true
	DetectorPresencia.cancelar_automatico()
	get_tree().paused = false

	# Pausa por pérdida de foco y reanudación rápida.
	_backend.emitir_presencia(true)
	await _esperar(0.8)
	DetectorPresencia.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _esperar(0.2)
	_comprobar(_pausas.size() == 3, "pausa por foco")
	_comprobar(DetectorPresencia.get_motivo_auto() == DetectorPresencia.MOTIVO_FOCO, "motivo foco")
	get_tree().paused = true
	DetectorPresencia.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await _esperar(0.8)
	_comprobar(_reanudaciones.size() == 2, "reanudación por foco")
	get_tree().paused = false

	# Pausa manual: apaga la cámara; al reanudar debe volver a activarse.
	DetectorPresencia.detener_camara()
	await _esperar(0.2)
	_comprobar(not _backend.esta_activo(), "cámara apagada en pausa manual")
	DetectorPresencia.reanudar_camara()
	await _esperar(0.2)
	_comprobar(_backend.esta_activo(), "cámara reactivada al reanudar")

	DetectorPresencia.desactivar_en_nivel(true)
	Configuracion.set_pausa_camara(false)
	Configuracion.set_pausa_tiempo(5)
	if _fallos.is_empty():
		print("PRUEBA OK: pausas=%s reanudaciones=%s" % [_pausas, _reanudaciones])
	else:
		print("PRUEBA FALLIDA: %s (pausas=%s reanudaciones=%s)" % [_fallos, _pausas, _reanudaciones])
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _on_pausa(motivo: String) -> void:
	_pausas.append(motivo)
	print("  pausa automática: ", motivo, " t=", Time.get_ticks_msec())


func _on_reanudacion(motivo: String) -> void:
	_reanudaciones.append(motivo)
	print("  reanudación automática: ", motivo, " t=", Time.get_ticks_msec())


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		print("  OK: ", descripcion)
	else:
		_fallos.append(descripcion)
		print("  FALLO: ", descripcion)


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout
