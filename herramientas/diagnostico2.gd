extends Node

const NIVEL = preload("res://escenas/Nivel1.tscn")


func _ready() -> void:
	var nivel = NIVEL.instantiate()
	add_child(nivel)
	await get_tree().process_frame

	var mapa: TileMapLayer = nivel.get_node("Nivel")
	var rect: Rect2i = mapa.get_used_rect()

	print("=== TOPE SOLIDO CADA 10 COLUMNAS (final) ===")
	for x in range(rect.position.x, rect.end.x, 10):
		var tope := -1
		for y in range(rect.position.y, rect.end.y):
			if mapa.get_cell_source_id(Vector2i(x, y)) != -1:
				tope = y
				break
		print("x_cell=", x, " px=", x * 32, " tope=", tope, " y_px=", tope * 32)

	print("=== TOPE CADA COLUMNA 13200..13696 ===")
	for x in range(13200 / 32, rect.end.x):
		var tope := -1
		for y in range(rect.position.y, rect.end.y):
			if mapa.get_cell_source_id(Vector2i(x, y)) != -1:
				tope = y
				break
		print("x_cell=", x, " px=", x * 32, " tope=", tope, " y_px=", tope * 32)

	print("=== CELDAS FINALES y=0..23, x=410..445 ===")
	for y in range(rect.position.y, rect.end.y):
		var fila := ""
		for x in range(410, rect.end.x):
			fila += "#" if mapa.get_cell_source_id(Vector2i(x, y)) != -1 else "."
		print("%02d %s" % [y, fila])

	print("=== NODOS DEL NIVEL CON HIJOS ===")
	for n in nivel.get_children():
		print("- ", n.name, " ", n.get_class(), " hijos=", n.get_child_count())
		for h in n.get_children():
			print("    · ", h.name, " ", h.get_class())

	print("=== FONDO ===")
	var fondo: TileMapLayer = nivel.get_node("Fondo")
	print("fondo used=", fondo.get_used_rect(), " cells=", fondo.get_used_cells().size())

	get_tree().quit()
