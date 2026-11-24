extends Node2D

## Portal del final del nivel.
##
## Nace sellado y oscuro. Cuando la flor de cempasúchil es recogida, `activar()`
## lo ilumina y permite entrar. Emite `bloqueado` si el jugador intenta usarlo
## antes de tiempo y `entrado` cuando por fin cruza el umbral.

signal bloqueado
signal entrado

@onready var area: Area2D = $Area2D
@onready var portal: Sprite2D = $Portal
@onready var brillo: Sprite2D = $Brillo

var activo: bool = false
var _entrado: bool = false
var _tiempo: float = 0.0


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	_aplicar_estado()


func activar() -> void:
	if activo:
		return

	activo = true
	brillo.visible = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(portal, "modulate", Color.WHITE, 0.5)
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.2)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.35)


func _process(delta: float) -> void:
	if not activo:
		return

	_tiempo += delta
	var pulso := 0.5 + 0.5 * sin(_tiempo * 2.2)
	brillo.modulate.a = lerpf(0.55, 1.0, pulso)
	brillo.scale = Vector2.ONE * lerpf(1.05, 1.2, pulso)


func _aplicar_estado() -> void:
	brillo.visible = activo
	if not activo:
		portal.modulate = Color(0.42, 0.42, 0.58, 1.0)


func _on_body_entered(body: Node2D) -> void:
	if _entrado or not body is Player:
		return

	if not activo:
		bloqueado.emit()
		return

	_entrado = true
	area.set_deferred("monitoring", false)
	entrado.emit()
