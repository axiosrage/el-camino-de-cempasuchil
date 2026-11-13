extends CanvasLayer

const CORAZON_LLENO: Texture2D = preload("res://assets/materiales/interfaz/barras/sprites/hearts/heart/heart full.png")
# Derivado de heart 50 black.png: recortado a 13x11 y alineado con el corazón lleno.
const CORAZON_MEDIO: Texture2D = preload("res://assets/hud/corazon_medio.png")
const CORAZON_VACIO: Texture2D = preload("res://assets/materiales/interfaz/barras/sprites/hearts/heart/heart empty.png")

@onready var corazones: Array[TextureRect] = [%Corazon1, %Corazon2, %Corazon3]
@onready var icono_jade: TextureRect = %IconoJade
@onready var etiqueta_jades: Label = %CantidadJades

var _vida_previa: int = -1
var _jades_previos: int = -1
var _jades_completados: bool = false


func _ready() -> void:
	actualizar_vida(6, 6)
	actualizar_jades(0, 0)
	# La primera actualización del nivel no debe contar como daño ni recogida.
	_vida_previa = -1
	_jades_previos = -1


func actualizar_vida(vida_media: int, vida_maxima_media: int) -> void:
	var total_corazones := int(ceil(vida_maxima_media / 2.0))

	for i in range(corazones.size()):
		var corazon := corazones[i]
		corazon.visible = i < total_corazones
		if not corazon.visible:
			continue

		var restante := vida_media - i * 2
		if restante >= 2:
			corazon.texture = CORAZON_LLENO
		elif restante == 1:
			corazon.texture = CORAZON_MEDIO
		else:
			corazon.texture = CORAZON_VACIO

	if _vida_previa >= 0 and vida_media < _vida_previa:
		_pulso_corazon(clampi(vida_media / 2, 0, total_corazones - 1))

	_vida_previa = vida_media


func actualizar_jades(recogidos: int, total: int) -> void:
	etiqueta_jades.text = "x %d" % recogidos

	if _jades_previos >= 0 and recogidos > _jades_previos:
		_pulso_jade()

	_jades_previos = recogidos

	if total > 0 and recogidos >= total and not _jades_completados:
		_jades_completados = true
		_destello_jades()


func _pulso_corazon(indice: int) -> void:
	if indice < 0 or indice >= corazones.size():
		return

	var corazon := corazones[indice]
	corazon.modulate = Color(2.5, 2.5, 2.5, 1.0)
	var tween := create_tween()
	tween.tween_property(corazon, "modulate", Color.WHITE, 0.25)


func _pulso_jade() -> void:
	icono_jade.modulate = Color(1.8, 2.0, 1.8, 1.0)
	var tween := create_tween()
	tween.tween_property(icono_jade, "modulate", Color.WHITE, 0.25)


func _destello_jades() -> void:
	var tween := create_tween().set_loops(3)
	tween.tween_property(etiqueta_jades, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.12)
	tween.tween_property(etiqueta_jades, "modulate", Color.WHITE, 0.12)
