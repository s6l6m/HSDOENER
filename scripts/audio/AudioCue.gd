extends Resource
class_name AudioCue

@export var id: AudioPlayerManager.AudioID
@export var stream: AudioStream
@export_range(0.0, 1.0, 0.01) var volume_scale: float = 1.0
@export var loop: bool = false
@export var unpausable: bool = false
