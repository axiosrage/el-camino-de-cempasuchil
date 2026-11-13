extends Node

## Estado persistente entre recargas de escena.
## La vida y el checkpoint viven aquí para que el jugador no vuelva
## siempre a 3 corazones al reaparecer.

var vida_maxima_media: int = 6
var vida_media: int = 6

var checkpoint_escena: String = ""
var checkpoint_posicion: Vector2 = Vector2.ZERO


func nueva_partida() -> void:
	vida_media = vida_maxima_media
	checkpoint_escena = ""
	checkpoint_posicion = Vector2.ZERO


func reiniciar_vida() -> void:
	vida_media = vida_maxima_media


func aplicar_dano(medios: int) -> void:
	vida_media = maxi(0, vida_media - medios)


func castigar_agua() -> void:
	# Un corazón menos. De momento se conserva al menos medio corazón
	# para no reaparecer con 0; cuando exista game over, el mínimo será 0.
	vida_media = maxi(1, vida_media - 2)
