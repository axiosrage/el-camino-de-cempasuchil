extends Node

const NIVEL = preload("res://escenas/Nivel1.tscn")

const VELAS = [
	{"pos": Vector2(494.0, 512.0), "nombre": "vela_494"},
	{"pos": Vector2(1678.0, 448.0), "nombre": "vela_1678"},
	{"pos": Vector2(4976.0, 416.0), "nombre": "vela_4976"},
	{"pos": Vector2(7378.0, 192.0), "nombre": "vela_7378"},
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size = Vector2i(1152, 648)
	# Sin pausas automáticas: la ventana de Xvfb nunca tiene el foco.
	Configuracion.pausa_camara = false
	Configuracion.pausa_foco = false
	get_tree().paused = false
	EstadoJuego.reiniciar_estado()
	EstadoJuego.slot_activo = 0

	var nivel = NIVEL.instantiate()
	add_child(nivel)
	await get_tree().process_frame
	await get_tree().physics_frame

	var player = nivel.get_node("%Player")
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	player.visible = false

	for vela in VELAS:
		await _capturar(player, vela["pos"] + Vector2(0, -24), vela["nombre"])

	await _capturar(player, Vector2(13370, 420), "flor")

	player.visible = true
	await _capturar(player, Vector2(13535, 420), "final_escena")

	var flor = nivel.get("_flor_final")
	player.global_position = flor.global_position
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.35).timeout
	await _capturar(player, Vector2(13535, 420), "portal_activo")

	var portal = nivel.get("_portal_final")
	player.global_position = portal.global_position
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(3.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/opencode/captura_final.png")
	print("capturas listas")

	get_tree().paused = false
	get_tree().quit()


func _capturar(player, posicion: Vector2, nombre: String) -> void:
	player.global_position = posicion
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/opencode/captura_%s.png" % nombre)
