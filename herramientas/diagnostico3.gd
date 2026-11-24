extends Node

const NIVEL = preload("res://escenas/Nivel1.tscn")


func _ready() -> void:
	EstadoJuego.reiniciar_estado()
	EstadoJuego.slot_activo = 0

	var nivel = NIVEL.instantiate()
	add_child(nivel)
	await get_tree().process_frame
	await get_tree().physics_frame

	var agua: TileMapLayer = nivel.get_node("agua")
	print("agua collision_enabled=", agua.get("collision_enabled"))
	var area: Area2D = agua.get_node("Area2D")
	print("area layer=", area.collision_layer, " mask=", area.collision_mask, " formas=", area.get_child_count())
	for hijo in area.get_children():
		if hijo is CollisionShape2D:
			var forma: RectangleShape2D = hijo.shape
			print("  forma pos=", hijo.position, " size=", forma.size)

	var velas: Node2D = nivel.get_node("Velas")
	print("velas=", velas.get_child_count())
	var posiciones: Array[float] = []
	for vela in velas.get_children():
		posiciones.append(vela.position.x)
		print("  vela x=", vela.position.x, " y=", vela.position.y, " fase=", vela.get("fase"))
	posiciones.sort()
	var min_sep := INF
	for i in range(1, posiciones.size()):
		min_sep = minf(min_sep, posiciones[i] - posiciones[i - 1])
	print("separacion minima=", min_sep)

	var flor = nivel.get("_flor_final")
	var portal = nivel.get("_portal_final")
	print("flor=", flor.position if flor != null else "null")
	print("portal=", portal.position if portal != null else "null", " activo=", portal.get("activo") if portal != null else "?")
	print("Musica pista=", Musica.pista_actual(), " playing=", Musica.esta_reproduciendo())

	get_tree().quit()
