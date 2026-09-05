extends Node
## TEMPORARY playtesting aid (2026-09-04) -- NOT part of the shipped game.
## Watches a fixed file path for simple text commands and synthesizes the
## corresponding Input action press/release, so a running game instance can
## be driven from outside the process without macOS Accessibility/System
## Events (which require GUI permission grants this session's automated
## driver doesn't reliably have). Removed once the manual playthrough pass
## is done -- see docs/SHIP_PLAN.md's "Full human playthrough pass" item.
##
## Command file: /tmp/slowlife_debug_input_<pid>.txt (this process's own
## PID -- see CMD_FILE below), one command per line, truncated after each
## read. Per-PID naming fixed a real collision found during this session's
## own playtest attempt: a fixed shared path meant a second (test) Godot
## instance and the owner's already-running window were both polling the
## same file, so debug commands (godmode, teleports) could land in either
## process nondeterministically. Supported lines:
##   press <action_name>
##   release <action_name>
##   tap <action_name>        (press then release next frame)
##   click <node_name>        (find first BaseButton with this exact node
##                             name anywhere in the tree, emit its
##                             `pressed` signal directly -- bypasses mouse/
##                             focus entirely, for menus with no default
##                             keyboard focus set)
##   dump state                (print player global_position, GameData
##                              silver/stamina/harmony, and TimeManager
##                              day/hour/minute to stdout -- lets a driving
##                              script verify state via log instead of
##                              screenshots)
##   godmode on                (testing shortcut, NOT a player-facing
##                              cheat: silver=9999, full stamina, and a
##                              handful of starter seeds/goods added to
##                              inventory, so buy/sell/plant/harvest flows
##                              can be exercised immediately instead of
##                              grinding to earn them first)
## Only does anything in a debug build (OS.is_debug_build()), and only
## reacts if the file actually exists -- inert with zero overhead
## otherwise.

var CMD_FILE := "/tmp/slowlife_debug_input_%d.txt" % OS.get_process_id()
## Diagnostic-only, this session: godot's stdout is unreliably buffered
## when redirected to a file in this headless-playtest setup (prints
## observed arriving minutes late or not at all), so every message this
## driver would otherwise print() is ALSO appended here (opened+closed
## per call, which forces a flush each time) for a channel that can
## actually be tailed live. Also per-PID for the same collision reason.
var LOG_FILE := "/tmp/slowlife_debug_output_%d.log" % OS.get_process_id()

var _tap_release_queue: Array[String] = []

func _log(msg: String) -> void:
	print(msg)
	var f := FileAccess.open(LOG_FILE, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_FILE) else FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line(msg)
		f.close()

func _ready() -> void:
	if OS.is_debug_build():
		SignalBus.show_dialogue.connect(_on_show_dialogue)
		_log("[DebugInputDriver] ready. cmd_file=%s log_file=%s" % [CMD_FILE, LOG_FILE])

func _on_show_dialogue(speaker: String, text: String) -> void:
	_log("[DIALOGUE] %s: %s" % [speaker, text])

