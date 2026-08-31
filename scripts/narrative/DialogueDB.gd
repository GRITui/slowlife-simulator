extends RefCounted
## DialogueDB — TASK-012 Binthabat event tree + village dialogue passes
## Cozy, low-exposition, authentic Thai countryside ambient lines.
## Seasonal quest chains: each NPC has 3 seasonal branches + a
## binthabat streak branch (triggered when player has offered alms today).
## Pure data + static helpers; no autoload, no scene-tree coupling.

const DIALOGUE: Dictionary = {
	"elder": {
		"cool": [
			"Cool morning — good for planting jasmine rice, child.",
			"Monks walk at dawn. A small offering keeps the village in balance.",
			"The buffalo are calm this season. Take it slow.",
		],
		"hot": [
			"Hot season — water early, rest at noon.",
			"Even the canal runs slow in the heat. Patience.",
			"Mango season soon. Share what you harvest.",
		],
		"monsoon": [
			"Rain fills the paddies. Lotus will rise in the pond.",
			"Monsoon — the sluice gate keeps the water kind.",
			"Stay on the bunds when the fields flood.",
		],
		"binthabat_done": [
			"Sadhu — your alms this morning steadied the village heart.",
			"Merit returns as calm. The fields felt it today.",
		],
		"binthabat_hint": [
			"If you have rice, offer it before 07:30 on temple lane.",
			"Lotus or mango — the monk accepts what is offered with care.",
		],
	},
	"child": {
		"cool": [
			"Can we fly kites when the wind is cool?",
			"I saw footprints by the pond!",
		],
		"hot": [
			"So hot! Can we get mango sticky rice?",
			"The buffalo is sleeping under the tree.",
		],
		"monsoon": [
			"Puddles everywhere! I found a lotus leaf boat.",
			"Will the path to school flood?",
		],
		"binthabat_done": [
			"Did you give rice to the monk? I want to try one day!",
			"Elder says sharing makes the village smile.",
		],
		"binthabat_hint": [
			"Monk is on temple lane early — I heard the bell!",
			"Rice grain is easy to share.",
		],
	},
	"handler": {
		"cool": [
			"Canal is steady. Sluice gate held through the cool.",
			"Buffalo pasture is green — good grazing.",
		],
		"hot": [
			"Canal drops in the heat. Watch the gate.",
			"If the gate sticks, a few grains and some strength will free it.",
		],
		"monsoon": [
			"Gate is working hard this season. Listen to the water.",
			"Repair the gate and pandan seed will come with the flow.",
		],
		"binthabat_done": [
			"Merit morning — water feels lighter on days you offer.",
			"Village harmony is up. The gate thanks you too.",
		],
		"binthabat_hint": [
			"Temple lane, 05:00-07:30 — don't miss the monk.",
			"Sticky rice also counts for alms, if you have it.",
		],
	},
	"monk": {
		"cool": [
			"May your morning be steady as still water.",
			"Cool season alms — lightness for the days ahead.",
		],
		"hot": [
			"Heat tests patience. A small kindness cools the heart.",
			"Walk slowly in the hot season, farmer.",
		],
		"monsoon": [
			"Rain feeds the rice. Patience feeds the soul.",
			"Lotus rises through mud — merit through small giving.",
		],
		"offer_thanks": [
			"Sadhu... may your generosity bring harmony (+%d).",
			"Anumodana — your offering steadies the village (+%d).",
		],
	},
}

static func get_line(npc_id: String, season: String, idx: int) -> String:
	var npc: Dictionary = DIALOGUE.get(npc_id, {})
	if npc.is_empty():
		return "..."
	var pool: Array = npc.get(season, [])
	if pool.is_empty():
		pool = npc.get("cool", [])
	if pool.is_empty():
		return "..."
	return String(pool[idx % pool.size()])

static func get_seasonal_line(npc_id: String, season: String, binthabat_done: bool, hint_roll: int) -> String:
	var npc: Dictionary = DIALOGUE.get(npc_id, {})
	if npc.is_empty():
		return "..."
	# If player offered today, prioritize binthabat_done branch 50% chance.
	if binthabat_done:
		var done_pool: Array = npc.get("binthabat_done", [])
		if not done_pool.is_empty() and hint_roll % 2 == 0:
			return String(done_pool[hint_roll % done_pool.size()])
	# Otherwise small hint chance when no offering yet (1 in 3).
	if not binthabat_done:
		var hint_pool: Array = npc.get("binthabat_hint", [])
		if not hint_pool.is_empty() and hint_roll % 3 == 0:
			return String(hint_pool[hint_roll % hint_pool.size()])
	var pool: Array = npc.get(season, [])
	if pool.is_empty():
		pool = npc.get("cool", [])
	return String(pool[hint_roll % pool.size()])

static func get_monk_thanks(item_id: String, harmony_yield: int, season: String) -> String:
	var pool: Array = DIALOGUE.get("monk", {}).get("offer_thanks", [])
	var template: String = String(pool[0]) if not pool.is_empty() else "Sadhu... (+%d)"
	# Keep short; item-specific flavor could be added without exposition.
	return template % harmony_yield

static func get_monk_seasonal_idle(season: String, idx: int) -> String:
	return get_line("monk", season, idx)
