extends Node

## Prueba de los controles táctiles: inyectan las mismas acciones del InputMap
## que teclado y mando, mueven al jugador real y abren/cierran la pausa.
## Uso: godot --headless --path . pruebas/controles_tactiles_test.tscn

const NIVEL = preload("res://escenas/Nivel1.tscn")

var _fallos: Array[String] = []
var _nivel
var _controles
var _camara_original: bool
var _foco_original: bool


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame

	_camara_original = Configuracion.pausa_camara
	_foco_original = Configuracion.pausa_foco
	Configuracion.pausa_camara = false
	Configuracion.pausa_foco = false

	_nivel = NIVEL.instantiate()
	add_child(_nivel)
	await get_tree().process_frame
	await get_tree().physics_frame

	_controles = _nivel.get("_controles_tactiles")
	_comprobar(_controles != null, "el nivel crea los controles táctiles")
	if _controles == null:
		await _terminar()
		return

	_controles.visible = true
	for nombre in ["Izquierda", "Derecha", "Salto", "Lanzar", "Pausa"]:
		_comprobar(_controles.get_node("Zona/" + nombre) != null, "existe el botón %s" % nombre)

	var boton_izq: Button = _controles.get_node("Zona/Izquierda")
	var boton_der: Button = _controles.get_node("Zona/Derecha")
	var boton_salto: Button = _controles.get_node("Zona/Salto")
	var boton_lanzar: Button = _controles.get_node("Zona/Lanzar")
	var boton_pausa: Button = _controles.get_node("Zona/Pausa")

	# Movimiento izquierdo mantenido.
	var jugador = _nivel.get_node("%Player")
	var x_inicial: float = jugador.global_position.x
	boton_izq.button_down.emit()
	await get_tree().physics_frame
	_comprobar(Input.is_action_pressed("mov_izquierda"), "IZQ mantiene la acción mov_izquierda")
	for i in range(12):
		await get_tree().physics_frame
	_comprobar(jugador.global_position.x < x_inicial - 5.0, "IZQ mueve al jugador a la izquierda")

	# Se pueden mantener dos botones a la vez (moverse y saltar).
	boton_salto.button_down.emit()
	await get_tree().physics_frame
	_comprobar(Input.is_action_pressed("salto"), "SALTO mantiene la acción salto")
	_comprobar(Input.is_action_pressed("mov_izquierda"), "SALTO no suelta IZQ")
	boton_izq.button_up.emit()
	boton_salto.button_up.emit()
	await get_tree().physics_frame
	_comprobar(not Input.is_action_pressed("mov_izquierda"), "soltar IZQ libera la acción")
	_comprobar(not Input.is_action_pressed("salto"), "soltar SALTO libera la acción")

	# Derecha y lanzar.
	boton_der.button_down.emit()
	await get_tree().physics_frame
	_comprobar(Input.is_action_pressed("mov_derecha"), "DER mantiene la acción mov_derecha")
	boton_der.button_up.emit()
	boton_lanzar.button_down.emit()
	await get_tree().physics_frame
	_comprobar(Input.is_action_pressed("lanzar"), "LANZAR mantiene la acción lanzar")
	boton_lanzar.button_up.emit()
	await get_tree().physics_frame
	_comprobar(not Input.is_action_pressed("lanzar"), "soltar LANZAR libera la acción")

	# Pausa: pulso corto que abre y cierra el menú existente del nivel.
	var menu_pausa = _nivel.get_node("Pausa")
	boton_pausa.button_down.emit()
	await _esperar_input()
	_comprobar(get_tree().paused, "PAUSA pausa el juego")
	_comprobar(menu_pausa.visible, "PAUSA abre el menú de pausa")

	boton_pausa.button_down.emit()
	await _esperar_input()
	_comprobar(not get_tree().paused, "PAUSA vuelve a reanudar el juego")
	_comprobar(not menu_pausa.visible, "PAUSA cierra el menú de pausa")

	# Al soltar todo, ninguna acción queda pegada.
	_controles.liberar_todo()
	await get_tree().process_frame
	for accion in ["mov_izquierda", "mov_derecha", "salto", "lanzar"]:
		_comprobar(not Input.is_action_pressed(accion), "liberar_todo suelta %s" % accion)

	await _terminar()


func _terminar() -> void:
	if _controles != null and is_instance_valid(_controles):
		_controles.liberar_todo()
	get_tree().paused = false
	if _nivel != null and is_instance_valid(_nivel):
		_nivel.queue_free()
	await get_tree().process_frame
	Configuracion.pausa_camara = _camara_original
	Configuracion.pausa_foco = _foco_original

	if _fallos.is_empty():
		print("PRUEBA CONTROLES TÁCTILES OK")
	else:
		print("PRUEBA CONTROLES TÁCTILES FALLIDA: %s" % [_fallos])
	get_tree().quit(0 if _fallos.is_empty() else 1)


## Los eventos inyectados con Input.parse_input_event se entregan en una o dos
## frames según el estado del bucle, así que se espera un margen corto.
func _esperar_input() -> void:
	for i in range(3):
		await get_tree().process_frame


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK: ", mensaje)
	else:
		_fallos.append(mensaje)
