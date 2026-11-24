extends Node2D

const ESCENA_A_INSTANCIAR = preload("res://escenas/lagarto.tscn")
const VELA = preload("res://escenas/vela.tscn")
const FLOR_FINAL = preload("res://escenas/flor_final.tscn")
const PORTAL_FINAL = preload("res://escenas/portal_final.tscn")
const FINAL_NIVEL = preload("res://escenas/final_nivel.tscn")
const CONTROLES_TACTILES = preload("res://escenas/controles_tactiles.tscn")
const CAPA_AGUA: int = 128
# Capa libre para la superficie física que sostiene al jugador al ahogarse.
const CAPA_SOPORTE_AGUA: int = 1024
const ANCHO_SOPORTE_AGUA: float = 48.0
const ALTO_SOPORTE_AGUA: float = 8.0
const MARGEN_AGUA: float = 12.0
const INTERVALO_CHECKPOINT_MS: int = 200
const MARGEN_FONDO_PX: float = 1200.0
const VELAS_OBJETIVO: int = 20
const SEPARACION_VELAS: float = 420.0
const SEMILLA_VELAS: int = 0x5E1A2026
const MARGEN_VELAS: float = 480.0
const X_PORTAL: float = 13_620.0
const X_FLOR: float = 13_450.0
const Y_FINAL: float = 448.0
# La textura del portal deja 2 px transparentes abajo; se baja para asentarlo.
const AJUSTE_Y_PORTAL: float = 2.0
const ZONAS_SIN_VELAS = [
	Vector2(6878.0, 320.0),   # aparición del jugador
	Vector2(12467.0, 320.0),  # perro y tronco
	Vector2(2928.0, 260.0),   # contenedor de la cuerda
	Vector2(3310.0, 260.0),   # estatua
	Vector2(4183.0, 260.0),   # zona de aparición del lagarto
]
# Puntos de guardado fijos, en orden de recorrido. El primero es siempre la
# aparición del jugador; estos se añaden después en _preparar_checkpoints().
const PUNTOS_GUARDADO: Array[Vector2] = [
	Vector2(2768.0, 364.0),   # tras el primer charco (2208..2624)
	Vector2(4352.0, 403.0),   # antes de los lagartos
	Vector2(6080.0, 403.0),   # tras el charco de 5248..5920
	Vector2(8048.0, 300.0),   # tras el charco largo, antes de la cuerda
	Vector2(9800.0, 236.0),   # tras el charco de 9152..9696
	Vector2(11840.0, 371.0),  # antes del perro y la tabla
	Vector2(13450.0, 435.0),  # junto a la flor y el portal
]

@onready var player: Player = %Player
@onready var fundido: ColorRect = $Transicion/Fondo
@onready var hud = %HUD
@onready var nivel_mapa: TileMapLayer = $Nivel
@onready var decoracion: TileMapLayer = $Decoracion
@onready var agua: TileMapLayer = $agua
@onready var parallax_fondo: ParallaxBackground = $ParallaxBackground

var jades_recogidos: int = 0
var jades_totales: int = 0
var reiniciando: bool = false

var _temporizador_guardado: Timer
var _guardado_inicial_hecho: bool = false
var _posicion_inicial: Vector2
var _puntos_checkpoint: Array[Vector2] = []
var _indice_checkpoint: int = 0
var _ultimo_chequeo_checkpoint_ms: int = -10000
var _forma_seguridad: RectangleShape2D
var _consulta_seguridad: PhysicsShapeQueryParameters2D
var _rectas_agua_mundo: Array[Rect2] = []
var _flor_final
var _portal_final
var _final_nivel
var _velas: Node2D
var _controles_tactiles
var _perro_acompañante: CharacterBody2D
var _terminando: bool = false


