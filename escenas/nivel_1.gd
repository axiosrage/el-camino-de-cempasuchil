extends Node2D

const ESCENA_A_INSTANCIAR = preload("res://escenas/lagarto.tscn")
const CAPA_AGUA: int = 128
const MARGEN_AGUA: float = 12.0
const INTERVALO_CHECKPOINT_MS: int = 200

@onready var player: Player = %Player
@onready var fundido: ColorRect = $Transicion/Fondo
@onready var hud = %HUD

var jades_recogidos: int = 0
var jades_totales: int = 0
var reiniciando: bool = false

var _temporizador_guardado: Timer
var _guardado_inicial_hecho: bool = false
var _posicion_inicial: Vector2
var _ultimo_chequeo_checkpoint_ms: int = -10000
var _forma_seguridad: RectangleShape2D
var _consulta_seguridad: PhysicsShapeQueryParameters2D


func _ready() -> void:
	_posicion_inicial = player.global_position
	_preparar_consulta_seguridad()
	_aplicar_estado_guardado()
	_preparar_hud()
	_configurar_autoguardado()
	call_deferred("_guardar_inicial")


func _physics_process(_delta: float) -> void:
	if reiniciando or not is_instance_valid(player) or player.muerto:
		return

	if not player.is_on_floor() or player.montado_en_tronco:
		return

	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_chequeo_checkpoint_ms < INTERVALO_CHECKPOINT_MS:
		return
	_ultimo_chequeo_checkpoint_ms = ahora

	# La última superficie firme y segura es el checkpoint. Se actualiza
	# en memoria; el temporizador se encarga de llevarlo al disco.
	if _es_punto_seguro(player.global_position):
		EstadoJuego.checkpoint_escena = scene_file_path
		EstadoJuego.checkpoint_posicion = player.global_position


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

	EstadoJuego.partida_cargada = false
	EstadoJuego.respawn_en_checkpoint = false
	EstadoJuego.reinicio_completo = false

	EstadoJuego.checkpoint_escena = scene_file_path
	if EstadoJuego.checkpoint_posicion == Vector2.ZERO:
		# Partida nueva o reinicio completo: el primer checkpoint es el
		# punto de aparición del nivel.
		EstadoJuego.checkpoint_posicion = _posicion_inicial


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


func _on_area_2d_body_entered(_body: Node2D) -> void:
	call_deferred("_spawn_lagarto")


func _on_agua_body_entered(body: Node2D) -> void:
	if body != player or reiniciando or player.muerto:
		return

	player.morir_en_agua()


func _spawn_lagarto() -> void:
	var nueva_escena = ESCENA_A_INSTANCIAR.instantiate()
	nueva_escena.global_position = player.global_position - Vector2(300, 0)
	get_tree().current_scene.add_child(nueva_escena)


func respawn(causa: String = "dano") -> void:
	if reiniciando:
		return

	reiniciando = true
	var espera_game_over := 0.0

	if causa == "agua" and EstadoJuego.vida_media > 0:
		# Muerte en agua con vida restante: reaparece en la última
		# superficie firme y conserva los jades recogidos.
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
