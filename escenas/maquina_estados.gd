extends Node

@onready var player: Player = self.owner
@onready var animaciones: AnimatedSprite2D = %Animaciones
@onready var coyote_time: Timer = $"../CoyoteTime"

const ESCENA_PIEDRA = preload("res://escenas/Piedra.tscn")
const ESCENA_CURVA = preload("res://escenas/CurvaLanzamiento.tscn")

const POTENCIA_MINIMA: float = 150.0
const POTENCIA_MAXIMA: float = 250.0
const VELOCIDAD_RECTA: float = 420.0
const TIEMPO_PARA_MOSTRAR_CURVA: float = 0.18
const IMPULSO_VERTICAL: float = -360.0
const PASO_CURVA: float = 0.04
const PUNTOS_CURVA: int = 36
const MASCARA_ESCENARIO: int = 1

var potencia_lanzamiento: float = POTENCIA_MINIMA
var tiempo_lanzamiento: float = 0.0
var curva_lanzamiento: Node2D = null

@export var VELOCIDAD = 150.0
@export var SALTO = -290
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

enum ESTADO {
	IDLE,
	CAMINANDO,
	LANZANDO,
	SALTANDO,
	CAYENDO,
	MUERTO
}

var estado_actual: ESTADO = ESTADO.CAYENDO
var estaba_en_el_suelo: bool = true
var muriendo: bool = false
var estaba_montado: bool = false

func _ready() -> void:
	animaciones.animation_finished.connect(_on_animacion_terminada)
	curva_lanzamiento = ESCENA_CURVA.instantiate()
	player.call_deferred("add_child", curva_lanzamiento)
	curva_lanzamiento.call("ocultar")

func _physics_process(delta: float):
	var esta_en_suelo = player.is_on_floor()
	
	
	if player.muerto and estado_actual != ESTADO.MUERTO:
		estado_actual = ESTADO.MUERTO
		estaba_montado = false
		_ocultar_curva()
		if player.causa_muerte == "agua":
			animaciones.play("muerte_agua")
		else:
			animaciones.play("muerte")

	# Sobre el tronco del perro se ignoran los controles: solo se sigue al tronco.
	if player.montado_en_tronco and not player.muerto:
		estaba_montado = true
		_ocultar_curva()
		_procesar_montado(delta)
		return

	if estaba_montado:
		estaba_montado = false
		if not player.muerto:
			estado_actual = ESTADO.IDLE if esta_en_suelo else ESTADO.CAYENDO

	# Activar Coyote Time al salir del suelo sin saltar
	if estaba_en_el_suelo and not esta_en_suelo and estado_actual != ESTADO.SALTANDO:
		coyote_time.start()

	estaba_en_el_suelo = esta_en_suelo

	if not esta_en_suelo:
		player.velocity.y += gravity * delta
		
	var direccion := Input.get_axis("mov_izquierda", "mov_derecha")
	
	match estado_actual:
		ESTADO.IDLE:
			player.velocity.x = 0
			animaciones.play("idle")
			
			# Transición a saltar (permite saltar si está en el suelo o dentro del Coyote Time)
			if Input.is_action_just_pressed("salto") and (esta_en_suelo or not coyote_time.is_stopped()):
				player.velocity.y = SALTO
				coyote_time.stop()
				estado_actual = ESTADO.SALTANDO
				
			if direccion != 0:
				estado_actual = ESTADO.CAMINANDO
				
			if Input.is_action_just_pressed("lanzar"):
				_iniciar_lanzamiento()
				
		ESTADO.CAMINANDO:
			animaciones.play("caminar")
			
			if direccion != 0:
				animaciones.flip_h = (direccion < 0)
				player.velocity.x = direccion * VELOCIDAD 
			else:
				player.velocity.x = move_toward(player.velocity.x, 0, VELOCIDAD * delta * 8)
				
			# Transición a saltar
			if Input.is_action_just_pressed("salto") and (esta_en_suelo or not coyote_time.is_stopped()):
				player.velocity.y = SALTO
				coyote_time.stop()
				estado_actual = ESTADO.SALTANDO
			
			if player.velocity.x == 0:
				estado_actual = ESTADO.IDLE
				
			# Transición a cayendo
			if not esta_en_suelo and coyote_time.is_stopped():
				estado_actual = ESTADO.CAYENDO

			if Input.is_action_just_pressed("lanzar"):
				_iniciar_lanzamiento()
		
		ESTADO.LANZANDO:
			player.velocity.x = 0
			animaciones.play("lanzar")
			tiempo_lanzamiento += delta
			var mantener := Input.is_action_pressed("lanzar")

			# A/D ajusta solo la fuerza, como en la lógica anterior.
			if not animaciones.flip_h:
				if Input.is_action_pressed("mov_derecha"):
					potencia_lanzamiento += 100.0 * delta
				if Input.is_action_pressed("mov_izquierda"):
					potencia_lanzamiento -= 100.0 * delta
			else:
				if Input.is_action_pressed("mov_izquierda"):
					potencia_lanzamiento += 100.0 * delta
				if Input.is_action_pressed("mov_derecha"):
					potencia_lanzamiento -= 100.0 * delta
			potencia_lanzamiento = clampf(potencia_lanzamiento, POTENCIA_MINIMA, POTENCIA_MAXIMA)

			if tiempo_lanzamiento >= TIEMPO_PARA_MOSTRAR_CURVA:
				_actualizar_curva()
			else:
				_ocultar_curva()

			# Toque corto: tiro recto. Mantener: lanza con el arco y la fuerza ajustada.
			if not mantener:
				if tiempo_lanzamiento < TIEMPO_PARA_MOSTRAR_CURVA:
					_lanzar_piedra_recta()
				else:
					_lanzar_piedra(potencia_lanzamiento)
				_ocultar_curva()
				tiempo_lanzamiento = 0.0
				estado_actual = ESTADO.IDLE if player.is_on_floor() else ESTADO.CAYENDO
				

		ESTADO.SALTANDO:
			if animaciones.animation != "saltar":
				animaciones.play("saltar")
			
			if direccion != 0:
				animaciones.flip_h = (direccion < 0)
				player.velocity.x = direccion * VELOCIDAD
			else:
				player.velocity.x = move_toward(player.velocity.x, 0, VELOCIDAD)

			# Transición a CAYENDO solo cuando la velocidad Y es positiva
			if player.velocity.y > 0:
				estado_actual = ESTADO.CAYENDO
		
		ESTADO.CAYENDO:
			if animaciones.animation != "cayendo":
				animaciones.play("cayendo")
			
			if direccion != 0:
				animaciones.flip_h = (direccion < 0)
				player.velocity.x = direccion * VELOCIDAD
			else:
				player.velocity.x = move_toward(player.velocity.x, 0, VELOCIDAD)
				
			# Al tocar el suelo, regresa a caminar o idle
			if esta_en_suelo:
				if direccion != 0:
					estado_actual = ESTADO.CAMINANDO
				else:
					estado_actual = ESTADO.IDLE
		ESTADO.MUERTO:
			player.velocity.x = 0
			player.velocity.y = move_toward(player.velocity.y, 0, gravity * delta)
	
	player.move_and_slide()