func _ready() -> void:
	# Las consultas de seguridad necesitan el espacio físico ya registrado
	# y que el jugador haya tenido un frame para apoyarse en el suelo.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_posicion_inicial = player.global_position
	_ajustar_hitbox_agua()
	_preparar_consulta_seguridad()
	_preparar_checkpoints()
	_aplicar_estado_guardado()
	_ajustar_fondo_al_nivel()
	_extender_decoracion()
	_preparar_final()
	_esparcir_velas()
	_preparar_hud()
	_preparar_controles_tactiles()
	_configurar_autoguardado()
	Musica.reproducir_juego()
	call_deferred("_guardar_inicial")


## Ajusta las repeticiones de los Parallax2D según el ancho real del nivel.
## Así, si el tilemap se amplía, el fondo sigue cubriendo todo el recorrido.
func _ajustar_fondo_al_nivel() -> void:
	var rect := nivel_mapa.get_used_rect()
	if rect.size.x <= 0:
		return

	var ancho := float(rect.size.x) * _lado_tile(nivel_mapa)
	for hijo in parallax_fondo.get_children():
		var capa := hijo as Parallax2D
		if capa == null or capa.repeat_size.x <= 0.0:
			continue

		var paso := absf(capa.repeat_size.x * capa.scale.x)
		if paso <= 0.0:
			continue

		# Las copias se reparten alrededor de la posición del Parallax2D.
		# Con dos juegos de copias (una por cada lado) cubrimos todo el
		# ancho del nivel, más un margen para la cámara.
		var copias := ceili((ancho + MARGEN_FONDO_PX) / paso) * 2 + 2
		capa.repeat_times = maxi(capa.repeat_times, copias)


## Repite el patrón de decoración del tilemap hasta el final del nivel.
## No modifica las celdas que ya existen: solo rellena las columnas nuevas.
func _extender_decoracion() -> void:
	var rect_nivel := nivel_mapa.get_used_rect()
	var rect_deco := decoracion.get_used_rect()
	if rect_nivel.size.x <= 0 or rect_deco.size.x <= 0:
		return

	var ancho_patron := rect_deco.size.x

	# A la derecha del patrón original.
	for x in range(rect_deco.end.x, rect_nivel.end.x):
		_copiar_columna_decoracion(x, rect_nivel, rect_deco, ancho_patron)

	# A la izquierda, por si el nivel también crece en ese sentido.
	for x in range(rect_nivel.position.x, rect_deco.position.x):
		_copiar_columna_decoracion(x, rect_nivel, rect_deco, ancho_patron)


func _copiar_columna_decoracion(
	destino_x: int,
	rect_nivel: Rect2i,
	rect_deco: Rect2i,
	ancho_patron: int
) -> void:
	var origen_x := rect_deco.position.x + posmod(destino_x - rect_deco.position.x, ancho_patron)
	var tope_destino := _tope_solido(destino_x, rect_nivel)
	var tope_origen := _tope_solido(origen_x, rect_nivel)

	# Sin suelo, o con el techo del nivel como primera celda, no hay dónde
	# apoyar la decoración.
	if tope_destino >= rect_nivel.end.y or tope_origen >= rect_nivel.end.y:
		return
	if tope_destino <= rect_nivel.position.y or tope_origen <= rect_nivel.position.y:
		return

	for y in range(rect_deco.position.y, rect_deco.end.y):
		var celda_origen := Vector2i(origen_x, y)
		var fuente := decoracion.get_cell_source_id(celda_origen)
		if fuente == -1:
			continue

		# La decoración original se apoya un tile por encima del suelo.
		var destino_y := tope_destino + (y - tope_origen)
		var celda_destino := Vector2i(destino_x, destino_y)
		if destino_y < rect_nivel.position.y or destino_y >= rect_nivel.end.y:
			continue
		if nivel_mapa.get_cell_source_id(celda_destino) != -1:
			continue

		decoracion.set_cell(
			celda_destino,
			fuente,
			decoracion.get_cell_atlas_coords(celda_origen),
			decoracion.get_cell_alternative_tile(celda_origen)
		)


