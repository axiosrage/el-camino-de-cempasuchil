extends Node

## Prueba manual del backend Linux con la cámara real.

var _pausas := 0
var _reanudaciones := 0


func _ready() -> void:
	Configuracion.set_pausa_tiempo(3)
	Configuracion.set_pausa_camara(true)
	DetectorPresencia.pausa_automatica_solicitada.connect(_on_pausa)
	DetectorPresencia.reanudacion_automatica_solicitada.connect(_on_reanudacion)
	DetectorPresencia.activar_en_nivel()

	for i in 15:
		await get_tree().create_timer(1.0).timeout
		print(
			"t=", i + 1,
			" estado=", DetectorPresencia.get_estado_texto(),
			" presencia=", DetectorPresencia.get_presencia(),
			" conf=", DetectorPresencia.get_confianza(),
			" fps=", DetectorPresencia.get_fps(),
			" latencia=", DetectorPresencia.get_latencia_ms(),
			" sin_presencia=", DetectorPresencia.get_segundos_sin_presencia(),
			" pausas=", _pausas,
			" reanudaciones=", _reanudaciones
		)

	DetectorPresencia.desactivar_en_nivel(true)
	Configuracion.set_pausa_camara(false)
	Configuracion.set_pausa_tiempo(5)
	await get_tree().create_timer(1.0).timeout
	print("FIN: pausas=", _pausas, " reanudaciones=", _reanudaciones)
	get_tree().quit()


func _on_pausa(motivo: String) -> void:
	_pausas += 1
	print("  >>> PAUSA AUTOMÁTICA: ", motivo)


func _on_reanudacion(motivo: String) -> void:
	_reanudaciones += 1
	print("  >>> REANUDACIÓN AUTOMÁTICA: ", motivo)
