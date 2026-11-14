extends Node

## Configuración persistente de audio y vídeo.
## Se aplica al arrancar y cada vez que el jugador cambia una opción.

const RUTA_CONFIG := "user://configuracion.cfg"
const VOLUMEN_DEFECTO := 0.8
const ANCHO_DEFECTO := 1152
const ALTO_DEFECTO := 648

var volumen: float = VOLUMEN_DEFECTO
var pantalla_completa: bool = false
var ventana_ancho: int = ANCHO_DEFECTO
var ventana_alto: int = ALTO_DEFECTO

var _hay_config: bool = false


func _ready() -> void:
	cargar()
	aplicar()


func cargar() -> void:
	var config := ConfigFile.new()
	var error := config.load(RUTA_CONFIG)
	if error != OK:
		_hay_config = false
		return

	_hay_config = true
	volumen = clampf(float(config.get_value("audio", "volumen", VOLUMEN_DEFECTO)), 0.0, 1.0)
	pantalla_completa = bool(config.get_value("video", "pantalla_completa", false))
	ventana_ancho = clampi(int(config.get_value("video", "ventana_ancho", ANCHO_DEFECTO)), 640, 7680)
	ventana_alto = clampi(int(config.get_value("video", "ventana_alto", ALTO_DEFECTO)), 360, 4320)


func guardar() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volumen", volumen)
	config.set_value("video", "pantalla_completa", pantalla_completa)
	config.set_value("video", "ventana_ancho", ventana_ancho)
	config.set_value("video", "ventana_alto", ventana_alto)
	var error := config.save(RUTA_CONFIG)
	if error != OK:
		push_warning("No se pudo guardar la configuración (error %d)" % error)


func aplicar() -> void:
	aplicar_volumen()
	aplicar_pantalla()


func set_volumen(valor: float) -> void:
	volumen = clampf(valor, 0.0, 1.0)
	aplicar_volumen()
	guardar()


func set_pantalla_completa(activa: bool) -> void:
	if activa == pantalla_completa:
		return
	pantalla_completa = activa
	aplicar_pantalla()
	guardar()


func aplicar_volumen() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_mute(bus, volumen <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volumen, 0.001)))


func aplicar_pantalla() -> void:
	if DisplayServer.get_name() == "headless":
		return

	var modo := DisplayServer.window_get_mode()
	if pantalla_completa:
		if modo == DisplayServer.WINDOW_MODE_WINDOWED:
			var tamano := DisplayServer.window_get_size()
			if tamano.x > 0 and tamano.y > 0:
				ventana_ancho = tamano.x
				ventana_alto = tamano.y

		if modo != DisplayServer.WINDOW_MODE_FULLSCREEN and modo != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return

	var estaba_en_pantalla_completa := modo == DisplayServer.WINDOW_MODE_FULLSCREEN or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if estaba_en_pantalla_completa:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# Solo se restaura el tamaño guardado si hay configuración previa o si
	# se acaba de salir de pantalla completa. Así no se pisa el tamaño que
	# el jugador haya elegido manualmente en una sesión nueva.
	if _hay_config or estaba_en_pantalla_completa:
		var tamano := Vector2i(ventana_ancho, ventana_alto)
		DisplayServer.window_set_size(tamano)
		var pantalla := DisplayServer.screen_get_size()
		DisplayServer.window_set_position((pantalla - tamano) / 2)
