extends Node

## Prueba del agua: la hitbox cubre todas las celdas, añade 4 px por encima
## de la superficie y el tilemap conserva su colisión sólida como en mictlan (2).
## Uso: godot --headless --path . pruebas/agua_test.tscn

const NIVEL = preload("res://escenas/Nivel1.tscn")

var _fallos: Array[String] = []
var _nivel: Node2D


func _ready() -> void:
	await get_tree().process_frame
	EstadoJuego.reiniciar_estado()
	EstadoJuego.slot_activo = 0

	_nivel = NIVEL.instantiate()
	add_child(_nivel)
	await get_tree().process_frame
	await get_tree().physics_frame

	var agua: TileMapLayer = _nivel.get_node("agua")
	var area: Area2D = agua.get_node("Area2D")
	var celdas := agua.get_used_cells()

	var colision_solida = agua.get("collision_enabled")
	if colision_solida == null:
		var tileset := agua.tile_set
		var capas_apagadas := true
		for i in range(tileset.get_physics_layers_count()):
			if tileset.get_physics_layer_collision_layer(i) != 0:
				capas_apagadas = false
		_comprobar(capas_apagadas, "la colisión sólida del agua sigue como en mictlan (2)")
	else:
		_comprobar(colision_solida == true, "la colisión sólida del agua sigue activa")

	_comprobar(area.collision_layer == 128, "el área de agua usa la capa 128")
	_comprobar(area.collision_mask == 2, "el área de agua detecta al jugador")
	_comprobar(area.get_child_count() > 1, "la hitbox se reconstruyó en varias formas")

	var formas: Array[Rect2] = []
	for hijo in area.get_children():
		if hijo is CollisionShape2D and hijo.shape is RectangleShape2D:
			var rect := (hijo.shape as RectangleShape2D).get_rect()
			rect.position += hijo.position
			formas.append(rect)
	_comprobar(not formas.is_empty(), "hay formas rectangulares de agua")

	var sin_cobertura := 0
	var superficie_por_columna := {}
	for celda in celdas:
		var centro := agua.map_to_local(celda)
		var cubierta := false
		for rect in formas:
			if rect.has_point(centro):
				cubierta = true
				break
		if not cubierta:
			sin_cobertura += 1
		if not superficie_por_columna.has(celda.x) or celda.y < superficie_por_columna[celda.x]:
			superficie_por_columna[celda.x] = celda.y
	_comprobar(sin_cobertura == 0, "todas las celdas de agua están cubiertas (%d sin cubrir)" % sin_cobertura)

	var lado := float(agua.tile_set.tile_size.x)
	var sin_margen := 0
	var con_margen_de_mas := 0
	for x in superficie_por_columna:
		var y: int = superficie_por_columna[x]
		var borde_superior := float(y) * lado
		var centro_x := float(x) * lado + lado * 0.5
		var dentro := Vector2(centro_x, borde_superior - 2.0)
		var fuera := Vector2(centro_x, borde_superior - 6.0)

		var cubierto_dentro := false
		var cubierto_fuera := false
		for rect in formas:
			if rect.has_point(dentro):
				cubierto_dentro = true
			if rect.has_point(fuera):
				cubierto_fuera = true
		if not cubierto_dentro:
			sin_margen += 1
		if cubierto_fuera:
			con_margen_de_mas += 1
	_comprobar(sin_margen == 0, "el margen de 4 px sobre el agua está cubierto (%d huecos)" % sin_margen)
	_comprobar(con_margen_de_mas == 0, "la hitbox no sube más de 4 px sobre el agua")

	var player := _nivel.get_node("%Player")
	var punto_seco := agua.to_local(player.global_position)
	var seco_cubierto := false
	for rect in formas:
		if rect.has_point(punto_seco):
			seco_cubierto = true
			break
	_comprobar(not seco_cubierto, "el punto de aparición no está dentro del agua")

	# La comprobación directa por frame cubre el caso de que se pierda body_entered.
	var falso_cuerpo := Node2D.new()
	falso_cuerpo.global_position = agua.to_global(agua.map_to_local(celdas[0]))
	_comprobar(
		bool(_nivel.call("_cuerpo_en_agua", falso_cuerpo)),
		"la comprobación directa detecta el cuerpo sobre el agua"
	)
	falso_cuerpo.global_position = player.global_position
	_comprobar(
		not bool(_nivel.call("_cuerpo_en_agua", falso_cuerpo)),
		"la comprobación directa no detecta agua en el punto de aparición"
	)
	falso_cuerpo.free()

	# Al morir en agua el jugador debe congelarse mientras se reproduce la
	# animación; antes la gravedad lo arrastraba hacia abajo con la cámara.
	player.global_position = agua.to_global(agua.map_to_local(celdas[0]))
	var y_inicial: float = player.global_position.y
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.4).timeout
	_comprobar(player.muerto and player.causa_muerte == "agua", "el agua mata al jugador")
	_comprobar(_nivel.get_node_or_null("SoporteAgua") != null, "el agua crea apoyo físico")
	_comprobar((player.collision_mask & 1024) != 0, "el jugador colisiona con el apoyo del agua")
	_comprobar(player.velocity.length() < 0.01, "la velocidad se anula al morir")
	_comprobar(
		absf(player.global_position.y - y_inicial) < 2.0,
		"el jugador no se va hacia abajo al morir en agua"
	)

	_nivel.queue_free()
	await get_tree().process_frame

	if _fallos.is_empty():
		print("PRUEBA AGUA OK")
	else:
		print("PRUEBA AGUA FALLIDA: %s" % [_fallos])
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK: ", mensaje)
	else:
		_fallos.append(mensaje)
