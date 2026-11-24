extends Node2D

## Vela decorativa con un destello amarillo en la llama.
##
## El nivel asigna `fase` antes de añadir la vela al árbol para que cada
## una parpadee con un ritmo ligeramente distinto.

@onready var brillo: Sprite2D = $Brillo

@export var fase: float = 0.0

var _tiempo: float = 0.0
var _duracion: float = 1.0
var _escala_base: Vector2


func _ready() -> void:
	_escala_base = brillo.scale
	_duracion = 1.0 + fmod(absf(fase) * 0.37, 0.55)
	_tiempo = fmod(absf(fase), TAU)


func _process(delta: float) -> void:
	_tiempo += delta
	var pulso := 0.5 + 0.5 * sin(_tiempo * TAU / _duracion)
	# Destello amarillo: la llama pasa de ámbar a amarillo claro al pulsar.
	brillo.modulate.r = 1.0
	brillo.modulate.g = lerpf(0.82, 1.0, pulso)
	brillo.modulate.b = lerpf(0.2, 0.55, pulso)
	brillo.modulate.a = lerpf(0.4, 1.0, pulso)
	brillo.scale = _escala_base * lerpf(0.85, 1.25, pulso)
