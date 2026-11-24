extends Node

const NIVEL = preload("res://escenas/Nivel1.tscn")


func _ready() -> void:
	var nivel = NIVEL.instantiate()
	add_child(nivel)
	await get_tree().process_frame

	print("=== NODOS ===")
	for n in nivel.get_children():
		var extra := ""
		if n is Node2D:
			extra = " pos=%s" % n.position
		print("- ", n.name, " (", n.get_class(), ")", extra)

	print("=== TILEMAPS ===")
	for nombre in ["Nivel", "Decoracion", "agua"]:
		var mapa: TileMapLayer = nivel.get_node(nombre)
		var rect := mapa.get_used_rect()
		print(nombre, " used=", rect, " cells=", mapa.get_used_cells().size())
		if mapa.tile_set:
			print("  tile_set=", mapa.tile_set.resource_path, " size=", mapa.tile_set.tile_size)
			for i in mapa.tile_set.get_source_count():
				var sid := mapa.tile_set.get_source_id(i)
				var src := mapa.tile_set.get_source(sid)
				print("   source ", sid, " ", src.get_class(), " ", src.resource_name if src is Resource else "")

	var agua: TileMapLayer = nivel.get_node("agua")
	var celdas := agua.get_used_cells()
	var clusters := {}
	for c in celdas:
		var clave := c.y
		if not clusters.has(clave):
			clusters[clave] = []
		clusters[clave].append(c.x)
	print("=== AGUA POR FILA ===")
	for y in clusters:
		var xs: Array = clusters[y]
		xs.sort()
		print("y=", y, " x=", xs[0], "..", xs[-1], " n=", xs.size(), " xs=", xs)

	print("=== AGUA AREA ===")
	var area: Area2D = nivel.get_node("agua/Area2D")
	print("pos=", area.position, " layer=", area.collision_layer, " mask=", area.collision_mask)
	for hijo in area.get_children():
		if hijo is CollisionShape2D:
			print("  shape pos=", hijo.position, " shape=", hijo.shape, " size=", hijo.shape.size if hijo.shape is RectangleShape2D else "?")

	print("=== DECORACION ===")
	var deco: TileMapLayer = nivel.get_node("Decoracion")
	var usadas := deco.get_used_cells()
	var por_fuente := {}
	for c in usadas:
		var sid := deco.get_cell_source_id(c)
		if not por_fuente.has(sid):
			por_fuente[sid] = 0
		por_fuente[sid] += 1
	print("por fuente=", por_fuente)
	for c in usadas.slice(0, 40):
		print("  ", c, " src=", deco.get_cell_source_id(c), " atlas=", deco.get_cell_atlas_coords(c))

	print("=== FIN DEL NIVEL ===")
	var rect_nivel: Rect2i = nivel.get_node("Nivel").get_used_rect()
	print("Nivel rect=", rect_nivel, " px x=", rect_nivel.position.x * 32, "..", rect_nivel.end.x * 32)
	print("Player pos=", nivel.get_node("Player").position)
	print("Perro pos=", nivel.get_node("Perro").position if nivel.has_node("Perro") else "n/a")

	get_tree().quit()
