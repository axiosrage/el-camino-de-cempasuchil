extends Node

## Estado persistente entre recargas de escena.
## La vida, el checkpoint y los jades viven aquí para que el jugador
## no vuelva siempre a 3 corazones al reaparecer.
##
## También administra las tres ranuras de guardado. Cada ranura es un
## archivo JSON independiente dentro de user://partidas.

const NUM_RANURAS := 3
const DIR_GUARDADO := "user://partidas"
const VERSION_GUARDADO := 1
const ESCENA_NIVEL_1 := "res://escenas/Nivel1.tscn"

var vida_maxima_media: int = 6
var vida_media: int = 6

var checkpoint_escena: String = ""
var checkpoint_posicion: Vector2 = Vector2.ZERO

var jades_recogidos: int = 0
var jades_recogidos_nombres: Array[String] = []
var flor_recogida: bool = false

# Ranura en la que se está jugando. 0 significa que no hay una activa.
var slot_activo: int = 0

# Banderas que Nivel1 consume al arrancar para saber qué estado restaurar.
var partida_cargada: bool = false
var respawn_en_checkpoint: bool = false
var reinicio_completo: bool = false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR_GUARDADO)


func slot_valido(slot: int) -> bool:
	return slot >= 1 and slot <= NUM_RANURAS


func ruta_slot(slot: int) -> String:
	return "%s/ranura_%d.json" % [DIR_GUARDADO, slot]


func hay_partida_guardada() -> bool:
	for slot in range(1, NUM_RANURAS + 1):
		if FileAccess.file_exists(ruta_slot(slot)):
			return true
	return false


## Devuelve la información visible de una ranura sin cargarla.
## Si el archivo existe pero está dañado, existe=true y danada=true.
func info_slot(slot: int) -> Dictionary:
	var base := {"slot": slot, "existe": false, "danada": false}
	if not slot_valido(slot):
		return base

	var ruta := ruta_slot(slot)
	if not FileAccess.file_exists(ruta):
		return base

	var datos := _leer_slot(slot)
	if datos.is_empty():
		base["existe"] = true
		base["danada"] = true
		return base

	var jades: Array = datos.get("jades", [])
	base["existe"] = true
	base["danada"] = false
	base["escena"] = str(datos.get("escena", ESCENA_NIVEL_1))
	base["nivel"] = str(datos.get("nivel_nombre", "NIVEL 1"))
	base["vida_media"] = int(datos.get("vida_media", vida_maxima_media))
	base["vida_maxima_media"] = int(datos.get("vida_maxima_media", vida_maxima_media))
	base["jades"] = jades.size()
	base["flor_recogida"] = bool(datos.get("flor_recogida", false))
	base["fecha"] = str(datos.get("fecha", ""))
	base["posicion"] = datos.get("posicion", Vector2.ZERO)
	return base


func cargar_slot(slot: int) -> bool:
	var datos := _leer_slot(slot)
	if datos.is_empty():
		return false

	slot_activo = slot
	vida_maxima_media = maxi(2, int(datos.get("vida_maxima_media", 6)))
	vida_media = clampi(int(datos.get("vida_media", vida_maxima_media)), 1, vida_maxima_media)

	jades_recogidos_nombres.clear()
	var jades: Array = datos.get("jades", [])
	for nombre in jades:
		var texto := str(nombre)
		if not texto.is_empty() and not jades_recogidos_nombres.has(texto):
			jades_recogidos_nombres.append(texto)
	jades_recogidos = jades_recogidos_nombres.size()
	flor_recogida = bool(datos.get("flor_recogida", false))

	checkpoint_escena = str(datos.get("escena", ESCENA_NIVEL_1))
	checkpoint_posicion = datos.get("posicion", Vector2.ZERO)
	partida_cargada = true
	respawn_en_checkpoint = false
	reinicio_completo = false
	return true


func nueva_partida_en_slot(slot: int) -> bool:
	if not slot_valido(slot):
		return false
	_eliminar_archivo_slot(slot)
	reiniciar_estado()
	slot_activo = slot
	return true


func borrar_slot(slot: int) -> bool:
	if not slot_valido(slot):
		return false
	var existia := FileAccess.file_exists(ruta_slot(slot))
	_eliminar_archivo_slot(slot)
	if slot_activo == slot:
		slot_activo = 0
		reiniciar_estado()
	return existia


