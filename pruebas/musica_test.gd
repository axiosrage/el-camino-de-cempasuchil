extends Node

## Prueba de la música: pistas en bucle, fundido cruzado y sin reinicios
## innecesarios al volver a pedir la misma canción.
## Uso: godot --headless --path . pruebas/musica_test.tscn

var _fallos: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_comprobar(Musica.process_mode == Node.PROCESS_MODE_ALWAYS, "la música sigue activa en pausa")
	_comprobar(Musica.pista_actual().is_empty(), "no hay pista al empezar")

	Musica.reproducir_menu()
	await get_tree().process_frame
	var menu_player = Musica.get("_activo")
	_comprobar(Musica.pista_actual() == "menu", "se elige la pista de menú")
	_comprobar(menu_player != null and menu_player.playing, "la pista de menú suena")
	_comprobar(menu_player.stream.loop, "la pista de menú está en bucle")

	await get_tree().create_timer(1.2).timeout
	_comprobar(menu_player.volume_db > -13.5, "la pista de menú alcanza su volumen")

	Musica.reproducir_juego()
	await get_tree().process_frame
	var juego_player = Musica.get("_activo")
	_comprobar(Musica.pista_actual() == "juego", "se elige la pista de juego")
	_comprobar(juego_player != null and juego_player.playing, "la pista de juego suena")
	_comprobar(juego_player.stream.loop, "la pista de juego está en bucle")
	_comprobar(juego_player != menu_player, "el fundido usa el otro reproductor")

	await get_tree().create_timer(1.3).timeout
	_comprobar(not menu_player.playing, "la pista anterior se detiene tras el fundido")
	_comprobar(juego_player.volume_db > -13.5, "la pista de juego alcanza su volumen")

	var antes: float = juego_player.get_playback_position()
	Musica.reproducir_juego()
	await get_tree().create_timer(0.2).timeout
	_comprobar(Musica.get("_activo") == juego_player, "pedir la misma pista no cambia de voz")
	_comprobar(Musica.pista_actual() == "juego", "pedir la misma pista conserva la selección")
	_comprobar(juego_player.get_playback_position() > antes, "pedir la misma pista no la reinicia")

	Musica.detener()
	await get_tree().create_timer(1.2).timeout
	_comprobar(not juego_player.playing, "detener apaga la música")
	_comprobar(Musica.pista_actual().is_empty(), "detener limpia la pista actual")

	if _fallos.is_empty():
		print("PRUEBA MÚSICA OK")
	else:
		print("PRUEBA MÚSICA FALLIDA: %s" % [_fallos])
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("  OK: ", mensaje)
	else:
		_fallos.append(mensaje)
