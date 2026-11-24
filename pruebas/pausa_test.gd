extends Control

## Captura el menú de pausa automática para revisar su aspecto.


func _ready() -> void:
	await get_tree().process_frame
	$Pausa.pausar_automatico("presencia")
	await get_tree().create_timer(0.4).timeout
	var imagen := get_viewport().get_texture().get_image()
	if imagen == null:
		# En headless no hay textura de viewport; la prueba sigue siendo válida.
		print("CAPTURA PAUSA: sin imagen (headless)")
	else:
		imagen.save_png("/tmp/opencode/pausa_auto_v3.png")
		print("CAPTURA PAUSA: ", imagen.get_size())
	get_tree().quit()
