extends Node


func _ready() -> void:
	print("pista inicial=", Musica.pista_actual())
	Musica.reproducir_menu()
	await get_tree().process_frame
	var jugador = Musica.get("_activo")
	print("playing=", Musica.esta_reproduciendo(), " pos=", jugador.get_playback_position(), " loop=", jugador.stream.loop, " vol=", jugador.volume_db)
	await get_tree().create_timer(0.6).timeout
	print("pos2=", jugador.get_playback_position(), " vol2=", jugador.volume_db)
	Musica.reproducir_juego()
	await get_tree().process_frame
	var jugador2 = Musica.get("_activo")
	print("juego playing=", jugador2.playing, " loop=", jugador2.stream.loop, " mismo=", jugador2 == jugador)
	await get_tree().create_timer(1.3).timeout
	print("viejo playing=", jugador.playing, " nuevo vol=", jugador2.volume_db)
	Musica.detener()
	await get_tree().create_timer(1.2).timeout
	print("tras detener=", jugador2.playing, " pista=", Musica.pista_actual())
	get_tree().quit()
