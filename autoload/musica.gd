extends Node

## Música de fondo del juego.
##
## Mantiene dos reproductores para hacer un fundido cruzado entre la pista
## del menú y la del nivel. Las pistas se reproducen en bucle y siguen el
## volumen general configurado en el bus Master.

var _pista_menu: AudioStream = preload("res://assets/audio/musica menu.mp3")
var _pista_juego: AudioStream = preload("res://assets/audio/musica del juego.mp3")

const VOLUMEN_DB: float = -12.0
const VOLUMEN_SILENCIO_DB: float = -48.0
const DURACION_FUNDIDO: float = 1.0

var _jugador_a: AudioStreamPlayer
var _jugador_b: AudioStreamPlayer
var _activo: AudioStreamPlayer
var _pista_actual: String = ""
var _tween: Tween


func _ready() -> void:
	# La música debe seguir sonando con el árbol en pausa (final del nivel,
	# menú de pausa, etc.).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pista_menu.loop = true
	_pista_juego.loop = true
	_jugador_a = _crear_voz("MusicaA")
	_jugador_b = _crear_voz("MusicaB")
	_activo = _jugador_a


func reproducir_menu() -> void:
	_reproducir("menu", _pista_menu)


func reproducir_juego() -> void:
	_reproducir("juego", _pista_juego)


func detener() -> void:
	_pista_actual = ""
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if _activo == null or not _activo.playing:
		return

	_tween = create_tween()
	_tween.tween_property(_activo, "volume_db", VOLUMEN_SILENCIO_DB, DURACION_FUNDIDO)
	_tween.tween_callback(_activo.stop)


func pista_actual() -> String:
	return _pista_actual


func esta_reproduciendo() -> bool:
	return _activo != null and _activo.playing


func _reproducir(nombre: String, pista: AudioStream) -> void:
	if _activo == null:
		return

	if _pista_actual == nombre:
		if not _activo.playing:
			_activo.stream = pista
			_activo.volume_db = VOLUMEN_DB
			_activo.play()
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()

	var anterior := _activo
	var nuevo := _jugador_b if anterior == _jugador_a else _jugador_a
	_activo = nuevo
	_pista_actual = nombre

	nuevo.stream = pista
	nuevo.volume_db = VOLUMEN_SILENCIO_DB
	nuevo.play()

	_tween = create_tween().set_parallel(true)
	_tween.tween_property(nuevo, "volume_db", VOLUMEN_DB, DURACION_FUNDIDO)
	if anterior.playing:
		_tween.tween_property(anterior, "volume_db", VOLUMEN_SILENCIO_DB, DURACION_FUNDIDO)
		_tween.chain().tween_callback(anterior.stop)


func _crear_voz(nombre: String) -> AudioStreamPlayer:
	var voz := AudioStreamPlayer.new()
	voz.name = nombre
	voz.bus = &"Master"
	voz.volume_db = VOLUMEN_SILENCIO_DB
	add_child(voz)
	return voz