func _tope_solido(x: int, rect_nivel: Rect2i) -> int:
	for y in range(rect_nivel.position.y, rect_nivel.end.y):
		if nivel_mapa.get_cell_source_id(Vector2i(x, y)) != -1:
			return y
	return rect_nivel.end.y


func _lado_tile(mapa: TileMapLayer) -> int:
	if mapa.tile_set == null:
		return 32
	return mapa.tile_set.tile_size.x


## Reconstruye la zona de muerte del agua a partir de todas sus celdas.
## El tilemap deja de ser sólido para que el jugador caiga y muera al tocar
## cualquier charca, en lugar de poder caminar sobre la superficie.
func _ajustar_hitbox_agua() -> void:
	if agua == null:
		return

	# TileMapLayer.collision_enabled existe en Godot 4.7. Si no estuviera,
	# se desactivan las capas de física del TileSet como respaldo.
	if agua.get("collision_enabled") == null:
		var tileset := agua.tile_set
		if tileset != null:
			for i in range(tileset.get_physics_layers_count()):
				tileset.set_physics_layer_collision_layer(i, 0)
				tileset.set_physics_layer_collision_mask(i, 0)

	var area := agua.get_node_or_null("Area2D") as Area2D
	if area == null:
		area = Area2D.new()
		area.name = "Area2D"
		agua.add_child(area)

	_rectas_agua_mundo.clear()

	area.collision_layer = CAPA_AGUA
	area.collision_mask = 2

	# La escena traía una sola forma que cubría una franja por debajo de la
	# superficie; se sustituye por la cobertura completa de las celdas.
	for hijo in area.get_children():
		if hijo is CollisionShape2D:
			area.remove_child(hijo)
			hijo.queue_free()

	var lado := float(_lado_tile(agua))
	var por_fila := {}
	for celda in agua.get_used_cells():
		if not por_fila.has(celda.y):
			por_fila[celda.y] = []
		por_fila[celda.y].append(celda.x)

	for y in por_fila:
		var xs: Array = por_fila[y]
		xs.sort()
		var inicio: int = xs[0]
		var anterior: int = xs[0]
		for i in range(1, xs.size()):
			var x: int = xs[i]
			if x == anterior + 1:
				anterior = x
				continue
			_crear_forma_agua(area, inicio, anterior, y, lado)
			inicio = x
			anterior = x
		_crear_forma_agua(area, inicio, anterior, y, lado)


func _crear_forma_agua(
	area: Area2D,
	x_inicio: int,
	x_fin: int,
	y: int,
	lado: float
) -> void:
	var ancho := float(x_fin - x_inicio + 1) * lado
	var centro := agua.map_to_local(Vector2i(x_inicio, y))
	centro.x += (ancho - lado) * 0.5
	# La forma cubre la celda completa y 4 px por encima de su superficie.
	centro.y -= 2.0

	var forma := RectangleShape2D.new()
	forma.size = Vector2(ancho, lado + 4.0)

	var colision := CollisionShape2D.new()
	colision.shape = forma
	colision.position = centro
	area.add_child(colision)

	# Copia en coordenadas del mundo para la comprobación directa por frame.
	# Así el agua sigue matando aunque se pierda la señal body_entered
	# (por ejemplo, si el jugador aparece ya dentro del agua).
	var centro_mundo := agua.to_global(centro)
	_rectas_agua_mundo.append(Rect2(centro_mundo - forma.size * 0.5, forma.size))


## Comprueba si el rectángulo de colisión del cuerpo toca alguna charca.
func _cuerpo_en_agua(cuerpo: Node2D) -> bool:
	if cuerpo == null:
		return false

	# La forma del jugador es 8x15 con desplazamiento (-1, 5.5).
	var cuerpo_rect := Rect2(
		cuerpo.global_position + Vector2(-5.0, -2.0),
		Vector2(8.0, 15.0)
	)
	for rect in _rectas_agua_mundo:
		if rect.intersects(cuerpo_rect):
			return true
	return false


