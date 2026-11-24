extends Node

## Salida del juego según la plataforma.
## En escritorio se cierra la ventana. En web se muestra una pantalla de
## despedida antes de detener el motor, para no dejar congelado el último frame.


func salir() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (window.SalidaWeb) window.SalidaWeb.salir();")
		# Damos dos frames al navegador para que pinte la pantalla de salida
		# antes de que el motor se detenga.
		await get_tree().process_frame
		await get_tree().process_frame
	get_tree().quit()
