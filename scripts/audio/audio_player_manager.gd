@tool
extends Node
class_name AudioPlayerManager

# -------------------------------------------------
# ENUM
# -------------------------------------------------
enum AudioID {
	# Customer
	CUSTOMER_ENTER,
	CUSTOMER_LEAVE,

	# Stations
	STATION_CUTTING,
	STATION_TRASH,
	STATION_FIRE_ON,
	STATION_FIRE_OFF,
	STATION_FIRE_BURN,
	
	# Plate
	PLATE_TAKE,
	PLATE_PLACE,

	# Player
	PLAYER_MOVE,
	PLAYER_GRAB,
	PLAYER_PUT,

	# Coin
	COIN_UP,
	COIN_DOWN,

	# Time
	TIME_COUNTDOWN,
	TIME_UP,
	
	# Sauce
	SAUCE,
}

# -------------------------------------------------
# CONFIG
# -------------------------------------------------
@export var audio_cues: Array[AudioCue] = []
@export var audio_bus: StringName = &"SFX"

# -------------------------------------------------
# SINGLETON
# -------------------------------------------------
static var _instance: AudioPlayerManager

# Internal lookup (enum → cue)
var _cue_lookup: Dictionary = {}

# -------------------------------------------------
# LIFECYCLE
# -------------------------------------------------
func _ready() -> void:
	_instance = self
	_build_lookup()


func _build_lookup() -> void:
	_cue_lookup.clear()
	for cue in audio_cues:
		if cue == null:
			continue
		if _cue_lookup.has(cue.id):
			push_warning("Duplicate AudioID: %s" % AudioID.keys()[cue.id])
			continue
		_cue_lookup[cue.id] = cue


# -------------------------------------------------
# STATIC API
# -------------------------------------------------

# One-shot sounds (coins, UI, short SFX)
static func play(id: AudioID) -> AudioStreamPlayer:
	if _instance == null:
		push_error("AudioPlayerManager not ready")
		return
	return _instance._play(id)

# Stop and clean up a specific instance
static func stop(player: AudioStreamPlayer) -> void:
	if player != null and player.is_inside_tree():
		player.stop()
		player.queue_free()


# -------------------------------------------------
# INTERNAL
# -------------------------------------------------

func _play(id: AudioID) -> AudioStreamPlayer:
	var cue := _get_cue(id)
	if cue == null:
		push_warning("No AudioCue for AudioID: %s" % AudioID.keys()[id])
		return null

	var player := _create_player(cue)
	player.play()

	# Cleanup only if NOT looping
	if not cue.loop:
		player.finished.connect(func(): player.queue_free())

	return player


func _create_player(cue: AudioCue) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()

	# Duplicate stream so loop state is per-instance
	var stream_instance: AudioStream = cue.stream.duplicate()

	if cue.loop:
		if stream_instance is AudioStreamWAV:
			stream_instance.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif stream_instance is AudioStreamOggVorbis or stream_instance is AudioStreamMP3:
			stream_instance.loop = true

	player.stream = stream_instance
	player.volume_db = linear_to_db(cue.volume_scale)
	player.bus = audio_bus
	add_child(player)

	return player


func _get_cue(id: AudioID) -> AudioCue:
	return _cue_lookup.get(id, null)
