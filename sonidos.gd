extends Node

## Reproduce los efectos de sonido del juego.
## Los sonidos de interfaz usan un pequeño pool de voces para poder
## solaparse sin cortarse; los del mundo se crean en la posición del evento.

const SONIDOS := {
	"seleccion": preload("res://assets/sonidos/seleccion.mp3"),
	"tomar_gema": preload("res://assets/sonidos/tomar_gema.mp3"),
	"golpe_piedra": preload("res://assets/sonidos/golpe_piedra.mp3"),
	"enemigo_desarmado": preload("res://assets/sonidos/enemigo_desarmado.mp3"),
	"perder_ahogarse": preload("res://assets/sonidos/perder_ahogarse.mp3"),
	"game_over": preload("res://assets/sonidos/game_over.mp3"),
	"pasos_esqueleto": preload("res://assets/sonidos/pasos_esqueleto.mp3"),
}

const VOCES_UI := 4
const VOLUMEN_UI := -10.0
const VOLUMEN_MUNDO := -4.0
const COOLDOWN_SELECCION_MS := 200

var _voces_ui: Array[AudioStreamPlayer] = []
var _indice_ui: int = 0
var _ultima_seleccion_ms: int = -10000


func _ready() -> void:
	for i in range(VOCES_UI):
		var voz := AudioStreamPlayer.new()
		voz.bus = &"Master"
		add_child(voz)
		_voces_ui.append(voz)

	get_tree().root.gui_focus_changed.connect(_on_foco_cambiado)
	get_tree().node_added.connect(_on_nodo_agregado)


## Sonido sin posición, para interfaz, muerte y game over.
func reproducir_ui(nombre: String, volumen_db: float = VOLUMEN_UI) -> void:
	var stream := _obtener(nombre)
	if stream == null:
		return

	var voz := _voces_ui[_indice_ui]
	_indice_ui = (_indice_ui + 1) % _voces_ui.size()
	voz.stop()
	voz.stream = stream
	voz.volume_db = volumen_db
	voz.play()


## Duración del efecto en segundos, o 0.0 si el nombre no existe.
func duracion(nombre: String) -> float:
	var stream := _obtener(nombre)
	if stream == null:
		return 0.0
	return stream.get_length()


## Sonido posicional de un evento del nivel. El reproductor se libera solo.
func reproducir_mundo(
	nombre: String,
	posicion: Vector2,
	volumen_db: float = VOLUMEN_MUNDO,
	distancia_max: float = 1100.0
) -> void:
	var stream := _obtener(nombre)
	if stream == null:
		return

	var escena := get_tree().current_scene
	if escena == null:
		return

	var voz := AudioStreamPlayer2D.new()
	voz.stream = stream
	voz.bus = &"Master"
	voz.volume_db = volumen_db
	voz.max_distance = distancia_max
	voz.attenuation = 1.2
	escena.add_child(voz)
	voz.global_position = posicion
	voz.finished.connect(voz.queue_free)
	voz.play()


## Suena al cambiar de foco y al pulsar cualquier botón. El cooldown evita
## que un mismo clic reproduzca el sonido dos veces.
func seleccionar() -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - _ultima_seleccion_ms < COOLDOWN_SELECCION_MS:
		return
	_ultima_seleccion_ms = ahora
	reproducir_ui("seleccion", VOLUMEN_UI)


func _on_foco_cambiado(control: Control) -> void:
	if control == null or not control.is_visible_in_tree():
		return
	if control is BaseButton:
		if (control as BaseButton).disabled:
			return
	elif not (control is Slider):
		return

	seleccionar()


func _on_nodo_agregado(nodo: Node) -> void:
	if nodo is BaseButton:
		var boton := nodo as BaseButton
		if not boton.pressed.is_connected(seleccionar):
			boton.pressed.connect(seleccionar)


func _obtener(nombre: String) -> AudioStream:
	if not SONIDOS.has(nombre):
		push_warning("Sonido desconocido: %s" % nombre)
		return null
	return SONIDOS[nombre]