func _physics_process(_delta: float) -> void:
	if reiniciando or not is_instance_valid(player) or player.muerto:
		return

	# Sobre la tabla del perro el agua no puede matar: la tabla avanza por la
	# superficie y el cuerpo del niño queda dentro del área de muerte al bajar
	# hasta apoyarse. Solo se vuelve a comprobar el agua tras desmontar.
	if not player.montado_en_tronco and not player.ignorar_agua and _cuerpo_en_agua(player):
		_matar_en_agua()
		return

	# El permiso termina en cuanto el niño toca tierra tras el salto final.
	if player.ignorar_agua and player.is_on_floor():
		player.ignorar_agua = false
		_soltar_derecha()

	if not player.is_on_floor() or player.montado_en_tronco:
		return

	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_chequeo_checkpoint_ms < INTERVALO_CHECKPOINT_MS:
		return
	_ultimo_chequeo_checkpoint_ms = ahora

	_actualizar_checkpoint()


func _preparar_consulta_seguridad() -> void:
	# Rectángulo del cuerpo del jugador (8x15) ampliado por el margen.
	_forma_seguridad = RectangleShape2D.new()
	_forma_seguridad.size = Vector2(
		8.0 + MARGEN_AGUA * 2.0,
		15.0 + MARGEN_AGUA * 2.0
	)
	_consulta_seguridad = PhysicsShapeQueryParameters2D.new()
	_consulta_seguridad.shape = _forma_seguridad
	_consulta_seguridad.collision_mask = CAPA_AGUA
	_consulta_seguridad.collide_with_areas = true
	_consulta_seguridad.collide_with_bodies = true
	_consulta_seguridad.exclude = [player.get_rid()]


## Prepara la lista completa de checkpoints: el inicio del nivel y los puntos
## fijos repartidos por el recorrido. Todos se validan antes de usarse.
func _preparar_checkpoints() -> void:
	_puntos_checkpoint.clear()
	_posicion_inicial = _buscar_punto_seguro(_posicion_inicial)
	_puntos_checkpoint.append(_posicion_inicial)
	for punto in PUNTOS_GUARDADO:
		_puntos_checkpoint.append(_buscar_punto_seguro(punto))
	_sincronizar_indice_checkpoint()


## Coloca el checkpoint activo en el último punto alcanzado por la partida
## guardada. Así una partida cargada no retrocede al principio al morir.
func _sincronizar_indice_checkpoint() -> void:
	if _puntos_checkpoint.is_empty():
		return

	var guardado := EstadoJuego.checkpoint_posicion
	_indice_checkpoint = 0
	for i in range(_puntos_checkpoint.size()):
		if guardado.x >= _puntos_checkpoint[i].x - 4.0:
			_indice_checkpoint = i

	EstadoJuego.checkpoint_posicion = _puntos_checkpoint[_indice_checkpoint]
	EstadoJuego.checkpoint_escena = scene_file_path


## Activa el siguiente punto fijo cuando el jugador lo alcance por fin.
func _actualizar_checkpoint() -> void:
	var siguiente := _indice_checkpoint + 1
	if siguiente >= _puntos_checkpoint.size():
		return
	if player.global_position.x < _puntos_checkpoint[siguiente].x:
		return

	_indice_checkpoint = siguiente
	EstadoJuego.checkpoint_escena = scene_file_path
	EstadoJuego.checkpoint_posicion = _puntos_checkpoint[siguiente]
	guardar_partida_actual(true)