func _procesar_montado(delta: float) -> void:
	var tronco := player.tronco_actual
	if not is_instance_valid(tronco):
		player.desmontar_de_tronco()
		return

	if not player.is_on_floor():
		player.velocity.y += gravity * delta

	# Sigue la posición del tronco sin aceptar entrada del jugador.
	var objetivo_x := tronco.global_position.x + player.offset_tronco
	var correccion := (objetivo_x - player.global_position.x) * 12.0
	player.velocity.x = clampf(tronco.linear_velocity.x + correccion, -250.0, 250.0)

	animaciones.play("idle")
	animaciones.flip_h = false

	# Espacio ya no salta: ordena al perro dar el empujón para esquivar.
	if Input.is_action_just_pressed("salto") and tronco.has_method("impulsar_perro"):
		tronco.impulsar_perro()

	player.move_and_slide()


func _iniciar_lanzamiento() -> void:
	estado_actual = ESTADO.LANZANDO
	tiempo_lanzamiento = 0.0
	potencia_lanzamiento = POTENCIA_MINIMA
	_ocultar_curva()


func _lanzar_piedra(potencia: float) -> void:
	var direccion := -1.0 if animaciones.flip_h else 1.0
	var piedra = ESCENA_PIEDRA.instantiate()

	piedra.global_position = _origen_lanzamiento(direccion)
	piedra.call("inicializar", potencia, direccion, IMPULSO_VERTICAL)
	piedra.add_to_group("piedras_lanzadas")
	get_tree().current_scene.add_child(piedra)


func _lanzar_piedra_recta() -> void:
	var direccion := -1.0 if animaciones.flip_h else 1.0
	var piedra = ESCENA_PIEDRA.instantiate()

	piedra.global_position = _origen_lanzamiento(direccion)
	piedra.call("inicializar_recta", VELOCIDAD_RECTA, direccion)
	piedra.add_to_group("piedras_lanzadas")
	get_tree().current_scene.add_child(piedra)


func _origen_lanzamiento(direccion: float) -> Vector2:
	return player.global_position + Vector2(direccion * 10.0, -2.0)


func _actualizar_curva() -> void:
	if curva_lanzamiento == null:
		return

	var direccion := -1.0 if animaciones.flip_h else 1.0
	var origen_local := Vector2(direccion * 10.0, -2.0)
	var origen_global := player.global_position + origen_local
	var velocidad_inicial := Vector2(direccion * potencia_lanzamiento, IMPULSO_VERTICAL)
	var gravedad: float = ProjectSettings.get_setting("physics/2d/default_gravity")

	var puntos := PackedVector2Array()
	var espacio := player.get_world_2d().direct_space_state
	var anterior_global := origen_global
	puntos.append(origen_local)

	for i in range(1, PUNTOS_CURVA + 1):
		var t := i * PASO_CURVA
		var punto_local := origen_local + velocidad_inicial * t + Vector2(0.0, 0.5 * gravedad * t * t)
		var punto_global := player.global_position + punto_local

		if i > 1:
			var consulta := PhysicsRayQueryParameters2D.create(anterior_global, punto_global, MASCARA_ESCENARIO)
			consulta.collide_with_areas = false
			var golpe := espacio.intersect_ray(consulta)
			if golpe:
				puntos.append(golpe.position - player.global_position)
				break

		puntos.append(punto_local)
		anterior_global = punto_global

	curva_lanzamiento.call("mostrar", puntos)


func _ocultar_curva() -> void:
	if curva_lanzamiento:
		curva_lanzamiento.call("ocultar")

func _on_animacion_terminada() -> void:
	if estado_actual == ESTADO.MUERTO and (animaciones.animation == &"muerte_agua" or animaciones.animation == &"muerte"):
		morir()

func morir() -> void:
	if muriendo:
		return
	
	muriendo = true
	print("El jugador murió (%s). Reapareciendo..." % player.causa_muerte)
	
	await get_tree().create_timer(0.6).timeout
	
	var nivel := get_tree().current_scene
	if nivel and nivel.has_method("respawn"):
		nivel.respawn(player.causa_muerte)
	else:
		get_tree().reload_current_scene()
