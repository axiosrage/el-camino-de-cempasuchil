extends Node

## Backend falso para probar la lógica de presencia sin cámara.

signal estado_cambiado(estado: String, mensaje: String)
signal datos_actualizados(presencia: bool, confianza: float, latencia_ms: int, fps: float)
signal permiso_resultado(ok: bool, mensaje: String)

var activo := false
var presencia := true
var confianza := 0.9
var latencia := 12
var fps := 5.0


func esta_activo() -> bool:
	return activo


func get_estado() -> String:
	return "activo" if activo else "apagado"


func get_mensaje() -> String:
	return ""


func get_presencia() -> bool:
	return presencia


func get_confianza() -> float:
	return confianza


func get_latencia_ms() -> int:
	return latencia


func get_fps() -> float:
	return fps


func get_nombre() -> String:
	return "Backend falso"


func probar_permiso() -> void:
	estado_cambiado.emit("listo", "Permiso concedido.")
	permiso_resultado.emit(true, "Permiso concedido.")


func iniciar() -> void:
	activo = true
	estado_cambiado.emit("activo", "")
	datos_actualizados.emit(true, 0.9, 12, 5.0)


func detener() -> void:
	activo = false
	estado_cambiado.emit("apagado", "")


func liberar() -> void:
	detener()


func emitir_presencia(valor: bool) -> void:
	presencia = valor
	confianza = 0.9 if valor else 0.05
	datos_actualizados.emit(valor, confianza, 12, 5.0)
