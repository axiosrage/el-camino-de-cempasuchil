extends Node

## Prueba del cruce final: el agua sostiene la tabla, el niño se monta sin
## ahogarse y salta a tierra firme cuando la tabla se detiene.
## Uso: godot --headless --path . pruebas/perro_agua_test.tscn

const NIVEL = preload("res://escenas/Nivel1.tscn")
const X_ORILLA: float = 13344.0

var _fallos: Array[String] = []
var _nivel: Node2D
var _murio_agua: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	Configuracion.pausa_camara = false
	Configuracion.pausa_foco = false
	EstadoJuego.reiniciar_estado()
	EstadoJuego.slot_activo = 0

	_nivel = NIVEL.instantiate()
	add_child(_nivel)
	await get_tree().process_frame
	await get_tree().physics_frame

	var agua: TileMapLayer = _nivel.get_node("agua")
	_comprobar(
		agua.get("collision_enabled") == true,
		"el agua conserva la colisión sólida"
	)

	var jugador = _nivel.get_node("%Player")
	var contenedor = _nivel.get_node("ContenedorPerroEscape")
	var tabla = contenedor.get_node("PlataformaTronco")
	# La prueba no depende de dónde esté colocado el Player en la escena:
	# lo llevamos al punto desde el que se aborda la tabla del perro.
	jugador.global_position = Vector2(12011.0, 434.0)
	jugador.velocity = Vector2.ZERO
	jugador.montado_en_tronco = false
	jugador.ignorar_agua = false
	jugador.murio.connect(func(causa): _murio_agua = causa == "agua")

	await get_tree().create_timer(0.3).timeout
	_comprobar(
		tabla.global_position.y > 455.0 and tabla.global_position.y < 470.0,
		"la tabla flota en la superficie (y=%.1f)" % tabla.global_position.y
	)

	_accion("mov_derecha", true)
	var montado := false
	var limite := Time.get_ticks_msec() + 8000
	while not montado and Time.get_ticks_msec() < limite:
		await get_tree().physics_frame
		montado = jugador.montado_en_tronco
	_accion("mov_derecha", false)
	_comprobar(montado and not _murio_agua, "el niño se sube a la tabla sin ahogarse")

	var bajado := false
	var estrellado := false
	limite = Time.get_ticks_msec() + 45000
	var siguiente_impulso := Time.get_ticks_msec() + 1000
	while not bajado and not estrellado and Time.get_ticks_msec() < limite:
		var ahora := Time.get_ticks_msec()
		if ahora >= siguiente_impulso:
			_accion("salto", true)
			siguiente_impulso = ahora + 1000
		else:
			_accion("salto", false)
		await get_tree().physics_frame
		bajado = not jugador.montado_en_tronco
		estrellado = _murio_agua
	_accion("salto", false)
	_comprobar(not estrellado, "el niño no se ahoga mientras cruza en la tabla")
	_comprobar(bajado, "la tabla deja bajar al niño al final del recorrido")

	limite = Time.get_ticks_msec() + 4000
	while not jugador.is_on_floor() and not _murio_agua and Time.get_ticks_msec() < limite:
		await get_tree().physics_frame
	_comprobar(not _murio_agua, "el salto final no cae al agua")
	_comprobar(jugador.is_on_floor(), "el niño aterriza en tierra firme")
	_comprobar(
		jugador.global_position.x >= X_ORILLA,
		"el aterrizaje queda más allá del agua (x=%.1f)" % jugador.global_position.x
	)

	if _fallos.is_empty():
		print("PRUEBA PERRO AGUA OK")
	else:
		print("PRUEBA PERRO AGUA FALLIDA: ", _fallos)
	get_tree().quit(1 if not _fallos.is_empty() else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK: ", mensaje)
	else:
		_fallos.append(mensaje)
		print("  FALLO: ", mensaje)


func _accion(nombre: String, presionada: bool) -> void:
	var evento := InputEventAction.new()
	evento.action = nombre
	evento.pressed = presionada
	Input.parse_input_event(evento)