## Rechaza puntos sobre el agua o demasiado cerca de ella, y exige suelo
## firme debajo. Así el respawn nunca cae dentro de la zona de muerte.
func _es_punto_seguro(posicion: Vector2) -> bool:
	if _consulta_seguridad == null:
		return true

	_consulta_seguridad.transform = Transform2D(0.0, posicion + Vector2(-1.0, 5.5))
	var espacio := get_world_2d().direct_space_state
	if not espacio.intersect_shape(_consulta_seguridad, 1).is_empty():
		return false

	var consulta_rayo := PhysicsRayQueryParameters2D.create(
		posicion + Vector2(0.0, 10.0),
		posicion + Vector2(0.0, 24.0),
		1
	)
	consulta_rayo.exclude = [player.get_rid()]
	return not espacio.intersect_ray(consulta_rayo).is_empty()


## Busca el punto seguro más cercano. Si el checkpoint guardado quedó
## dentro del agua, intenta retroceder horizontalmente antes de rendirse.
func _buscar_punto_seguro(base: Vector2) -> Vector2:
	if _es_punto_seguro(base):
		return base

	var candidatos := [
		Vector2(-16, 0), Vector2(16, 0),
		Vector2(-32, 0), Vector2(32, 0),
		Vector2(-48, 0), Vector2(48, 0),
		Vector2(-64, 0), Vector2(64, 0),
		Vector2(0, -8), Vector2(0, -16),
		Vector2(0, 8), Vector2(0, 16), Vector2(0, 24),
		Vector2(0, 32), Vector2(0, 40), Vector2(0, 48),
	]
	for desplazamiento in candidatos:
		var candidato: Vector2 = base + desplazamiento
		if _es_punto_seguro(candidato):
			return candidato

	return _posicion_inicial


func _aplicar_estado_guardado() -> void:
	var usar_checkpoint := EstadoJuego.partida_cargada or EstadoJuego.respawn_en_checkpoint
	if usar_checkpoint and EstadoJuego.checkpoint_posicion != Vector2.ZERO:
		var punto := _buscar_punto_seguro(EstadoJuego.checkpoint_posicion)
		player.global_position = punto
		player.velocity = Vector2.ZERO
		EstadoJuego.checkpoint_posicion = punto
		_colocar_perro_en_checkpoint(punto)

	EstadoJuego.partida_cargada = false
	EstadoJuego.respawn_en_checkpoint = false
	EstadoJuego.reinicio_completo = false

	EstadoJuego.checkpoint_escena = scene_file_path
	if EstadoJuego.checkpoint_posicion == Vector2.ZERO:
		# Partida nueva o reinicio completo: el primer checkpoint es el
		# punto de aparición del nivel.
		EstadoJuego.checkpoint_posicion = _posicion_inicial

	_sincronizar_indice_checkpoint()


## Tras una muerte o una carga, el perro debe reaparecer con el niño y no
## quedarse en su sitio del principio del nivel. Se busca un punto firme
## cercano al checkpoint y se reactiva el seguimiento.
func _colocar_perro_en_checkpoint(punto: Vector2) -> void:
	_perro_acompañante = get_node_or_null("PerroAcompañante") as CharacterBody2D
	if not is_instance_valid(_perro_acompañante):
		return

	var destino := punto
	for desplazamiento in [-28.0, 28.0, -44.0, 44.0, -16.0, 16.0]:
		var base := punto + Vector2(desplazamiento, 0.0)
		var candidato := _buscar_punto_seguro(base)
		if candidato.distance_to(base) < 1.0:
			destino = candidato
			break

	_perro_acompañante.global_position = destino
	_perro_acompañante.velocity = Vector2.ZERO
	_perro_acompañante.player = player
	_perro_acompañante.activo = true
	_perro_acompañante.en_rango = true
	_perro_acompañante.yendose = false
	_perro_acompañante.tiempo_impulso = 0.0
	# Si el checkpoint está junto a la zona de despedida, no debe irse.
	_perro_acompañante.mantener_con_jugador = true
	_perro_acompañante.visible = true


