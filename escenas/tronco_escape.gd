extends RigidBody2D

@export var DISTANCIA_MINIMA_RECORRIDO: float = 80.0
@export var TIEMPO_PARADO_PARA_BAJAR: float = 0.8

@onready var zona_jinete: Area2D = $ZonaJinete

var jinete: Player = null
var x_inicio: float = 0.0
var x_maxima: float = 0.0
var recorrido_iniciado: bool = false
var tiempo_sin_avanzar: float = 0.0


func _ready() -> void:
	x_inicio = global_position.x
	x_maxima = x_inicio
	zona_jinete.body_entered.connect(_on_zona_jinete_body_entered)
	zona_jinete.body_exited.connect(_on_zona_jinete_body_exited)


func _physics_process(delta: float) -> void:
	if jinete and (not is_instance_valid(jinete) or jinete.muerto):
		_soltar_jinete()
		return

	if jinete == null:
		tiempo_sin_avanzar = 0.0
		return

	if not recorrido_iniciado and absf(global_position.x - x_inicio) > DISTANCIA_MINIMA_RECORRIDO:
		recorrido_iniciado = true
		x_maxima = global_position.x

	# Si el tronco ya avanzó y dejó de progresar al final, el niño puede bajarse.
	if recorrido_iniciado:
		if global_position.x > x_maxima + 0.25:
			x_maxima = global_position.x
			tiempo_sin_avanzar = 0.0
		else:
			tiempo_sin_avanzar += delta
			if tiempo_sin_avanzar >= TIEMPO_PARADO_PARA_BAJAR:
				_soltar_jinete()


func _on_zona_jinete_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	if body.muerto or body.ignorar_agua:
		return

	jinete = body
	body.montar_en_tronco(self)


func _on_zona_jinete_body_exited(body: Node2D) -> void:
	if body == jinete:
		_soltar_jinete()


func _soltar_jinete() -> void:
	if is_instance_valid(jinete):
		jinete.desmontar_de_tronco()
		# La tabla se detiene poco antes de la orilla. El salto hacia delante
		# deja al niño sobre el suelo firme en lugar de soltarlo en el agua.
		jinete.ignorar_agua = true
		jinete.velocity = Vector2(150.0, -260.0)
		_mantener_derecha(true)
	jinete = null
	tiempo_sin_avanzar = 0.0


func impulsar_perro() -> void:
	var perro := get_parent().get_node_or_null("Perro")
	if perro and perro.has_method("impulsar"):
		perro.impulsar()


func _mantener_derecha(presionada: bool) -> void:
	var evento := InputEventAction.new()
	evento.action = "mov_derecha"
	evento.pressed = presionada
	Input.parse_input_event(evento)