func guardar_slot_actual(escena: String, posicion: Vector2, nombre_nivel: String = "NIVEL 1") -> bool:
	if not slot_valido(slot_activo):
		return false

	checkpoint_escena = escena
	checkpoint_posicion = posicion

	var jades: Array[String] = jades_recogidos_nombres.duplicate()
	var datos := {
		"version": VERSION_GUARDADO,
		"escena": escena,
		"nivel_nombre": nombre_nivel,
		"posicion": {"x": posicion.x, "y": posicion.y},
		"vida_media": vida_media,
		"vida_maxima_media": vida_maxima_media,
		"jades": jades,
		"flor_recogida": flor_recogida,
		"fecha": _fecha_actual(),
	}

	var ruta := ruta_slot(slot_activo)
	var temporal := ruta + ".tmp"
	var archivo := FileAccess.open(temporal, FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo abrir el guardado temporal: %s" % temporal)
		return false

	archivo.store_string(JSON.stringify(datos, "\t"))
	archivo.close()

	var dir := DirAccess.open(DIR_GUARDADO)
	if dir == null:
		push_warning("No se pudo abrir la carpeta de guardado: %s" % DIR_GUARDADO)
		return false

	var error := dir.rename(temporal.get_file(), ruta.get_file())
	if error != OK:
		# En algunos sistemas rename no sobrescribe; se elimina el destino
		# anterior y se intenta una vez más.
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
		error = dir.rename(temporal.get_file(), ruta.get_file())

	if error != OK:
		push_warning("No se pudo guardar la ranura %d (error %d)" % [slot_activo, error])
		return false
	return true


func registrar_jade(nombre: String) -> void:
	if nombre.is_empty() or jades_recogidos_nombres.has(nombre):
		return
	jades_recogidos_nombres.append(nombre)
	jades_recogidos = jades_recogidos_nombres.size()


func registrar_flor() -> void:
	flor_recogida = true


## Prepara el reaparecido en la última superficie segura. La vida ya
## viene descontada por el agua. Devuelve false si no hay checkpoint.
func respawn_en_ultimo_suelo() -> bool:
	if checkpoint_posicion == Vector2.ZERO:
		return false

	respawn_en_checkpoint = true
	partida_cargada = false
	reinicio_completo = false
	if checkpoint_escena.is_empty():
		checkpoint_escena = ESCENA_NIVEL_1

	guardar_slot_actual(checkpoint_escena, checkpoint_posicion, "NIVEL 1")
	return true


## Reinicio completo tras perder los tres corazones. La ranura activa
## se borra; Nivel1 la vuelve a crear al arrancar desde el inicio.
func reiniciar_nivel_completo() -> void:
	vida_media = vida_maxima_media
	jades_recogidos = 0
	jades_recogidos_nombres.clear()
	flor_recogida = false
	checkpoint_escena = ""
	checkpoint_posicion = Vector2.ZERO
	partida_cargada = false
	respawn_en_checkpoint = false
	reinicio_completo = true

	if slot_valido(slot_activo):
		_eliminar_archivo_slot(slot_activo)


func reiniciar_estado() -> void:
	vida_media = vida_maxima_media
	checkpoint_escena = ""
	checkpoint_posicion = Vector2.ZERO
	jades_recogidos = 0
	jades_recogidos_nombres.clear()
	flor_recogida = false
	partida_cargada = false
	respawn_en_checkpoint = false
	reinicio_completo = false


func nueva_partida() -> void:
	reiniciar_estado()


func reiniciar_vida() -> void:
	vida_media = vida_maxima_media


func aplicar_dano(medios: int) -> void:
	vida_media = maxi(0, vida_media - medios)


func castigar_agua() -> void:
	# El agua quita un corazón. Si ya no queda vida, el nivel se reinicia
	# por completo desde Nivel1.
	vida_media = maxi(0, vida_media - 2)


func _leer_slot(slot: int) -> Dictionary:
	var ruta := ruta_slot(slot)
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return {}

	var texto := archivo.get_as_text()
	archivo.close()

	var json := JSON.new()
	if json.parse(texto) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}

	var datos = json.data

	var dict: Dictionary = datos
	if int(dict.get("version", 0)) != VERSION_GUARDADO:
		return {}

	var escena := str(dict.get("escena", ""))
	if escena.is_empty() or not ResourceLoader.exists(escena):
		return {}

	if typeof(dict.get("posicion", null)) != TYPE_DICTIONARY:
		return {}
	var posicion := _posicion_desde_datos(dict)
	if not is_finite(posicion.x) or not is_finite(posicion.y):
		return {}

	var maxima := int(dict.get("vida_maxima_media", 0))
	var vida := int(dict.get("vida_media", 0))
	if maxima <= 0 or vida <= 0 or vida > maxima:
		return {}

	if typeof(dict.get("jades", null)) != TYPE_ARRAY:
		return {}

	var jades: Array[String] = []
	for nombre in dict["jades"]:
		if typeof(nombre) == TYPE_STRING:
			var nombre_texto := str(nombre)
			if not nombre_texto.is_empty() and not jades.has(nombre_texto):
				jades.append(nombre_texto)

	dict["jades"] = jades
	dict["posicion"] = posicion
	return dict


func _posicion_desde_datos(datos: Dictionary) -> Vector2:
	var posicion = datos.get("posicion", {})
	if typeof(posicion) != TYPE_DICTIONARY:
		return Vector2.ZERO
	return Vector2(float(posicion.get("x", 0.0)), float(posicion.get("y", 0.0)))


func _fecha_actual() -> String:
	var fecha := Time.get_datetime_dict_from_system()
	return "%02d/%02d/%04d %02d:%02d" % [
		int(fecha["day"]),
		int(fecha["month"]),
		int(fecha["year"]),
		int(fecha["hour"]),
		int(fecha["minute"]),
	]


func _eliminar_archivo_slot(slot: int) -> void:
	var ruta := ruta_slot(slot)
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	var temporal := ruta + ".tmp"
	if FileAccess.file_exists(temporal):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporal))
