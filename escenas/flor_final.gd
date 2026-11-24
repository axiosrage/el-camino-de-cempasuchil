extends Node2D

## Flor de cempasúchil que cierra el nivel.
##
## Flota sobre el final de la plataforma y brilla con un resplandor cálido.
## Al tocarla emite `recogida`, se encoge y desaparece.

signal recogida

@onready var area: Area2D = $Area2D
@onready var flor: Sprite2D = $Flor
@onready var brillo: Sprite2D = $Brillo

var _recogida: bool = false
var _tiempo: float = 0.0
var _base_flor: Vector2
var _base_brillo: Vector2
var _base_brillo_escala: Vector2


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	_base_flor = flor.position
	_base_brillo = brillo.position
	_base_brillo_escala = brillo.scale


func _process(delta: float) -> void:
	_tiempo += delta
	var flotacion := sin(_tiempo * 2.0) * 6.0
	flor.position.y = _base_flor.y + flotacion
	brillo.position.y = _base_brillo.y + flotacion

	var pulso := 0.5 + 0.5 * sin(_tiempo * 3.0)
	brillo.modulate.a = lerpf(0.45, 0.85, pulso)
	brillo.scale = _base_brillo_escala * lerpf(0.85, 1.15, pulso)


func _on_body_entered(body: Node2D) -> void:
	if _recogida or not body is Player:
		return

	_recogida = true
	area.set_deferred("monitoring", false)
	recogida.emit()
	_animar_recogida()


func _animar_recogida() -> void:
	set_process(false)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.15)
	await tween.finished
	queue_free()