func _process(_delta: float) -> void:
	if not OS.is_debug_build():
		return
	for action in _tap_release_queue:
		Input.action_release(action)
	_tap_release_queue.clear()

	if not FileAccess.file_exists(CMD_FILE):
		return
	var f := FileAccess.open(CMD_FILE, FileAccess.READ)
	if f == null:
		return
	var content := f.get_as_text()
	f.close()
	if content.strip_edges() == "":
		return
	DirAccess.remove_absolute(CMD_FILE)

	for line in content.split("\n"):
		var parts := line.strip_edges().split(" ")
		if parts.size() < 2:
			continue
		var cmd := parts[0]
		var action := parts[1]

		if cmd == "click":
			var btn := _find_button_by_name(get_tree().root, action)
			if btn != null:
				btn.pressed.emit()
				_log("[DebugInputDriver] clicked: " + action)
			else:
				_log("[DebugInputDriver] no BaseButton named: " + action)
			continue

		if cmd == "godmode" and action == "on":
			GameData.add_silver(9999)
			GameData.reset_stamina()
			GameData.harmony = 100
			var items := ["seed_cabbage", "seed_garlic", "jasmine_rice", "wood", "copper_ore", "iron_ore", "silver_ore", "ornate_shrine_blueprint"]
			for item_id in items:
				GameData.add_item(item_id, 10)
			_log("[DebugInputDriver] godmode on: silver=%s stamina_tier=%s harmony=%s +10 each: %s" % [
				GameData.silver, GameData.stamina_tier, GameData.harmony, items
			])
			continue

		if cmd == "goto" and parts.size() >= 3:
			var player_g: Node = _find_node_by_name(get_tree().root, "Player")
			if player_g != null and player_g is Node2D:
				(player_g as Node2D).global_position = Vector2(float(parts[1]), float(parts[2]))
				_log("[DebugInputDriver] teleported Player to " + str((player_g as Node2D).global_position))
			else:
				_log("[DebugInputDriver] no Player found to teleport")
			continue

		if cmd == "give" and parts.size() >= 2:
			var give_id: String = parts[1]
			var give_count: int = int(parts[2]) if parts.size() >= 3 else 1
			GameData.add_item(give_id, give_count)
			_log("[DebugInputDriver] gave %d x %s" % [give_count, give_id])
			continue

		if cmd == "set" and action == "day" and parts.size() >= 3:
			var tm_set: Node = SignalBus.time_manager
			if tm_set != null:
				tm_set.set("day", int(parts[2]))
				_log("[DebugInputDriver] set day to " + parts[2])
			continue

		if cmd == "set" and action == "season" and parts.size() >= 3:
			var tm_season: Node = SignalBus.time_manager
			if tm_season != null:
				tm_season.set("current_season", parts[2])
				_log("[DebugInputDriver] set season to " + parts[2])
			continue

		if cmd == "dump":
			var player: Node = _find_node_by_name(get_tree().root, "Player")
			var pos_str := "n/a"
			if player != null and player is Node2D:
				pos_str = str((player as Node2D).global_position)
			var tm: Node = SignalBus.time_manager
			var time_str := "n/a"
			if tm != null:
				time_str = "day=%s hour=%s min=%s" % [tm.get("day"), tm.get("hour"), tm.get("minute")]
			_log("[DebugInputDriver] STATE player_pos=%s silver=%s stamina_tier=%s harmony=%s time=%s" % [
				pos_str, GameData.silver, GameData.stamina_tier, GameData.harmony, time_str
			])
			continue

		if not InputMap.has_action(action):
			_log("[DebugInputDriver] unknown action: " + action)
			continue
		match cmd:
			"press":
				Input.action_press(action)
				_dispatch_action_event(action, true)
			"release":
				Input.action_release(action)
				_dispatch_action_event(action, false)
			"tap":
				Input.action_press(action)
				_dispatch_action_event(action, true)
				_tap_release_queue.append(action)
			_:
				_log("[DebugInputDriver] unknown command: " + cmd)

## Dispatches a real InputEventAction through the normal _input() chain, in
## addition to Input.action_press/release's polled-state update. NEEDED:
## code that reads Input.is_action_pressed() in _process/_physics_process
## (movement) is satisfied by action_press/release alone, but code that
## listens for event.is_action_pressed() inside _input(event) (e.g.
## Player.gd's interact handler) only ever fires on a real InputEvent --
## action_press() alone silently never reaches it. Found the hard way: the
## interact key appeared completely dead under this driver even though
## movement worked, until this was added.
func _dispatch_action_event(action: String, is_pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = is_pressed
	Input.parse_input_event(ev)

func _find_button_by_name(node: Node, target_name: String) -> BaseButton:
	if node.name == target_name and node is BaseButton:
		return node
	for child in node.get_children():
		var found := _find_button_by_name(child, target_name)
		if found != null:
			return found
	return null

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null
