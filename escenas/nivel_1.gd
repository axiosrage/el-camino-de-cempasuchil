extends Node2D

const ESCENA_A_INSTANCIAR = preload("res://escenas/lagarto.tscn")
@onready var player: Player = %Player
@onready var fundido: ColorRect = $Transicion/Fondo
@onready var hud = %HUD

var jades_recogidos: int = 0
var jades_totales: int = 0
var reiniciando: bool = false


func _ready() -> void:
	_preparar_hud()


func _preparar_hud() -> void:
	player.vida_cambiada.connect(Callable(hud, "actualizar_vida"))
	hud.call("actualizar_vida", player.vida_media, player.corazones_max * 2)

	for piedra in $piedras.get_children():
		if piedra.has_signal("recogida"):
			jades_totales += 1
			piedra.connect("recogida", _on_jade_recogido)

	hud.call("actualizar_jades", jades_recogidos, jades_totales)


func _on_jade_recogido() -> void:
	jades_recogidos += 1
	hud.call("actualizar_jades", jades_recogidos, jades_totales)


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

	# La muerte en combate reinicia la vida completa, como antes.
	# La muerte en agua conserva el corazón que ya se descontó.
	if causa != "agua":
		EstadoJuego.reiniciar_vida()

	fundido.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fundido, "color:a", 1.0, 0.5)
	await tween.finished
	get_tree().reload_current_scene()
