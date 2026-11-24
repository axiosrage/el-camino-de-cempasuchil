extends Control

## Captura el menú de pausa automática para revisar su aspecto.
## También comprueba que existe el botón «Salir» para abandonar el juego.

var _fallos: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	var pausa := $Pausa
	_comprobar(pausa.boton_salir != null, "el menú de pausa tiene botón Salir")
	_comprobar(pausa.boton_salir.text == "Salir", "el botón Salir está etiquetado")
	_comprobar(pausa._botones.has(pausa.boton_salir), "Salir se incluye en la navegación")
	pausa.pausar_automatico("presencia")
	await get_tree().create_timer(0.4).timeout
	var imagen := get_viewport().get_texture().get_image()
	if imagen == null:
		# En headless no hay textura de viewport; la prueba sigue siendo válida.
		print("CAPTURA PAUSA: sin imagen (headless)")
	else:
		imagen.save_png("/tmp/opencode/pausa_auto_v3.png")
		print("CAPTURA PAUSA: ", imagen.get_size())

	if _fallos.is_empty():
		print("PRUEBA PAUSA OK")
	else:
		print("PRUEBA PAUSA FALLIDA: %s" % [_fallos])
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		print("  OK: ", descripcion)
	else:
		_fallos.append(descripcion)
		print("  FALLO: ", descripcion)
