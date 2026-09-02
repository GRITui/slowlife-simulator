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
			"Wan Sart is coming — sticky rice, peanut, sesame, bound with palm sugar. For the ancestors.",
		],
		"hot": [
			"Hot season — water early, rest at noon.",
			"Even the canal runs slow in the heat. Patience.",
			"Mango season soon. Share what you harvest.",
			"Songkran is near — the young ones will splash water on the elders for blessing.",
			"Ton's been talking about a monster by the forest again. Phi Ta Khon does that to a child's imagination.",
		],
		"monsoon": [
			"Rain fills the paddies. Lotus will rise in the pond.",
			"Monsoon — the sluice gate keeps the water kind.",
			"Stay on the bunds when the fields flood.",
		],
		# TASK-329: weather branch (any season) — see get_seasonal_line().
		"rain": [
			"Come sit under the eave a moment. The rain will ease.",
			"Good rain for the rice. Bad rain for these old knees.",
		],
		"binthabat_done": [
			"Sadhu — your alms this morning steadied the village heart.",
			"Merit returns as calm. The fields felt it today.",
		],
		"binthabat_hint": [
			"If you have rice, offer it before 07:30 on temple lane.",
			"Lotus or mango — the monk accepts what is offered with care.",
		],
		"fishing_hint": [
			"The eels hide in the canal mud after heavy rain — feel for them, don't look.",
			"Salit surface at the hottest part of the afternoon, when the paddy water's low.",
			"Deep canal bends, monsoon only — the whiskered one doesn't come to shallow water.",
			"Careful with that one's tail. It rests flat on the sandy bottom, hot season only.",
			"The golden one runs upriver when the water cools — patience, not strength, catches it.",
			"My grandmother spoke of a giant in the deep canal bend — once a generation, monsoon only. Few believe her. I do.",
			"At high noon in the hot season, something flashes every color in the sun near the lotus maze. I've only seen it once.",
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
			"Songkran! Can we throw water at everyone today?",
			"Nong Ton says he knows every ghost story there is. Bet I could scare HIM with what I saw by the forest edge.",
		],
		"monsoon": [
			"Puddles everywhere! I found a lotus leaf boat.",
			"Will the path to school flood?",
		],
		"rain": [
			"Splashing in puddles is the BEST part of rain!",
			"Mom says come inside when it rains this hard. I'm inside! Mostly.",
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
			"Wing Kwai's coming. Uncle Preecha's already bragging about his buffalo. Someone should humble him.",
		],
		"hot": [
			"Canal drops in the heat. Watch the gate.",
			"If the gate sticks, a few grains and some strength will free it.",
			"We fill the jars early for Songkran — every drop gets shared that day.",
		],
		"monsoon": [
			"Gate is working hard this season. Listen to the water.",
			"Repair the gate and pandan seed will come with the flow.",
			"Canal's rising faster than I like. If it breaks the bank, bring me wood — we reinforce before it floods, not after.",
		],
		"rain": [
			"Good day to check the sluice gate holds. Bad day to be standing here doing it.",
			"Buffalo don't mind the rain. I do.",
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
			"Wan Sart honors those who came before. Bring kra yasat, if you've made it.",
			"The macaques took your bananas out of hunger, not malice. A banquet mends more than a chase ever would.",
		],
		"hot": [
			"Heat tests patience. A small kindness cools the heart.",
			"Walk slowly in the hot season, farmer.",
			"Pour water gently over the Buddha image this Songkran — cleanse, don't drench.",
		],
		"monsoon": [
			"Rain feeds the rice. Patience feeds the soul.",
			"Lotus rises through mud — merit through small giving.",
		],
		"offer_thanks": [
			"Sadhu... may your generosity bring harmony (+%d).",
			"Anumodana — your offering steadied the village (+%d).",
		],
	},
	# TASK-025 Evening Market Stall — 1 line per season, cozy, no
	# combat/gold/fail keywords. Keep short so the dialogue panel tween
	# (3.5s) finishes naturally.
	"market": {
		"cool": [
			"Sticky rice for rice grain? A fair trade — share the harvest.",
		],
		"hot": [
			"Mango for lotus root — the heat ripens both. Share the warmth.",
		],
		"monsoon": [
			"Lotus root for sticky rice? The rains feed us all. Take it.",
		],
	},
	# New peer-age romance-eligible NPCs (Head-of-Art round, 2026-09-01).
	# Affinity-tiered, not season-tiered — mirrors the round's PO_INBOX MVP
	# spec: stranger -> friendly -> close -> romantic, gated by a future
	# GameData.affinity[npc_id] int this data doesn't itself track.
	"niran": {
		"stranger": [
			"You're new to the paddies. Mind the eastern bund, it floods first.",
			"Elder says you're doing fine for a first season. High praise, from her.",
		],
		"friendly": [
			"Race you to the harvest this time? Loser waters both plots tomorrow.",
			"Saved you the good seed. Don't tell the market I undercut myself.",
		],
		"close": [
			"Honestly — I look forward to the days you're out in the fields too.",
			"You make the long seasons feel shorter. Don't know how else to say it.",
		],
		# TASK-324: occasional light rival pressure on the close-tier courtship
		# path — someone else has been asking about the player. Flavor-only, no
		# name, no mechanical effect. Surfaced only on every 5th talk.
		"rival": [
			"Someone was asking about you at the seed stall yesterday. Didn't catch a name — just said they're a good planter.",
			"The trader mentioned you on the coast road. Said your name came up more than once down that way.",
		],
		"romantic": [
			"Walk the canal path with me tonight? Just us, no rivalry this time.",
			"I used to farm alone before you got here. I don't want to go back to that.",
		],
	},
	"veteran": {
		"any": [
			"Second year on the land — the rows know your footsteps now.",
			"Third year: neighbors bring you seeds without asking.",
			"Fourth year: the village calls you when the sluice misbehaves.",
		],
	},

	"headman": {
		"cool": [
			"The village runs on small kindnesses. Keep it up.",
			"Wing Kwai prep is underway — the buffalo earn their festival.",
		],
	},
	"vet": {
		"cool": [
			"Buffalo look healthy. Whatever you are feeding them, keep at it.",
			"Goat arrived last week — strong hooves, good sign.",
		],
	},

	## New: Trader's cart (Head-of-Art round, 2026-09-01) — the coastal-goods
	## trader referenced in GIFT_PREFERENCES since early in the project,
	## finally getting a face and a cart. Cozy, no gold/fail keywords.
	"trader": {
		"hot": [
			"The coast road's dusty this time of year — good thing the cart has wheels, not legs.",
			"Durian and mango, I'll take all you can spare. The coast pays it forward in shrimp paste.",
		],
		"monsoon": [
			"Mud slows the cart, not the trading. Lotus root still moves well downriver.",
			"Careful on the canal path — I nearly lost a sack of rice flour to the current last week.",
		],
		"cool": [
			"Cool season, good roads — I make it round to every farm before dusk.",
			"Sticky rice and palm sugar, always welcome. The coast has a sweet tooth.",
		],
	},

	"nong_ton": {
		"cool": [
			"Uncle Somchai says the ghosts wore their masks all wrong this year!",
			"I'm Nong Ton — I know EVERY ghost story in the village. Every one!",
		],
	},
	"somchai": {
		"cool": [
			"Uncle Somchai, at your service. I carve the Phi Ta Khon masks.",
			"A good mask takes patience. So does good rice.",
		],
	},

	"fah": {
		"stranger": [
			"The canal's calm this morning. Good for thinking, if you like that sort of thing.",
			"You fish? No — didn't think so. Ask me sometime, if you're curious.",
		],
		"friendly": [
			"Caught something strange near the lotus maze yesterday. Still thinking about it.",
			"You're quieter than the village gives you credit for. I like that.",
		],
		"close": [
			"I don't tell many people about the deep-canal spots. You're one of the few.",
			"Some evenings I'd rather sit by the water with you than anywhere else.",
		],
		# TASK-324: occasional light rival pressure on the close-tier courtship
		# path — someone else has been asking about the player. Flavor-only, no
		# name, no mechanical effect. Surfaced only on every 5th talk.
		"rival": [
			"Another fisher was asking after you on the canal yesterday. Said you two should compare catches sometime.",
			"Someone left a note at the dock asking when you'd be back on the water. Didn't sign it.",
		],
		"romantic": [
			"Stay till the lanterns come out? The water looks different after dark.",
			"I've started saving the best catches to cook for you. Didn't plan that. Just happened.",
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

## TASK-329: weather defaults to "clear" so existing callers are unaffected.
## Priority stays binthabat_done > binthabat_hint > rain > season, matching
## the existing branch structure — rain is a ~40% flavor chance (like the
## 1-in-3 binthabat hint), not a hard override, so season lines still show.
static func get_seasonal_line(npc_id: String, season: String, binthabat_done: bool, hint_roll: int, weather: String = "clear") -> String:
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
	if weather == "rain":
		var rain_pool: Array = npc.get("rain", [])
		if not rain_pool.is_empty() and hint_roll % 5 < 2:
			return String(rain_pool[hint_roll % rain_pool.size()])
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

static func get_market_line(season: String, have_id: String, want_id: String) -> String:
	# Cozy 1-line seasonal flavor for the Evening Market Stall (TASK-025).
	# No gold/money/fail/debt references — test gate enforces this.
	var pool: Array = DIALOGUE.get("market", {}).get(season, [])
	if pool.is_empty():
		pool = DIALOGUE.get("market", {}).get("cool", [])
	if pool.is_empty():
		return "Trade? %s for %s — share the harvest." % [have_id, want_id]
	return String(pool[0])

## TASK-051: affinity -> dialogue tier (breakpoints 25/60/90).
static func get_affinity_tier(affinity: int) -> String:
	if affinity >= 90:
		return "romantic"
	if affinity >= 60:
		return "close"
	if affinity >= 25:
		return "friendly"
	return "stranger"

## TASK-054: per-NPC liked gifts. loved = +20 affinity + special line,
## liked = +10, anything else food = +5 (v1 fallback).
const GIFT_PREFERENCES: Dictionary = {
	"niran": {"loved": ["mango_sticky_rice", "mango"], "liked": ["rice_grain", "sticky_rice", "thai_basil"]},
	"fah": {"loved": ["pla_nin_mid", "lotus_soup", "lotus_root"], "liked": ["fish_sauce", "egg", "som_tam"]},
	"elder": {"loved": ["lotus_root", "banana_rice_cake"], "liked": ["rice_grain", "thai_basil"]},
	"child": {"loved": ["mango_sticky_rice", "durian"], "liked": ["egg", "banana"]},
	"handler": {"loved": ["tom_yum", "fish_sauce"], "liked": ["rice_grain", "egg"]},
	"monk": {"loved": ["jasmine_rice", "lotus_root"], "liked": ["banana", "mango", "sticky_rice"]},
	"trader": {"loved": ["pla_kraben_big", "pla_buk_big"], "liked": ["durian", "coconut", "palm_sugar"]},
}

## Returns "loved" | "liked" | "neutral" for a given NPC + item.
static func gift_tier(npc_id: String, item_id: String) -> String:
	var prefs: Dictionary = GIFT_PREFERENCES.get(npc_id, {})
	if (prefs.get("loved", []) as Array).has(item_id):
		return "loved"
	if (prefs.get("liked", []) as Array).has(item_id):
		return "liked"
	return "neutral"

## Affinity delta per tier.
static func gift_affinity(tier: String) -> int:
	match tier:
		"loved": return 20
		"liked": return 10
		_: return 5
