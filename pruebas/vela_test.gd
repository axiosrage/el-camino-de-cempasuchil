extends Node

## Prueba de las velas decorativas: se reparten por el nivel, se apoyan en
## suelo seco, mantienen separación y su brillo amarillo pulsa.
## Uso: godot --headless --path . pruebas/vela_test.tscn

const NIVEL = preload("res://escenas/Nivel1.tscn")

var _fallos: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	EstadoJuego.reiniciar_estado()
	EstadoJuego.slot_activo = 0

	var nivel = NIVEL.instantiate()
	add_child(nivel)
	await get_tree().process_frame
	await get_tree().physics_frame

	var velas: Node2D = nivel.get_node_or_null("Velas")
	_comprobar(velas != null, "existe el contenedor de velas")
	if velas == null:
		await _terminar(nivel)
		return

	var total := velas.get_child_count()
	_comprobar(total >= 10, "se colocaron varias velas (%d)" % total)
	_comprobar(total <= 20, "no hay más velas de las previstas (%d)" % total)

	var nivel_mapa: TileMapLayer = nivel.get_node("Nivel")
	var agua: TileMapLayer = nivel.get_node("agua")
	var posiciones: Array[float] = []
	var fases := {}
	var con_brillo := 0
	var reducidas := 0
	var amarillas := 0

	for vela in velas.get_children():
		posiciones.append(vela.global_position.x)
		fases[vela.get("fase")] = true

		var brillo: Sprite2D = vela.get_node_or_null("Brillo")
		if brillo != null and brillo.material is CanvasItemMaterial:
			if (brillo.material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_ADD:
				con_brillo += 1
		if brillo != null and brillo.modulate.g > 0.8 and brillo.modulate.b < 0.6:
			amarillas += 1

		var sprite: Sprite2D = vela.get_node_or_null("Sprite2D")
		if sprite != null and sprite.texture.get_height() * sprite.scale.y <= 9.0:
			reducidas += 1

		var celda := Vector2i(
			int(floor(vela.global_position.x / 32.0)),
			int(floor(vela.global_position.y / 32.0))
		)
		_comprobar(
			nivel_mapa.get_cell_source_id(celda) != -1,
			"vela apoyada en suelo sólido en %s" % vela.global_position
		)

		var celda_agua := agua.local_to_map(agua.to_local(vela.global_position - Vector2(0, 8)))
		var agua_cerca := false
		for dx in range(-2, 3):
			for dy in range(-1, 3):
				if agua.get_cell_source_id(celda_agua + Vector2i(dx, dy)) != -1:
					agua_cerca = true
		_comprobar(not agua_cerca, "vela fuera del agua en %s" % vela.global_position)

	_comprobar(con_brillo == total, "todas las velas tienen brillo aditivo")
	_comprobar(reducidas == total, "todas las velas miden 9 px o menos de alto")
	_comprobar(amarillas == total, "el destello de la llama es amarillo")
	_comprobar(fases.size() > 1, "las velas parpadean con fases distintas")

	posiciones.sort()
	var separacion_min := INF
	for i in range(1, posiciones.size()):
		separacion_min = minf(separacion_min, posiciones[i] - posiciones[i - 1])
	_comprobar(separacion_min >= 400.0, "separación mínima entre velas (%.1f px)" % separacion_min)

	var primera = velas.get_child(0)
	var brillo_primera: Sprite2D = primera.get_node("Brillo")
	# Se muestrea varias veces para no depender de la fase del seno en el
	# instante exacto en que empieza la prueba.
	var alfa_min := INF
	var alfa_max := -INF
	for i in range(6):
		var alfa := brillo_primera.modulate.a
		alfa_min = minf(alfa_min, alfa)
		alfa_max = maxf(alfa_max, alfa)
		await get_tree().create_timer(0.12).timeout
	_comprobar(alfa_max - alfa_min > 0.01, "el brillo de la llama pulsa")

	await _terminar(nivel)


func _terminar(nivel) -> void:
	if nivel != null:
		nivel.queue_free()
		await get_tree().process_frame

	if _fallos.is_empty():
		print("PRUEBA VELA OK")
	else:
		print("PRUEBA VELA FALLIDA: %s" % [_fallos])
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK: ", mensaje)
	else:
		_fallos.append(mensaje)
