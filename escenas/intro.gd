extends Control

## Intro de cómic: muestra las viñetas de assets/intro/Historia_Mictlán.
## Cada imagen es ya un panel completo en 16:9, así que no hay que recortar
## páginas. Avanza sola. Espacio, Enter o A saltan al siguiente panel; Esc, B
## o el botón «SALTAR INTRO» saltan la intro completa.

signal panel_mostrado(indice: int)
signal intro_terminada

# Duraciones en segundos. La apertura y el cierre se dejan un poco más para
# poder leer el título y el último texto.
const PANELES := [
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta1.png"), "duracion": 6.0},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta2.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta3.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta4.png"), "duracion": 4.0},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta5.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta6.png"), "duracion": 4.0},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta7.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta8.png"), "duracion": 4.0},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta9.png"), "duracion": 5.0},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta10.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta11.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta12.png"), "duracion": 4.0},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta13.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta14.png"), "duracion": 5.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta15.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta16.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta17.png"), "duracion": 5.0},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta18.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta19.png"), "duracion": 4.0},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta20.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta21.png"), "duracion": 5.0},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta22.png"), "duracion": 4.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta23.png"), "duracion": 5.5},
	{"imagen": preload("res://assets/intro/Historia_Mictlán/viñeta24.png"), "duracion": 6.0},
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
var _duracion_actual := 0.0
var _bloqueado := true
var _saliendo := false
var _cambiando_panel := false


func _ready() -> void:
	Musica.reproducir_menu()
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
		return

	if event.is_action_pressed("ui_accept"):
		_saltar_panel_actual()
		get_viewport().set_input_as_handled()


func _mostrar_panel(indice: int) -> void:
	_indice = indice
	var datos: Dictionary = PANELES[indice]
	panel_imagen.texture = datos["imagen"]
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


## Espacio, Enter o A: pasa al siguiente panel sin esperar la duración.
## En el último panel termina la intro.
func _saltar_panel_actual() -> void:
	if _bloqueado or _saliendo or _cambiando_panel:
		return
	if _indice >= PANELES.size() - 1:
		_terminar_intro()
	else:
		_avanzar_panel()


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
