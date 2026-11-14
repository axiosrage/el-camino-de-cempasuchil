extends Control

## Intro de cómic: muestra las páginas de assets/Intro viñeta por viñeta.
## Avanza sola y se puede saltar con Esc o con el botón inferior.

signal panel_mostrado(indice: int)
signal intro_terminada

const PAGINAS: Array[Texture2D] = [
	preload("res://assets/intro/intro01.png"),
	preload("res://assets/intro/intro02.png"),
	preload("res://assets/intro/intro03.png"),
	preload("res://assets/intro/intro04.png"),
	preload("res://assets/intro/intro05.png"),
]

# Cada entrada recorta una viñeta de una página. La primera incluye el
# título de la historia y la viñeta de apertura para que no quede como
# una franja demasiado fina en pantalla.
const PANELES := [
	{"pagina": 0, "region": Rect2(15, 12, 998, 493), "duracion": 6.0},
	{"pagina": 0, "region": Rect2(15, 519, 424, 530), "duracion": 4.0},
	{"pagina": 0, "region": Rect2(453, 519, 560, 530), "duracion": 4.5},
	{"pagina": 0, "region": Rect2(15, 1066, 998, 455), "duracion": 4.5},
	{"pagina": 1, "region": Rect2(12, 12, 398, 478), "duracion": 4.5},
	{"pagina": 1, "region": Rect2(423, 12, 591, 478), "duracion": 4.0},
	{"pagina": 1, "region": Rect2(12, 504, 485, 649), "duracion": 3.5},
	{"pagina": 1, "region": Rect2(510, 504, 504, 649), "duracion": 3.0},
	{"pagina": 1, "region": Rect2(12, 1166, 1001, 353), "duracion": 4.5},
	{"pagina": 2, "region": Rect2(0, 0, 1024, 357), "duracion": 4.0},
	{"pagina": 2, "region": Rect2(0, 373, 1024, 356), "duracion": 4.5},
	{"pagina": 2, "region": Rect2(0, 744, 497, 402), "duracion": 4.0},
	{"pagina": 2, "region": Rect2(511, 744, 513, 402), "duracion": 4.0},
	{"pagina": 2, "region": Rect2(0, 1160, 1024, 376), "duracion": 6.0},
	{"pagina": 3, "region": Rect2(6, 4, 865, 578), "duracion": 5.5},
	{"pagina": 3, "region": Rect2(884, 4, 397, 578), "duracion": 4.5},
	{"pagina": 3, "region": Rect2(6, 596, 1274, 617), "duracion": 6.5},
	{"pagina": 4, "region": Rect2(6, 6, 389, 384), "duracion": 4.5},
	{"pagina": 4, "region": Rect2(400, 6, 618, 384), "duracion": 5.0},
	{"pagina": 4, "region": Rect2(6, 395, 757, 736), "duracion": 7.5},
	{"pagina": 4, "region": Rect2(770, 395, 248, 736), "duracion": 3.0},
	{"pagina": 4, "region": Rect2(6, 1139, 1012, 390), "duracion": 4.5},
]

const MARGEN_MARCO := 6.0
const DURACION_ENTRADA := 0.55
const DURACION_CAMBIO_PANEL := 0.16
const DURACION_SALIDA := 0.35

@onready var area_panel: Control = $AreaPanel
@onready var marco: Panel = $AreaPanel/Marco
@onready var panel_imagen: TextureRect = $AreaPanel/PanelImagen
@onready var contador: Label = $HUD/HBox/Contador
@onready var barra: ProgressBar = $HUD/HBox/Barra
@onready var boton_saltar: Button = $HUD/HBox/Saltar
@onready var fade_rect: ColorRect = $FadeRect
@onready var temporizador: Timer = $Temporizador

var _indice := -1
var _atlas_actual: AtlasTexture
var _duracion_actual := 0.0
var _bloqueado := true
var _saliendo := false
var _cambiando_panel := false


func _ready() -> void:
	get_viewport().size_changed.connect(_ajustar_panel)
	boton_saltar.pressed.connect(_on_saltar_pressed)
	temporizador.timeout.connect(_on_temporizador_timeout)
	barra.max_value = 1.0
	barra.value = 0.0
	fade_rect.modulate.a = 1.0
	_mostrar_panel(0)
	await get_tree().process_frame
	_ajustar_panel()
	await _fundir_entrada()
	_bloqueado = false
	_iniciar_temporizador()


func _process(_delta: float) -> void:
	if _saliendo or temporizador.is_stopped():
		return
	if temporizador.wait_time > 0.0:
		barra.value = 1.0 - temporizador.time_left / temporizador.wait_time


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_saltar_pressed()
		get_viewport().set_input_as_handled()


func _mostrar_panel(indice: int) -> void:
	_indice = indice
	var datos: Dictionary = PANELES[indice]
	var region: Rect2 = datos["region"]

	_atlas_actual = AtlasTexture.new()
	_atlas_actual.atlas = PAGINAS[datos["pagina"]]
	_atlas_actual.region = region
	_atlas_actual.filter_clip = true
	panel_imagen.texture = _atlas_actual
	panel_imagen.modulate.a = 0.0

	_duracion_actual = datos["duracion"]
	contador.text = "PANEL %d / %d" % [indice + 1, PANELES.size()]
	barra.value = 0.0
	_ajustar_panel()

	var tween := create_tween()
	tween.tween_property(panel_imagen, "modulate:a", 1.0, DURACION_CAMBIO_PANEL)
	panel_mostrado.emit(indice)


func _ajustar_panel() -> void:
	if panel_imagen.texture == null or area_panel.size.x <= 0.0 or area_panel.size.y <= 0.0:
		return

	var tam_textura := panel_imagen.texture.get_size()
	if tam_textura.x <= 0.0 or tam_textura.y <= 0.0:
		return

	var escala := minf(area_panel.size.x / tam_textura.x, area_panel.size.y / tam_textura.y)
	var tam_panel := (tam_textura * escala).floor()
	var posicion := ((area_panel.size - tam_panel) / 2.0).floor()

	panel_imagen.position = posicion
	panel_imagen.size = tam_panel
	marco.position = posicion - Vector2(MARGEN_MARCO, MARGEN_MARCO)
	marco.size = tam_panel + Vector2(MARGEN_MARCO * 2.0, MARGEN_MARCO * 2.0)


func _iniciar_temporizador() -> void:
	if _saliendo:
		return
	_cambiando_panel = false
	temporizador.start(_duracion_actual)


func _on_temporizador_timeout() -> void:
	if _saliendo:
		return

	barra.value = 1.0
	if _indice >= PANELES.size() - 1:
		_terminar_intro()
	else:
		_avanzar_panel()


func _avanzar_panel() -> void:
	if _cambiando_panel or _saliendo:
		return
	_cambiando_panel = true
	temporizador.stop()

	var tween := create_tween()
	tween.tween_property(panel_imagen, "modulate:a", 0.0, DURACION_CAMBIO_PANEL)
	await tween.finished
	if _saliendo:
		return

	_mostrar_panel(_indice + 1)
	_iniciar_temporizador()


func _on_saltar_pressed() -> void:
	if _bloqueado or _saliendo:
		return
	_terminar_intro()


func _terminar_intro() -> void:
	if _saliendo:
		return
	_saliendo = true
	temporizador.stop()
	barra.value = 1.0
	boton_saltar.disabled = true
	intro_terminada.emit()

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, DURACION_SALIDA)
	await tween.finished
	get_tree().change_scene_to_file("res://escenas/Nivel1.tscn")


func _fundir_entrada() -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, DURACION_ENTRADA)
	await tween.finished