func _preparar_hud() -> void:
	player.vida_cambiada.connect(Callable(hud, "actualizar_vida"))
	hud.call("actualizar_vida", player.vida_media, player.corazones_max * 2)

	jades_recogidos = EstadoJuego.jades_recogidos_nombres.size()
	for piedra in $piedras.get_children():
		jades_totales += 1

		if EstadoJuego.jades_recogidos_nombres.has(String(piedra.name)):
			# Se quita del árbol de inmediato para que su Area2D no pueda
			# volver a emitir la señal mientras se libera.
			$piedras.remove_child(piedra)
			piedra.queue_free()
			continue

		if piedra.has_signal("recogida"):
			piedra.connect("recogida", _on_jade_recogido.bind(String(piedra.name)))

	hud.call("actualizar_jades", jades_recogidos, jades_totales)


func _on_jade_recogido(nombre: String) -> void:
	EstadoJuego.registrar_jade(nombre)
	jades_recogidos = EstadoJuego.jades_recogidos
	hud.call("actualizar_jades", jades_recogidos, jades_totales)
	Sonidos.reproducir_mundo("tomar_gema", player.global_position, -3.0)
	guardar_partida_actual(true)


## Los botones táctiles se crean en runtime para no tocar la escena del nivel
## del usuario. En escritorio se ocultan solos; las acciones siguen siendo las
## mismas que las del teclado y el mando.
func _preparar_controles_tactiles() -> void:
	_controles_tactiles = CONTROLES_TACTILES.instantiate()
	add_child(_controles_tactiles)


func _configurar_autoguardado() -> void:
	_temporizador_guardado = Timer.new()
	_temporizador_guardado.wait_time = 1.0
	_temporizador_guardado.autostart = true
	_temporizador_guardado.timeout.connect(_on_autoguardado)
	add_child(_temporizador_guardado)


func _on_autoguardado() -> void:
	guardar_partida_actual(true)


func _guardar_inicial() -> void:
	if _guardado_inicial_hecho:
		return
	_guardado_inicial_hecho = true
	guardar_partida_actual(true)


## Guarda la ranura activa. Por defecto usa el checkpoint; el parámetro
## existe para poder guardar la posición actual en el futuro si hiciera falta.
func guardar_partida_actual(usar_checkpoint: bool = true) -> void:
	if reiniciando or not is_instance_valid(player) or player.muerto:
		return

	var posicion := EstadoJuego.checkpoint_posicion
	if not usar_checkpoint and player.is_on_floor() and not player.montado_en_tronco:
		posicion = player.global_position

	if posicion == Vector2.ZERO:
		return

	EstadoJuego.guardar_slot_actual(scene_file_path, posicion, "NIVEL 1")


## Coloca la flor y el portal al final del nivel. Si la flor ya se recogió
## en esta partida, el portal aparece abierto desde el principio.
func _preparar_final() -> void:
	var contenedor := Node2D.new()
	contenedor.name = "Final"
	add_child(contenedor)

	_portal_final = PORTAL_FINAL.instantiate()
	_portal_final.position = Vector2(X_PORTAL, Y_FINAL + AJUSTE_Y_PORTAL)
	contenedor.add_child(_portal_final)
	_portal_final.bloqueado.connect(_on_portal_bloqueado)
	_portal_final.entrado.connect(_on_portal_entrado)

	if EstadoJuego.flor_recogida:
		_portal_final.call("activar")
		return

	_flor_final = FLOR_FINAL.instantiate()
	_flor_final.position = Vector2(X_FLOR, Y_FINAL)
	contenedor.add_child(_flor_final)
	_flor_final.recogida.connect(_on_flor_recogida)


