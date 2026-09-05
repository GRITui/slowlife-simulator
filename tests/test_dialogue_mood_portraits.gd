extends SceneTree
# TASK-377 gate — mood-portrait plumbing on top of TASK-376's dialogue
# portrait. Adds coverage for:
#   1. SignalBus.show_dialogue_with_mood exists.
#   2. PORTRAIT_PATHS is a nested dict covering all 12 speakers x their
#      locked mood-set sizes (9 for the 6 non-romance, 11 for the 6
#      romance candidates).
#   3. The 6 already-shipped speakers' "neutral" entries still point
#      at the EXACT unchanged flat paths from TASK-376 (regression
#      guard — renaming/moving those files would break shipped art).
#   4. show_dialogue_with_mood("Elder", ..., "happy") falls back to
#      the neutral portrait when the mood-specific PNG doesn't exist
#      yet (the art batch is still running), with a real
#      ResourceLoader.exists() against the real filesystem.
#   5. show_dialogue_with_mood("Ek", ..., "happy") hides the portrait
#      cleanly when NEITHER the mood PNG nor the neutral PNG exists on
#      disk (Ek has no art at all yet — must not crash on a
#      totally-absent asset).
#   6. The ORIGINAL plain show_dialogue signal/handler still behaves
#      identically — this is the "did not regress TASK-376" gate.
#
# Same scene-tree-wired pattern as test_dialogue_portrait.gd (TASK-376)
# — instances the real World.tscn, drives the real SignalBus, checks
# the real Portrait TextureRect node. No mocks.

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  dialogue-mood-portraits :: %s" % label)
	else:
		_failed += 1
		print("  FAIL  dialogue-mood-portraits :: %s" % label)

