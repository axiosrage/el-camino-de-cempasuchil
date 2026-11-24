extends Node

## Configuración persistente de audio, vídeo y pausa automática.
## Se aplica al arrancar y cada vez que el jugador cambia una opción.

signal pausa_cambiada

const RUTA_CONFIG := "user://configuracion.cfg"
const VOLUMEN_DEFECTO := 0.8
const ANCHO_DEFECTO := 1152
const ALTO_DEFECTO := 648
const TIEMPOS_PAUSA := [3, 5, 10, 20]
const TIEMPO_PAUSA_DEFECTO := 5
const CLAVE_PANTALLA_ELEGIDA := "pantalla_completa_elegida"

var volumen: float = VOLUMEN_DEFECTO
var pantalla_completa: bool = false
var ventana_ancho: int = ANCHO_DEFECTO
var ventana_alto: int = ALTO_DEFECTO
var pausa_camara: bool = false
var pausa_foco: bool = true
var pausa_tiempo: int = TIEMPO_PAUSA_DEFECTO

var _hay_config: bool = false
var _pantalla_elegida: bool = false
var _iniciando: bool = true


func _ready() -> void:
	cargar()
	aplicar(false)
	_iniciando = false


func cargar() -> void:
	var config := ConfigFile.new()
	var error := config.load(RUTA_CONFIG)
	if error != OK:
		_hay_config = false
		_pantalla_elegida = false
		pantalla_completa = _es_pc()
		return

	_hay_config = true
	volumen = clampf(float(config.get_value("audio", "volumen", VOLUMEN_DEFECTO)), 0.0, 1.0)

	_pantalla_elegida = bool(config.get_value("video", CLAVE_PANTALLA_ELEGIDA, false))
	var valor_guardado = config.get_value("video", "pantalla_completa", null)
	if valor_guardado == null:
		pantalla_completa = _es_pc()
	else:
		pantalla_completa = bool(valor_guardado)
		# Las versiones anteriores guardaban el valor por defecto sin que el
		# jugador lo eligiera: en PC arrancamos en pantalla completa.
		if not _pantalla_elegida and _es_pc():
			pantalla_completa = true

	ventana_ancho = clampi(int(config.get_value("video", "ventana_ancho", ANCHO_DEFECTO)), 640, 7680)
	ventana_alto = clampi(int(config.get_value("video", "ventana_alto", ALTO_DEFECTO)), 360, 4320)
	pausa_camara = bool(config.get_value("pausa", "camara", false))
	pausa_foco = bool(config.get_value("pausa", "foco", true))
	pausa_tiempo = int(config.get_value("pausa", "tiempo", TIEMPO_PAUSA_DEFECTO))
	if not TIEMPOS_PAUSA.has(pausa_tiempo):
		pausa_tiempo = TIEMPO_PAUSA_DEFECTO


func guardar() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volumen", volumen)
	config.set_value("video", "pantalla_completa", pantalla_completa)
	config.set_value("video", CLAVE_PANTALLA_ELEGIDA, _pantalla_elegida)
	config.set_value("video", "ventana_ancho", ventana_ancho)
	config.set_value("video", "ventana_alto", ventana_alto)
	config.set_value("pausa", "camara", pausa_camara)
	config.set_value("pausa", "foco", pausa_foco)
	config.set_value("pausa", "tiempo", pausa_tiempo)
	var error := config.save(RUTA_CONFIG)
	if error != OK:
		push_warning("No se pudo guardar la configuración (error %d)" % error)


func aplicar(desde_usuario: bool = true) -> void:
	aplicar_volumen()
	aplicar_pantalla(desde_usuario)


func set_volumen(valor: float) -> void:
	volumen = clampf(valor, 0.0, 1.0)
	aplicar_volumen()
	guardar()


func set_pantalla_completa(activa: bool) -> void:
	if activa == pantalla_completa:
		return
	pantalla_completa = activa
	_pantalla_elegida = true
	aplicar_pantalla(true)
	guardar()


func set_pausa_camara(activa: bool) -> void:
	if activa == pausa_camara:
		return
	pausa_camara = activa
	guardar()
	pausa_cambiada.emit()


func set_pausa_foco(activa: bool) -> void:
	if activa == pausa_foco:
		return
	pausa_foco = activa
	guardar()
	pausa_cambiada.emit()


func set_pausa_tiempo(segundos: int) -> void:
	if not TIEMPOS_PAUSA.has(segundos):
		segundos = TIEMPO_PAUSA_DEFECTO
	if segundos == pausa_tiempo:
		return
	pausa_tiempo = segundos
	guardar()
	pausa_cambiada.emit()


func aplicar_volumen() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_mute(bus, volumen <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volumen, 0.001)))


func aplicar_pantalla(desde_usuario: bool = true) -> void:
	if DisplayServer.get_name() == "headless":
		return

	_notificar_pantalla_web(pantalla_completa)

	# El navegador solo permite pedir pantalla completa desde una acción del
	# jugador. Al cargar la página avisamos al script web, pero no la pedimos.
	if _iniciando and not desde_usuario and OS.has_feature("web"):
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


func _es_pc() -> bool:
	return not OS.has_feature("web") and DisplayServer.get_name() != "headless"


## En web, el navegador reserva Esc para salir de pantalla completa. El script
## web mantiene el modo mientras la opción siga activa en Ajustes.
func _notificar_pantalla_web(activa: bool) -> void:
	if not OS.has_feature("web"):
		return

	var valor := "true" if activa else "false"
	var codigo := "window.__mictlanPantallaCompletaDeseada = %s; if (window.PantallaCompletaWeb) window.PantallaCompletaWeb.notificar(%s);" % [valor, valor]
	JavaScriptBridge.eval(codigo)