## Reparte velas por las repisas del nivel con una semilla fija. Así la
## decoración parece aleatoria pero es reproducible entre partidas.
func _esparcir_velas() -> void:
	_velas = Node2D.new()
	_velas.name = "Velas"
	add_child(_velas)

	var rng := RandomNumberGenerator.new()
	rng.seed = SEMILLA_VELAS

	var rect := nivel_mapa.get_used_rect()
	var lado := float(_lado_tile(nivel_mapa))
	var x_min := float(rect.position.x) * lado + MARGEN_VELAS
	var x_max := float(rect.end.x) * lado - MARGEN_VELAS
	var candidatos: Array[Vector2] = []

	var x := x_min + lado * 0.5
	while x <= x_max:
		var superficie := _superficie_vela(x, rect)
		if superficie >= 0.0:
			candidatos.append(Vector2(x, superficie))
		x += lado

	for i in range(candidatos.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temporal := candidatos[i]
		candidatos[i] = candidatos[j]
		candidatos[j] = temporal

	var colocadas: Array[Vector2] = []
	for candidato in candidatos:
		if colocadas.size() >= VELAS_OBJETIVO:
			break

		var valida := true
		for otra in colocadas:
			if absf(candidato.x - otra.x) < SEPARACION_VELAS:
				valida = false
				break
		if not valida:
			continue

		colocadas.append(candidato)
		_crear_vela(candidato, rng)


func _superficie_vela(x: float, rect: Rect2i) -> float:
	var lado := float(_lado_tile(nivel_mapa))
	var celda_x := int(floor(x / lado))
	var tope := _tope_solido(celda_x, rect)
	if tope <= rect.position.y or tope >= rect.end.y - 1:
		return -1.0

	# Solo repisas planas de al menos tres tiles.
	if _tope_solido(celda_x - 1, rect) != tope or _tope_solido(celda_x + 1, rect) != tope:
		return -1.0

	var superficie := float(tope) * lado
	if _hay_agua_cerca(x, superficie):
		return -1.0
	if _zona_sin_velas(x):
		return -1.0
	return superficie


func _hay_agua_cerca(x: float, superficie: float) -> bool:
	var celda := agua.local_to_map(agua.to_local(Vector2(x, superficie - 8.0)))
	for dx in range(-2, 3):
		for dy in range(-1, 3):
			if agua.get_cell_source_id(celda + Vector2i(dx, dy)) != -1:
				return true
	return false


func _zona_sin_velas(x: float) -> bool:
	for zona in ZONAS_SIN_VELAS:
		if absf(x - zona.x) < zona.y:
			return true
	return x > X_FLOR - 260.0


func _crear_vela(posicion: Vector2, rng: RandomNumberGenerator) -> void:
	var vela = VELA.instantiate()
	vela.position = posicion + Vector2(rng.randf_range(-6.0, 6.0), 0.0)
	vela.set("fase", rng.randf_range(0.0, TAU))
	_velas.add_child(vela)


func velas_colocadas() -> int:
	return _velas.get_child_count() if _velas != null else 0


func _on_flor_recogida() -> void:
	if _terminando:
		return

	EstadoJuego.registrar_flor()
	guardar_partida_actual(true)
	_portal_final.call("activar")
	hud.call("mostrar_mensaje", "HAS RECOGIDO LA FLOR DE CEMPASÚCHIL\nEL PORTAL SE HA ABIERTO", 4.0)
	Sonidos.reproducir_ui("tomar_gema", -2.0)


func _on_portal_bloqueado() -> void:
	if _terminando:
		return
	hud.call("mostrar_mensaje", "EL PORTAL ESTÁ SELLADO\nBUSCA LA FLOR AL FINAL DEL CAMINO", 2.5)


func _on_portal_entrado() -> void:
	if _terminando:
		return

	_terminando = true
	player.velocity = Vector2.ZERO
	player.process_mode = Node.PROCESS_MODE_DISABLED
	hud.call("ocultar_mensaje")

	# El menú de pausa no debe abrirse encima del final.
	var pausa := get_node_or_null("Pausa")
	if pausa != null:
		pausa.visible = false
		pausa.process_mode = Node.PROCESS_MODE_DISABLED

	Sonidos.reproducir_ui("seleccion", -4.0)

	var tween := create_tween()
	tween.tween_property(fundido, "color:a", 1.0, 0.9)
	await tween.finished

	_final_nivel = FINAL_NIVEL.instantiate()
	add_child(_final_nivel)
	get_tree().paused = true

func _on_agua_body_entered(body: Node2D) -> void:
	if body != player or reiniciando or player.muerto:
		return
	if player.montado_en_tronco or player.ignorar_agua:
		return

	_matar_en_agua()


## Mata al jugador y crea una superficie física sobre el agua para que el
## cuerpo no siga hundiéndose mientras se reproduce la animación de muerte.
## El soporte no existe en vida, así que el agua sigue siendo letal.
func _matar_en_agua() -> void:
	if reiniciando or not is_instance_valid(player) or player.muerto:
		return

	player.morir_en_agua()
	_crear_soporte_agua()


func _crear_soporte_agua() -> void:
	var soporte := StaticBody2D.new()
	soporte.name = "SoporteAgua"
	soporte.collision_layer = CAPA_SOPORTE_AGUA
	soporte.collision_mask = 2

	var forma := RectangleShape2D.new()
	forma.size = Vector2(ANCHO_SOPORTE_AGUA, ALTO_SOPORTE_AGUA)
	var colision := CollisionShape2D.new()
	colision.shape = forma
	soporte.add_child(colision)

	add_child(soporte)
	# La caja del jugador termina 13 px por debajo de su origen.
	soporte.global_position = Vector2(
		player.global_position.x,
		player.global_position.y + 13.0 + ALTO_SOPORTE_AGUA * 0.5
	)
	player.collision_mask |= CAPA_SOPORTE_AGUA


func _spawn_lagarto() -> void:
	var nueva_escena = ESCENA_A_INSTANCIAR.instantiate()
	nueva_escena.global_position = player.global_position - Vector2(300, 0)
	get_tree().current_scene.add_child(nueva_escena)


## Solo se reinicia el nivel entero cuando ya no queda ningún corazón.
func _debe_reiniciar_completo() -> bool:
	return EstadoJuego.vida_media <= 0


func respawn(causa: String = "dano") -> void:
	if reiniciando:
		return

	if player.ignorar_agua:
		player.ignorar_agua = false
		_soltar_derecha()
	reiniciando = true
	var espera_game_over := 0.0

	if not _debe_reiniciar_completo():
		# Muerte "pequeña" (cualquier causa con corazones restantes): vuelve
		# al último punto de guardado y conserva vidas, jades y flor.
		EstadoJuego.checkpoint_posicion = _buscar_punto_seguro(EstadoJuego.checkpoint_posicion)
		EstadoJuego.respawn_en_ultimo_suelo()
	else:
		# Perder los tres corazones reinicia el nivel por completo.
		# El fundido se mantiene en negro hasta que termina GAME OVER;
		# así el nivel no reaparece encima del sonido.
		espera_game_over = Sonidos.duracion("game_over")
		Sonidos.reproducir_ui("game_over", -5.0)
		EstadoJuego.reiniciar_nivel_completo()

	fundido.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fundido, "color:a", 1.0, 0.5)
	await tween.finished
	if espera_game_over > 0.0:
		# 0.15 s de margen para no cortar el final del audio.
		await get_tree().create_timer(maxf(espera_game_over - 0.5, 0.0) + 0.15).timeout
	get_tree().reload_current_scene()


func _soltar_derecha() -> void:
	var evento := InputEventAction.new()
	evento.action = "mov_derecha"
	evento.pressed = false
	Input.parse_input_event(evento)


func _on_area_2d_body_entered(_body: Node2D) -> void:
	call_deferred("_spawn_lagarto")
func _on_final_lagarto_body_entered(body: Node2D) -> void:
	if body.has_method("hundirse"):
		body.hundirse()
