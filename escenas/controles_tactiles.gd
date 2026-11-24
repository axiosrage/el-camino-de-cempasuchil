extends CanvasLayer

## Controles en pantalla para dispositivos móviles.
##
## Aparece solo en pantallas táctiles (o cuando `forzar_visibles` está activo,
## para las pruebas). Cada botón inyecta la misma acción del InputMap que usan
## el teclado y el mando, así que no hace falta duplicar la lógica del jugador.
##
## Se añade al nivel desde `nivel_1.gd` y se muestra por encima del HUD.

const ACCIONES := {
	"Izquierda": "mov_izquierda",
	"Derecha": "mov_derecha",
	"Salto": "salto",
	"Lanzar": "lanzar",
	"Pausa": "pausa",
}

@onready var zona: Control = $Zona

@export var forzar_visibles: bool = false

var _presionadas: Dictionary = {}
var _liberado_en_pausa: bool = false


func _ready() -> void:
	visible = forzar_visibles or _es_tactil()
	for nombre in ACCIONES.keys():
		var boton: Button = zona.get_node(nombre)
		boton.focus_mode = Control.FOCUS_NONE
		boton.button_down.connect(_on_boton_abajo.bind(nombre))
		boton.button_up.connect(_on_boton_arriba.bind(nombre))


func _exit_tree() -> void:
	liberar_todo()


func _process(_delta: float) -> void:
	# Si el juego se pausa mientras un dedo sigue sobre un botón, la acción
	# quedaría pulsada para siempre. Al pausar se sueltan todas.
	if get_tree().paused and not _liberado_en_pausa:
		liberar_todo()
		_liberado_en_pausa = true
	elif not get_tree().paused:
		_liberado_en_pausa = false


func _es_tactil() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func _on_boton_abajo(nombre: String) -> void:
	var accion: String = ACCIONES.get(nombre, "")
	if accion.is_empty():
		return

	# Pausa es un interruptor: se envía el pulso completo y no se mantiene.
	if accion == "pausa":
		_enviar(accion, true)
		_enviar(accion, false)
		return

	if _presionadas.has(accion):
		return
	_presionadas[accion] = true
	_enviar(accion, true)


func _on_boton_arriba(nombre: String) -> void:
	var accion: String = ACCIONES.get(nombre, "")
	if accion.is_empty() or accion == "pausa":
		return
	if not _presionadas.has(accion):
		return

	_presionadas.erase(accion)
	_enviar(accion, false)


func liberar_todo() -> void:
	for accion in _presionadas.keys():
		_enviar(accion, false)
	_presionadas.clear()


func _enviar(accion: String, pulsado: bool) -> void:
	var evento := InputEventAction.new()
	evento.action = accion
	evento.pressed = pulsado
	Input.parse_input_event(evento)
