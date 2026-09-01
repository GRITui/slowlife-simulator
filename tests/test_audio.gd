extends SceneTree
# ENGINE-014 audio activation gate — orphan signals consumed, synth works.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  audio :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  audio :: %s" % label)

func _handler_for(sig: String) -> String:
	match sig:
		"binthabat_offered": return "_on_binthabat"
		"crop_harvested": return "_on_harvest"
		"craft_completed": return "_on_craft"
	return ""

func _initialize() -> void:
	var am: Node = root.get_node_or_null("AudioManager")
	_check(am != null, "AudioManager autoload registered")
	if am == null:
		await process_frame
		quit(1)
		return
	# Orphan-signal consumers wired.
	var sb: Node = root.get_node("SignalBus")
	am._ensure_init()
	for sig in ["binthabat_offered", "crop_harvested", "craft_completed"]:
		_check(sb.is_connected(sig, Callable(am, _handler_for(sig))),
			"%s consumed by AudioManager" % sig)
	# Synthesis contract: streams prebuilt, 16-bit PCM, sane length.
	for id in ["binthabat", "harvest", "craft", "ui_click", "save"]:
		var s: AudioStreamWAV = am._streams.get(id) as AudioStreamWAV
		_check(s != null and s.data.size() > 0 and s.format == AudioStreamWAV.FORMAT_16_BITS,
			"stream '%s' synthesized (%s samples bytes=%d)" % [id, "16bit", s.data.size() if s else 0])
	# play_sfx no-crash headless (dummy audio driver).
	am.play_sfx("ui_click")
	am.play_sfx("nonexistent")
	_check(true, "play_sfx headless-safe (known + unknown ids)")
	# Recycle rate: orphan count should drop to zero after this task.
	var orphans: int = 0
	for sig in ["binthabat_offered", "crop_harvested", "craft_completed"]:
		if not sb.is_connected(sig, Callable(am, _handler_for(sig))):
			orphans += 1
	_check(orphans == 0, "zero orphan signals remain (%d)" % orphans)
	print("\n=== AUDIO TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("AUDIO GATE FAILED")
	await process_frame
	quit(1 if _failed > 0 else 0)
