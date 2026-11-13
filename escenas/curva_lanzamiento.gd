extends Node2D

var puntos: PackedVector2Array = PackedVector2Array()
var color_linea: Color = Color(1.0, 0.93, 0.62, 0.45)
var color_punto: Color = Color(1.0, 0.86, 0.38, 0.95)


func _ready() -> void:
	visible = false


func mostrar(nuevos_puntos: PackedVector2Array) -> void:
	puntos = nuevos_puntos
	visible = true
	queue_redraw()


func ocultar() -> void:
	if not visible and puntos.is_empty():
		return
	visible = false
	puntos = PackedVector2Array()
	queue_redraw()


func _draw() -> void:
	if puntos.size() < 2:
		return

	draw_polyline(puntos, color_linea, 1.3, true)

	var total := puntos.size()
	for i in range(0, total, 2):
		var t := float(i) / float(maxi(total - 1, 1))
		var radio := lerpf(2.0, 0.8, t)
		draw_circle(puntos[i], radio, color_punto)

	# Marca el punto de impacto estimado.
	draw_arc(puntos[total - 1], 4.0, 0.0, TAU, 20, color_punto, 1.2, true)
