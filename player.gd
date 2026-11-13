class_name Player
extends CharacterBody2D

signal vida_cambiada(vida_media: int, vida_maxima_media: int)
signal murio(causa: String)

@onready var animaciones: AnimatedSprite2D = %Animaciones
@onready var maquina_estados: Node = $MaquinaEstados

@export var corazones_max: int = 3

var vida_media: int
var muerto: bool = false
var invulnerable: bool = false
var causa_muerte: String = "dano"

# Mientras está montado en el tronco del perro, el jugador no controla el movimiento.
var montado_en_tronco: bool = false
var tronco_actual: RigidBody2D = null
var offset_tronco: float = 0.0


func _ready() -> void:
	EstadoJuego.vida_maxima_media = corazones_max * 2
	vida_media = clampi(EstadoJuego.vida_media, 0, EstadoJuego.vida_maxima_media)
	EstadoJuego.vida_media = vida_media
	vida_cambiada.emit(vida_media, EstadoJuego.vida_maxima_media)


func recibir_dano(corazones: float, causa: String = "dano") -> void:
	if muerto or invulnerable:
		return

	var medios := int(round(corazones * 2.0))
	if medios <= 0:
		return

	EstadoJuego.aplicar_dano(medios)
	vida_media = EstadoJuego.vida_media
	vida_cambiada.emit(vida_media, corazones_max * 2)

	if vida_media == 0:
		morir(causa)
		return

	_iniciar_invulnerabilidad()


func morir_en_agua() -> void:
	if muerto:
		return

	# El agua quita un corazón y ese valor se conserva al reaparecer.
	EstadoJuego.castigar_agua()
	vida_media = EstadoJuego.vida_media
	vida_cambiada.emit(vida_media, corazones_max * 2)
	morir("agua")


func morir(causa: String = "dano") -> void:
	if muerto:
		return

	muerto = true
	causa_muerte = causa
	desmontar_de_tronco()
	murio.emit(causa)


func montar_en_tronco(tronco: RigidBody2D) -> void:
	if muerto:
		return

	montado_en_tronco = true
	tronco_actual = tronco
	# Conserva una posición estable sobre el tronco, sin permitir que se salga de él.
	offset_tronco = clampf(global_position.x - tronco.global_position.x, -10.0, 10.0)


func desmontar_de_tronco() -> void:
	montado_en_tronco = false
	tronco_actual = null
	offset_tronco = 0.0


func _iniciar_invulnerabilidad() -> void:
	invulnerable = true
	var tween := create_tween().set_loops(6)
	tween.tween_property(animaciones, "modulate:a", 0.25, 0.1)
	tween.tween_property(animaciones, "modulate:a", 1.0, 0.1)
	await tween.finished
	invulnerable = false
	animaciones.modulate.a = 1.0