func _initialize() -> void:
	var sb: Node = root.get_node("SignalBus")

	# --- A. SignalBus shape ---
	_check(sb.has_signal("show_dialogue_with_mood"),
		"SignalBus has show_dialogue_with_mood signal")
	# Confirm the new signal's signature is (String, String, String) — the
	# same speaker/text shape as show_dialogue plus a mood String arg.
	var mood_signal_info: Dictionary = {}
	for s in sb.get_signal_list():
		if String(s.get("name", "")) == "show_dialogue_with_mood":
			mood_signal_info = s
			break
	var arg_names: Array = mood_signal_info.get("args", [])
	# get_signal_list() reports each arg's "type" as an int Variant.Type
	# enum value (TYPE_STRING = 4, etc.), NOT a string. type_string() is
	# the global helper that turns an int Variant.Type into its name.
	var arg_types: Array = []
	for a in arg_names:
		arg_types.append(type_string(int(a.get("type", 0))))
	_check(arg_names.size() == 3,
		"show_dialogue_with_mood has exactly 3 args (speaker, text, mood), got %d" % arg_names.size())
	_check(arg_types == ["String", "String", "String"],
		"show_dialogue_with_mood arg types are (String, String, String), got %s" % str(arg_types))
	# The original show_dialogue must be untouched.
	_check(sb.has_signal("show_dialogue"),
		"SignalBus still has the original show_dialogue signal (TASK-376 regression guard)")

	# --- B. PORTRAIT_PATHS structure ---
	# Pull the const off the loaded script (World.gd must compile first
	# for this to work, which run_gate.sh guarantees via --import).
	var world_script: GDScript = load("res://scenes/core/World.gd") as GDScript
	_check(world_script != null, "scenes/core/World.gd loaded as GDScript")
	if world_script == null:
		print("\n=== DIALOGUE-MOOD-PORTRAITS TESTS: %d passed, %d failed ===" % [_passed, _failed])
		quit(1)
		return
	var portrait_paths: Dictionary = world_script.get("PORTRAIT_PATHS")
	_check(portrait_paths != null and not portrait_paths.is_empty(),
		"PORTRAIT_PATHS is a non-empty Dictionary")

	# All 12 speakers present.
	var expected_all_speakers := ["Elder", "Child", "Handler", "Monk", "Trader", "Buffalo",
		"Ek", "Fah", "Ploy", "Chang", "Klong", "Yaa"]
	for sp in expected_all_speakers:
		_check(portrait_paths.has(sp),
			"PORTRAIT_PATHS has entry for speaker '%s'" % sp)

	# 6 non-romance speakers must each have EXACTLY the 9 universal moods.
	var expected_universal := ["neutral", "happy", "excited", "sad", "angry",
		"disappointed", "worry", "tired", "bored"]
	for sp in ["Elder", "Child", "Handler", "Monk", "Trader", "Buffalo"]:
		var moods_v: Variant = portrait_paths.get(sp, {})
		# Check it's actually a Dictionary, not a stale String from the
		# old flat shape — a literal regression guard for the data
		# structure restructure itself.
		_check(typeof(moods_v) == TYPE_DICTIONARY,
			"PORTRAIT_PATHS['%s'] is a nested Dictionary (not the old flat String)" % sp)
		var moods: Dictionary = moods_v
		_check(moods.size() == 9,
			"PORTRAIT_PATHS['%s'] has exactly 9 moods (universal set), got %d" % [sp, moods.size()])
		for m in expected_universal:
			_check(moods.has(m),
				"PORTRAIT_PATHS['%s'] has mood '%s'" % [sp, m])

	# 6 romance candidates must each have EXACTLY the 9 universal PLUS
	# in_love and shy (11 total).
	var expected_romance_extra := ["in_love", "shy"]
	for sp in ["Ek", "Fah", "Ploy", "Chang", "Klong", "Yaa"]:
		var moods_v: Variant = portrait_paths.get(sp, {})
		_check(typeof(moods_v) == TYPE_DICTIONARY,
			"PORTRAIT_PATHS['%s'] is a nested Dictionary (not the old flat String)" % sp)
		var moods: Dictionary = moods_v
		_check(moods.size() == 11,
			"PORTRAIT_PATHS['%s'] has exactly 11 moods (9 universal + in_love + shy), got %d" % [sp, moods.size()])
		for m in expected_universal:
			_check(moods.has(m),
				"PORTRAIT_PATHS['%s'] has universal mood '%s'" % [sp, m])
		for m in expected_romance_extra:
			_check(moods.has(m),
				"PORTRAIT_PATHS['%s'] has romance-only mood '%s'" % [sp, m])

	# --- C. Regression guard: the 6 already-shipped neutrals must still
	# point at the EXACT unchanged TASK-376 flat paths (no rename). ---
	var regression_paths := {
		"Elder": "res://assets/ui/portraits/elder.png",
		"Child": "res://assets/ui/portraits/child.png",
		"Handler": "res://assets/ui/portraits/handler.png",
		"Monk": "res://assets/ui/portraits/monk.png",
		"Trader": "res://assets/ui/portraits/trader.png",
		"Buffalo": "res://assets/ui/portraits/buffalo.png",
	}
	for sp in regression_paths.keys():
		var moods_r: Dictionary = portrait_paths.get(sp, {})
		var actual: String = String(moods_r.get("neutral", ""))
		_check(actual == String(regression_paths[sp]),
			"PORTRAIT_PATHS['%s']['neutral'] still points at TASK-376 ship path ('%s')" % [sp, regression_paths[sp]])

	# --- D, E, F. Real scene + real SignalBus + real ResourceLoader ---
	var world: Node = (load("res://scenes/core/World.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var portrait: TextureRect = world.get_node_or_null("DialogueLayer/Panel/Portrait") as TextureRect
	_check(portrait != null, "World.tscn has a real DialogueLayer/Panel/Portrait node")
	if portrait == null:
		world.queue_free()
		print("\n=== DIALOGUE-MOOD-PORTRAITS TESTS: %d passed, %d failed ===" % [_passed, _failed])
		quit(1)
		return

	_check(portrait.visible == false, "Portrait starts hidden before any dialogue")

	# --- F. ORIGINAL plain show_dialogue signal/handler still works ---
	# Re-runs 2 of the existing TASK-376 assertions as a documented
	# regression guard for TASK-377: the new dict structure + new
	# helper must NOT have broken the plain show_dialogue path.
	var sb_plain: Node = sb
	sb_plain.show_dialogue.emit("Elder", "Welcome, traveler.")
	await process_frame
	_check(portrait.visible == true,
		"(regression guard) plain show_dialogue('Elder', ...) still shows Portrait")
	_check(portrait.texture != null,
		"(regression guard) plain show_dialogue('Elder', ...) still sets Portrait.texture")
	var plain_elder_texture: Texture2D = portrait.texture
	sb_plain.show_dialogue.emit("Camera", "Screenshot saved.")
	await process_frame
	_check(portrait.visible == false,
		"(regression guard) plain show_dialogue('Camera', ...) still hides Portrait")

	# --- D. Mood-aware fallback to neutral for an existing speaker ---
	# elder_happy.png does NOT exist on disk yet (the art batch hasn't
	# reached it), so the mood-aware handler must fall back to the
	# neutral elder.png — the SAME image plain show_dialogue("Elder")
	# uses. This is the single most important behavior: the runtime
	# gracefully hides nothing and shows the fallback while art is
	# still generating.
	sb_plain.show_dialogue_with_mood.emit("Elder", "test", "happy")
	await process_frame
	_check(portrait.visible == true,
		"show_dialogue_with_mood('Elder', ..., 'happy') shows Portrait (fallback to neutral)")
	_check(portrait.texture != null,
		"show_dialogue_with_mood('Elder', ..., 'happy') sets a Portrait texture (fallback to neutral)")
	_check(portrait.texture == plain_elder_texture,
		"show_dialogue_with_mood('Elder', ..., 'happy') texture IS the neutral elder.png (same object as plain show_dialogue)")

	# Also assert against the resolved path string, separately from the
	# scene-tree observation, so a future change that re-creates the
	# texture but points at a wrong path still fails.
	# _resolve_portrait_path() is a pure dict-lookup helper (locked
	# spec) — it returns the mood-specific path even if that file is
	# missing on disk; the disk-existence + fallback-to-neutral check
	# happens in _on_show_dialogue_with_mood() above. So the helper
	# returns the happy path here even though elder_happy.png doesn't
	# exist; the OBSERVED scene-tree result (texture == neutral elder.png,
	# visible == true) is what proves the handler's fallback chain works.
	var elder_happy_path: String = String(portrait_paths["Elder"]["happy"])
	var elder_neutral_path: String = String(portrait_paths["Elder"]["neutral"])
	_check(not ResourceLoader.exists(elder_happy_path),
		"precondition: elder_happy.png is NOT yet on disk (art batch still generating)")
	_check(ResourceLoader.exists(elder_neutral_path),
		"precondition: elder_neutral.png IS on disk (TASK-376 ship file)")
	var elder_resolve: String = world.call("_resolve_portrait_path", "Elder", "happy")
	_check(elder_resolve == elder_happy_path,
		"_resolve_portrait_path('Elder', 'happy') returns the mood-specific path ('%s') even when that file is missing on disk (disk check is the handler's job)" % elder_happy_path)

	# Re-emit plain show_dialogue to re-confirm visible state is sane
	# going forward (no double-set lingering state bug introduced by
	# the mood-aware path).
	sb_plain.show_dialogue.emit("Monk", "Peace be with you.")
	await process_frame
	_check(portrait.visible == true and portrait.texture != null,
		"plain show_dialogue('Monk', ...) still works after a mood-aware emission")

	# --- E. Romance candidate with NO art at all ---
	# Ek has zero existing portrait art (no ek_neutral.png on disk, no
	# ek_happy.png on disk). The handler must NOT crash and must hide
	# the Portrait cleanly (both the specific mood AND the neutral
	# fallback fail ResourceLoader.exists()).
	var ek_happy_path: String = String(portrait_paths["Ek"]["happy"])
	var ek_neutral_path: String = String(portrait_paths["Ek"]["neutral"])
	_check(not ResourceLoader.exists(ek_neutral_path),
		"precondition: ek_neutral.png is NOT on disk yet (Ek has no portrait art yet)")
	_check(not ResourceLoader.exists(ek_happy_path),
		"precondition: ek_happy.png is NOT on disk yet (Ek has no portrait art yet)")
	var ek_resolve: String = world.call("_resolve_portrait_path", "Ek", "happy")
	_check(ek_resolve == ek_happy_path,
		"_resolve_portrait_path('Ek', 'happy') returns the mood-specific path ('%s'); disk-existence + fallback-to-neutral is the handler's job" % ek_happy_path)
	sb_plain.show_dialogue_with_mood.emit("Ek", "test", "happy")
	await process_frame
	_check(portrait.visible == false,
		"show_dialogue_with_mood('Ek', ..., 'happy') hides Portrait (Ek has no art at all yet)")

	# Also exercise in_love for a romance candidate — same shape, same
	# expected fallback-to-neutral behavior. Confirms the romance-only
	# moods are wired into the dict AND the resolve helper handles them.
	sb_plain.show_dialogue_with_mood.emit("Fah", "test", "in_love")
	await process_frame
	_check(portrait.visible == false,
		"show_dialogue_with_mood('Fah', ..., 'in_love') hides Portrait (Fah has no art at all yet)")

	world.queue_free()
	print("\n=== DIALOGUE-MOOD-PORTRAITS TESTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		push_error("DIALOGUE-MOOD-PORTRAITS GATE FAILED")
	quit(1 if _failed > 0 else 0)
