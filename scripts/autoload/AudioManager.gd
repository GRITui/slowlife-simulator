extends Node
# AudioManager — TASK-021 / ENGINE-014 activated. Synthesizes cozy SFX
# programmatically (AudioStreamWAV PCM — no binary assets, headless-safe),
# consumes the previously-orphaned signals, and exposes play_sfx for callers.

const SFX_DEFS: Dictionary = {
	"binthabat": {"freq": 660.0, "ms": 160, "second": 880.0},  # soft bell
	"harvest": {"freq": 440.0, "ms": 110, "second": 0.0},      # pop
	"craft": {"freq": 523.0, "ms": 140, "second": 659.0},      # chime
	"ui_click": {"freq": 330.0, "ms": 60, "second": 0.0},      # tick
	"save": {"freq": 392.0, "ms": 130, "second": 523.0},       # confirm
}
const SFX_DB: float = -12.0

var bus_volumes: Dictionary = {"Master": 0.0, "Music": 0.0, "SFX": 0.0}
var _streams: Dictionary = {}
var _player: AudioStreamPlayer = null
var _initialized: bool = false

## Idempotent init — _ready may not fire for autoloads under `--script`
## test runners, so every entry point guarantees setup (ENGINE-014).
func _ensure_init() -> void:
	if _initialized:
		return
	_initialized = true
	_player = AudioStreamPlayer.new()
	_player.name = "SfxPlayer"
	_player.volume_db = SFX_DB
	add_child(_player)
	for id: String in SFX_DEFS.keys():
		_streams[id] = _synthesize(SFX_DEFS[id])
	# ENGINE-014: previously-orphaned signals now have a live consumer.
	SignalBus.binthabat_offered.connect(_on_binthabat)
	SignalBus.crop_harvested.connect(_on_harvest)
	SignalBus.craft_completed.connect(_on_craft)

func _ready() -> void:
	_ensure_init()

func _synthesize(def: Dictionary) -> AudioStreamWAV:
	var freq: float = float(def["freq"])
	var second: float = float(def.get("second", 0.0))
	var ms: int = int(def["ms"])
	var rate: int = 22050
	var samples: int = int(rate * ms / 1000.0)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)
	for i: int in samples:
		var t: float = float(i) / float(rate)
		var envelope: float = 1.0 - float(i) / float(samples) # gentle decay
		var v: float = sin(TAU * freq * t) * 0.5
		if second > 0.0 and float(i) > float(samples) / 2.0:
			v = sin(TAU * second * t) * 0.5
		var pcm: int = int(clampf(v * envelope, -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, pcm)
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	return wav

func play_sfx(id: String) -> void:
	_ensure_init()
	if id.is_empty() or not _streams.has(id) or _player == null:
		return
	_player.stream = _streams[id] as AudioStreamWAV
	_player.play()

func _on_binthabat(_item_id: String, _yield: int) -> void:
	play_sfx("binthabat")

func _on_harvest(_crop_id: int) -> void:
	play_sfx("harvest")

func _on_craft(_item_id: String, _qty: int) -> void:
	play_sfx("craft")

func play_music(_id: String) -> void:
	pass # ambient loop lands with authored audio assets (TASK-021 art lane)

func set_volume(bus: String, db: float) -> void:
	bus_volumes[bus] = db
	if bus == "SFX" and _player != null:
		_player.volume_db = SFX_DB + db
