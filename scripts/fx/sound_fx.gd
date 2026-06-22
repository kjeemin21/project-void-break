class_name SoundFX
extends RefCounted

## One-shot positional sound helper. Spawns a self-freeing AudioStreamPlayer2D so
## a sound outlives the emitter (e.g. a ship that was just destroyed). Safe to
## call with a null stream — it simply does nothing until you assign audio.

static func play_2d(stream: AudioStream, parent: Node, position: Vector2, volume_db: float = 0.0) -> void:
	if stream == null or parent == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	parent.add_child(player)
	player.global_position = position
	player.play()
