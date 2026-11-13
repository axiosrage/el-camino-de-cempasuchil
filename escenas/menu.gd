extends Control

@onready var jugar: Button = $VBoxContainer/jugar
@onready var salir: Button = $VBoxContainer/salir
@onready var fade_rect: ColorRect = $FadeRect


func _ready() -> void:
	jugar.pivot_offset = jugar.size / 2
	salir.pivot_offset = salir.size / 2
	fade_rect.visible = true
	# Configuramos el rectángulo negro para que empiece invisible y no bloquee clics
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jugar.grab_focus()

func _on_jugar_pressed() -> void:
	# Desactivamos los botones para evitar múltiples clics
	jugar.disabled = true
	salir.disabled = true
	
	# Activamos el filtro para bloquear clics en la pantalla durante el desvanecimiento
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Creamos un tween paralelo para animar varias cosas a la vez
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# 1. El botón da un pequeño salto estético hacia adentro/afuera
	tween.tween_property(jugar, "scale", Vector2(1.15, 1.15), 0.3)
	
	# 2. La pantalla completa se hace negra gradualmente (Fade to black)
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	
	# Esperamos a que terminen las animaciones
	await tween.finished
	
	# Empezamos una partida nueva con la vida llena y sin checkpoint.
	EstadoJuego.nueva_partida()
	
	# Cambiamos de escena
	get_tree().change_scene_to_file("res://escenas/Nivel1.tscn")

func _on_jugar_mouse_entered() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(jugar, "scale", Vector2(1.05, 1.05), 0.1)

func _on_jugar_mouse_exited() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(jugar, "scale", Vector2(1, 1), 0.1)

func _on_salir_pressed() -> void:
	get_tree().quit()

func _on_salir_mouse_entered() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(salir, "scale", Vector2(1.05, 1.05), 0.1)

func _on_salir_mouse_exited() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(salir, "scale", Vector2(1, 1), 0.1)
