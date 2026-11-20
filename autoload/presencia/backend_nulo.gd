extends Node

## Backend de cámara para plataformas sin CameraServer (por ejemplo Windows).
## La pausa por pérdida de foco sigue funcionando sin este backend.

signal estado_cambiado(estado: String, mensaje: String)
signal datos_actualizados(presencia: bool, confianza: float, latencia_ms: int, fps: float)
signal permiso_resultado(ok: bool, mensaje: String)

var _estado := "no_disponible"
var _mensaje := "La cámara no está disponible en esta plataforma."


func _ready() -> void:
	set_process(false)


func esta_activo() -> bool:
	return false


func get_estado() -> String:
	return _estado


func get_mensaje() -> String:
	return _mensaje


func get_presencia() -> bool:
	return false


func get_confianza() -> float:
	return 0.0


func get_latencia_ms() -> int:
	return 0


func get_fps() -> float:
	return 0.0


func get_nombre() -> String:
	return "Sin cámara"


func iniciar() -> void:
	_estado = "no_disponible"
	estado_cambiado.emit(_estado, _mensaje)


func detener() -> void:
	_estado = "apagado"
	estado_cambiado.emit(_estado, "")


func liberar() -> void:
	detener()


func probar_permiso() -> void:
	_estado = "no_disponible"
	estado_cambiado.emit(_estado, _mensaje)
	permiso_resultado.emit(false, _mensaje)
