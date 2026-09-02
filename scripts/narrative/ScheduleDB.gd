extends RefCounted
## ScheduleDB — TASK-058 (#115) NPC daily movement schedules.
## Waypoints per NPC with hour windows; NPC scripts query the active
## waypoint and drift toward it. Data-only (cozy, no urgency).
##
## TASK-328 (2026-09-02): rain override. GameData.current_weather already
## varies (TimeManager) but nothing consumed it for NPC positioning before
## this — villagers just kept their normal outdoor hour-schedule regardless
## of weather. Scoped to the two NPCs whose schedule already has an
## explicit "home" waypoint (elder, child) rather than inventing new
## positions for the rest — see docs/research/TASK-328-329-spec.md.

const SCHEDULES: Dictionary = {
	"elder": [
		{"from": 5, "to": 11, "pos": Vector2(1, 2)},   # temple lane at dawn
		{"from": 11, "to": 17, "pos": Vector2(1, 5)},  # home courtyard
		{"from": 17, "to": 24, "pos": Vector2(1, 3)},  # evening by the shrine
	],
	"child": [
		{"from": 6, "to": 12, "pos": Vector2(4, 3)},   # paddy edge play
		{"from": 12, "to": 18, "pos": Vector2(2, 1)},  # lotus pond
		{"from": 18, "to": 24, "pos": Vector2(1, 6)},  # home
	],
	"handler": [
		{"from": 5, "to": 12, "pos": Vector2(11, 13)}, # canal check
		{"from": 12, "to": 18, "pos": Vector2(3, 14)}, # pasture
		{"from": 18, "to": 24, "pos": Vector2(11, 13)},
	],
	"niran": [
		{"from": 6, "to": 12, "pos": Vector2(13, 5)},  # paddy rivalry
		{"from": 12, "to": 18, "pos": Vector2(9, 6)},  # paddy core
		{"from": 18, "to": 24, "pos": Vector2(13, 7)},
	],
	"headman": [
		{"from": 6, "to": 12, "pos": Vector2(1, 3)},
		{"from": 12, "to": 18, "pos": Vector2(17, 1)},
		{"from": 18, "to": 24, "pos": Vector2(1, 4)},
	],
	"vet": [
		{"from": 6, "to": 12, "pos": Vector2(2, 14)},
		{"from": 12, "to": 18, "pos": Vector2(3, 14)},
		{"from": 18, "to": 24, "pos": Vector2(2, 13)},
	],
	"fah": [
		{"from": 6, "to": 12, "pos": Vector2(10, 12)}, # canal mornings
		{"from": 12, "to": 18, "pos": Vector2(2, 1)},  # lotus pond
		{"from": 18, "to": 24, "pos": Vector2(10, 11)},
	],
}

## TASK-328: home waypoint used for the full day when it's raining, for
## NPCs whose normal schedule already labels one slot "home"/"home
## courtyard" (reusing the existing position, not a new one).
const RAIN_HOME: Dictionary = {
	"elder": Vector2(1, 5),
	"child": Vector2(1, 6),
}

## Active waypoint cell for npc_id at the given hour (first window match).
## weather defaults to "clear" so existing callers are unaffected.
static func waypoint_for(npc_id: String, hour: int, weather: String = "clear") -> Vector2i:
	if weather == "rain" and RAIN_HOME.has(npc_id):
		return RAIN_HOME[npc_id] as Vector2i
	var schedule: Array = SCHEDULES.get(npc_id, []) as Array
	for entry: Dictionary in schedule:
		if hour >= int(entry.get("from", 0)) and hour < int(entry.get("to", 24)):
			return entry.get("pos", Vector2i.ZERO) as Vector2i
	return Vector2i.ZERO
