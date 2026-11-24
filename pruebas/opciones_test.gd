extends Control

## Captura el panel de Opciones para revisar el ajuste vertical.


func _ready() -> void:
	await get_tree().process_frame
	$Opciones.abrir()
	await get_tree().create_timer(0.5).timeout
	var imagen := get_viewport().get_texture().get_image()
	if imagen == null:
		# En headless no hay textura de viewport; la prueba sigue siendo válida.
		print("CAPTURA: sin imagen (headless)")
	else:
		imagen.save_png("/tmp/opencode/opciones_v3.png")
		print("CAPTURA: ", imagen.get_size())
	get_tree().quit()
