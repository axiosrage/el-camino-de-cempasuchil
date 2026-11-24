extends Node

## Comprueba que el backend Linux prioriza cámaras USB/externas.
## Uso: godot --headless --path . pruebas/camara_externa_test.tscn

const BackendLinux = preload("res://autoload/presencia/backend_linux.gd")

var _fallos: Array[String] = []


func _ready() -> void:
	var backend := BackendLinux.new()
	add_child(backend)

	var usb := backend.puntuar_camara(
		"USB Camera", CameraFeed.FEED_UNSPECIFIED, 640, 480, "YUYV 4:2:2"
	)
	var integrada := backend.puntuar_camara(
		"Integrated Camera", CameraFeed.FEED_FRONT, 640, 480, "YUYV 4:2:2"
	)
	_comprobar(usb > integrada, "una cámara USB gana sobre la integrada frontal")

	var webcam := backend.puntuar_camara(
		"Logitech Webcam C920", CameraFeed.FEED_UNSPECIFIED, 1280, 720, "MJPG"
	)
	_comprobar(webcam > integrada, "una webcam externa gana aunque use otro formato")

	var sin_posicion := backend.puntuar_camara(
		"cámara", CameraFeed.FEED_UNSPECIFIED, 320, 240, "YUYV"
	)
	var frontal := backend.puntuar_camara(
		"cámara", CameraFeed.FEED_FRONT, 320, 240, "YUYV"
	)
	_comprobar(sin_posicion > frontal, "sin posición declarada gana sobre la frontal")

	if _fallos.is_empty():
		print("PRUEBA CÁMARA EXTERNA OK")
	else:
		print("PRUEBA CÁMARA EXTERNA FALLIDA: %s" % [_fallos])
	get_tree().quit(0 if _fallos.is_empty() else 1)


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		print("  OK: ", descripcion)
	else:
		_fallos.append(descripcion)
		print("  FALLO: ", descripcion)
