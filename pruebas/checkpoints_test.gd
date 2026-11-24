extends Node

## Prueba de los puntos de guardado fijos y de la regla de reaparición:
## solo se reinicia el nivel completo cuando se pierde el último corazón.
## Uso: godot --headless --path . pruebas/checkpoints_test.tscn

const NIVEL = preload("res://escenas/Nivel1.tscn")

var _fallos: Array[String] = []
var _nivel: Node2D


func _ready() -> void:
	await get_tree().process_frame
	Configuracion.pausa_camara = false
	Configuracion.pausa_foco = false
	EstadoJuego.reiniciar_estado()
	EstadoJuego.slot_activo = 0

	_nivel = NIVEL.instantiate()
	add_child(_nivel)
	await get_tree().process_frame
	await get_tree().physics_frame

	var puntos: Array = _nivel.get("_puntos_checkpoint")
	_comprobar(puntos.size() >= 6, "hay puntos de guardado repartidos por el nivel")

	var todos_seguros := true
	for punto in puntos:
		if not bool(_nivel.call("_es_punto_seguro", punto)):
			todos_seguros = false
	_comprobar(todos_seguros, "todos los puntos están sobre suelo firme y fuera del agua")

	var indice_inicial := int(_nivel.get("_indice_checkpoint"))
	_comprobar(
		EstadoJuego.checkpoint_posicion.distance_to(puntos[indice_inicial]) < 1.0,
		"el checkpoint inicial corresponde a la posición de aparición"
	)

	# Al superar un punto fijo, el guardado pasa a ese punto.
	_nivel.set("_indice_checkpoint", 0)
	var objetivo: Vector2 = puntos[1]
	var jugador = _nivel.get_node("%Player")
	jugador.global_position = objetivo + Vector2(0.0, -4.0)
	jugador.velocity = Vector2.ZERO
	var t0 := Time.get_ticks_msec()
	while not jugador.is_on_floor() and Time.get_ticks_msec() - t0 < 4000:
		await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout
	_comprobar(int(_nivel.get("_indice_checkpoint")) == 1, "se activa el punto alcanzado")
	_comprobar(
		EstadoJuego.checkpoint_posicion.distance_to(objetivo) < 1.0,
		"el checkpoint guardado es el punto alcanzado"
	)

	EstadoJuego.vida_media = 2
	EstadoJuego.registrar_jade("jade_prueba")
	EstadoJuego.registrar_flor()
	_comprobar(not bool(_nivel.call("_debe_reiniciar_completo")), "una muerte pequeña no reinicia el nivel")
	EstadoJuego.respawn_en_ultimo_suelo()
	_comprobar(EstadoJuego.respawn_en_checkpoint, "la muerte pequeña reaparece en el checkpoint")
	_comprobar(not EstadoJuego.reinicio_completo, "la muerte pequeña conserva jades y flor")
	_comprobar(
		EstadoJuego.vida_media == 2 and EstadoJuego.jades_recogidos == 1 and EstadoJuego.flor_recogida,
		"la muerte pequeña conserva vida, jades y flor"
	)

	EstadoJuego.respawn_en_checkpoint = false
	EstadoJuego.vida_media = 0
	_comprobar(bool(_nivel.call("_debe_reiniciar_completo")), "perder el último corazón reinicia el nivel")
	EstadoJuego.reiniciar_nivel_completo()
	_comprobar(EstadoJuego.reinicio_completo, "el reinicio completo se marca correctamente")
	_comprobar(EstadoJuego.checkpoint_posicion == Vector2.ZERO, "el reinicio completo borra el checkpoint")
	_comprobar(
		EstadoJuego.vida_media == EstadoJuego.vida_maxima_media
		and EstadoJuego.jades_recogidos == 0
		and not EstadoJuego.flor_recogida,
		"el reinicio completo devuelve la vida y borra jades y flor"
	)

	_nivel.queue_free()
	await get_tree().process_frame

	# Al recargar desde un checkpoint (muerte pequeña o partida guardada),
	# el perro debe aparecer junto al niño y seguir acompañándolo.
	EstadoJuego.reiniciar_estado()
	EstadoJuego.slot_activo = 0
	EstadoJuego.partida_cargada = true
	EstadoJuego.checkpoint_posicion = puntos[3]
	var recargado = NIVEL.instantiate()
	add_child(recargado)
	await get_tree().process_frame
	await get_tree().physics_frame

	var jugador_recargado = recargado.get_node("%Player")
	var perro = recargado.get_node("PerroAcompañante")
	_comprobar(
		jugador_recargado.global_position.distance_to(puntos[3]) < 2.0,
		"el jugador reaparece en el checkpoint"
	)
	_comprobar(
		absf(perro.global_position.x - jugador_recargado.global_position.x) < 80.0,
		"el perro reaparece junto al jugador"
	)
	_comprobar(
		bool(recargado.call("_es_punto_seguro", perro.global_position)),
		"el perro reaparece sobre suelo firme y fuera del agua"
	)
	_comprobar(bool(perro.get("activo")) and perro.get("player") == jugador_recargado, "el perro sigue al jugador tras reaparecer")
	_comprobar(bool(perro.get("mantener_con_jugador")), "el perro no se despide tras reaparecer")

	recargado.queue_free()
	await get_tree().process_frame

	if _fallos.is_empty():
		print("PRUEBA CHECKPOINTS OK")
	else:
		print("PRUEBA CHECKPOINTS FALLIDA: ", _fallos)
	get_tree().quit(1 if not _fallos.is_empty() else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK: ", mensaje)
	else:
		_fallos.append(mensaje)
		print("  FALLO: ", mensaje)
