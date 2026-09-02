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

	# TASK-338: Nok, semi-retired veteran farmer — warm, instructive,
	# mentoring tone. Contrasts Ek's competitive rivalry with
	# cooperative, patient wisdom.
	"nok": {
		"cool": [
			"Cool season is for patience — the rice knows its own time.",
			"Sixty years on this land, and still something new each season.",
		],
		"hot": [
			"Heat like this, water at dawn or not at all.",
			"The mango trees remember every drought. Be gentle with them.",
		],
		"monsoon": [
			"Let the rain do the work it knows how to do.",
			"Watch the bunds — a small leak becomes a big one overnight.",
		],
		"rain": [
			"Come sit under the eave a while. The fields can wait an hour.",
			"Rain like this, I just watch it fall. Nothing wrong with that.",
		],
		"binthabat_done": [
			"Merit given freely comes back the same way. Always has.",
			"Good on you for offering. The old ways still hold.",
		],
		"binthabat_hint": [
			"Temple lane, before the heat sets in — the monk's there most mornings.",
			"Rice, sticky rice, whatever you can spare. It's the offering that matters, not the size.",
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
	# TASK-346: retrofitted from the original 4-tier (stranger/friendly/
	# close/romantic) shape to 10 numbered levels — see GameData.level_for().
	# The 8 original lines are preserved as anchors (2 per old tier,
	# redistributed to their nearest new level) with new lines filling the
	# expanded resolution in between.
	"ek": {
		"1": [
			"You're new to the paddies. Mind the eastern bund, it floods first.",
			"Elder says you're doing fine for a first season. High praise, from her.",
		],
		"2": [
			"Still sizing you up. Don't take it personally.",
			"Not bad, for someone who didn't grow up here.",
		],
		"3": [
			"Race you to the harvest this time? Loser waters both plots tomorrow.",
			"Saved you the good seed. Don't tell the market I undercut myself.",
		],
		"4": [
			"You're actually decent competition now. Annoying, but true.",
			"I look forward to seeing whose plot does better this week.",
		],
		"5": [
			"You've gotten better. Doesn't mean I'll go easy on you.",
			"Half the reason I work harder is you're right there working too.",
		],
		"6": [
			"Honestly — I look forward to the days you're out in the fields too.",
			"You make the long seasons feel shorter. Don't know how else to say it.",
		],
		"7": [
			"I keep finding reasons to walk past your plot instead of mine.",
			"Somewhere along the way this stopped feeling like rivalry.",
		],
		"8": [
			"I think about you more than I compete with you these days.",
			"Don't tell anyone I said that. Actually — tell whoever you want.",
		],
		"9": [
			"Walk the canal path with me tonight? Just us, no rivalry this time.",
			"I used to farm alone before you got here. I don't want to go back to that.",
		],
		"10": [
			"There's no version of this farm, or this life, I want without you in it.",
			"You're not my rival anymore. Haven't been for a long time.",
		],
		# TASK-345/341: the early-warning fairness fix — once a rival warning
		# has fired (RivalClock at 25/50/75%), Ek's OWN level-1 dialogue
		# surfaces the threat directly, instead of leaving it to a rival NPC
		# the player may never approach. Checked in RomanceNPC._talk() only
		# at level 1, before the level 6-8 "rival" override below.
		"1_warned": [
			"Someone's been asking whether I've... noticed you. I said I hadn't decided what I noticed yet.",
		],
		# TASK-324: occasional light rival pressure on the close-equivalent
		# courtship band (levels 6-8, matching the old 60-89 affinity range
		# exactly under floor(affinity/10)) — someone else has been asking
		# about the player. Flavor-only, no name, no mechanical effect.
		# Surfaced only on every 5th talk.
		"rival": [
			"Someone was asking about you at the seed stall yesterday. Didn't catch a name — just said they're a good planter.",
			"The trader mentioned you on the coast road. Said your name came up more than once down that way.",
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

	# TASK-346: retrofitted to 10 numbered levels (see the "ek" comment
	# above for the general approach).
	"fah": {
		"1": [
			"The canal's calm this morning. Good for thinking, if you like that sort of thing.",
			"You fish? No — didn't think so. Ask me sometime, if you're curious.",
		],
		"2": [
			"You're quieter than most people who come by here. I don't mind that.",
			"Come back if you want to actually learn something about the water.",
		],
		"3": [
			"Caught something strange near the lotus maze yesterday. Still thinking about it.",
			"You're quieter than the village gives you credit for. I like that.",
		],
		"4": [
			"I don't usually explain my methods. I might, for you.",
			"You ask better questions than most people bother to.",
		],
		"5": [
			"I saved you a spot on the dock. Didn't think about why until after.",
			"There's a difference between being alone and being lonely. You're helping with the second one.",
		],
		"6": [
			"I don't tell many people about the deep-canal spots. You're one of the few.",
			"Some evenings I'd rather sit by the water with you than anywhere else.",
		],
		"7": [
			"I've started timing my casts around when you usually show up.",
			"Quiet is easier to share with the right person. Turns out.",
		],
		"8": [
			"I think about what you'd say about a catch before I even land it.",
			"You've made the water feel less like the only company I need.",
		],
		"9": [
			"Stay till the lanterns come out? The water looks different after dark.",
			"I've started saving the best catches to cook for you. Didn't plan that. Just happened.",
		],
		"10": [
			"I used to think I preferred the water to people. That was before you.",
			"Wherever you are is quieter and better than anywhere I'd be without you.",
		],
		# TASK-345/341: early-warning fairness fix (see the "ek" comment
		# above for the general approach).
		"1_warned": [
			"Someone left a note asking if I'd 'said anything' to you yet. I haven't decided what there is to say.",
		],
		# TASK-324: occasional light rival pressure on the close-equivalent
		# courtship band (levels 6-8). Flavor-only, no name, no mechanical
		# effect. Surfaced only on every 5th talk.
		"rival": [
			"Another fisher was asking after you on the canal yesterday. Said you two should compare catches sometime.",
			"Someone left a note at the dock asking when you'd be back on the water. Didn't sign it.",
		],
	},

	# TASK-335: third romance candidate. Warm, sociable market dessert-maker
	# near the temple lane — contrasts Ek's competitive edge and Fah's
	# quiet introspection with an extroverted, community-glue personality.
	# Same 5-tier structure (stranger/friendly/close/rival/romantic).
	# TASK-346: retrofitted to 10 numbered levels (see the "ek" comment
	# above for the general approach).
	"ploy": {
		"1": [
			"New to the village? Have a taste — first one's always free.",
			"Careful, the mango sticky rice sells out by midday. Ask the market why.",
		],
		"2": [
			"You came back for seconds. I remember faces that do that.",
			"Most people just grab and go. You actually said thank you.",
		],
		"3": [
			"I saved you the last piece. Don't tell the headman, he'll want it too.",
			"You've got flour on your sleeve again. Here, hold still —",
		],
		"4": [
			"I started setting a piece aside before you even show up.",
			"You ask how the recipes are made. Most people just eat and leave.",
		],
		"5": [
			"I give everyone a smile. Yours I actually mean.",
			"Somehow you're the customer I look forward to most.",
		],
		"6": [
			"Everyone gets my sweets. You get the ones I actually make for myself.",
			"I talk to the whole village every day. Somehow you're the one I think about after.",
		],
		"7": [
			"I've started saving my best batch for whenever you show up next.",
			"The stall gets quiet after you leave. I've noticed that more than I'd like to admit.",
		],
		"8": [
			"I don't know when 'the customer I like' became 'the person I think about all day.'",
			"Everyone in this village gets a taste of something. You get all of me, if you want it.",
		],
		"9": [
			"Come by after the stall closes tonight? Just us, no customers, no sweets to sell.",
			"I used to give my best to everyone equally. Not anymore. Not since you.",
		],
		"10": [
			"The stall was never the sweetest thing about this place. You are.",
			"I don't want to imagine closing up shop each night without you waiting for me.",
		],
		# TASK-345/341: early-warning fairness fix (see the "ek" comment
		# in this file for the general approach).
		"1_warned": [
			"The trader asked if I've 'said anything yet.' I keep changing the subject. Maybe I shouldn't.",
		],
		# TASK-324 pattern: occasional light rival pressure on the
		# close-equivalent courtship band (levels 6-8). Flavor-only, no
		# name, no mechanical effect.
		"rival": [
			"Someone from the coast road asked about you at the stall. Wanted to know if you were spoken for.",
			"The trader keeps asking if I've 'said anything yet.' Told him it's none of his business. It isn't, right?",
		],
	},

	# TASK-341: 3 more romance candidates, authored directly in TASK-346's
	# 10-level shape (no old 4-tier draft ever existed for these). Also
	# folds in TASK-345's early-warning fix from the start via "1_warned".
	"chang": {
		"1": [
			"You're here for a mask? Uncle Somchai handles those. I just... hold the chisel steady.",
			"Careful where you step — wood shavings everywhere. Occupational hazard.",
		],
		"2": [
			"You came back. Most people watch for a minute and wander off.",
			"I don't talk much while I carve. Hope that's alright.",
		],
		"3": [
			"This one's for the festival. Takes weeks to get the eyes right.",
			"You noticed the grain pattern? Not many do.",
		],
		"4": [
			"I don't show unfinished work to just anyone.",
			"Somchai says I'm too particular. I'd rather be too particular than sloppy.",
		],
		"5": [
			"I kept a scrap piece aside. Small carving, not much, but — here.",
			"You ask good questions about the wood. Better than most.",
		],
		"6": [
			"I don't usually let people watch this part. You're the exception.",
			"Some evenings I look forward to just... you being nearby while I work.",
		],
		"7": [
			"I've started carving little details I think you'd like, not just what the mask needs.",
			"Quiet company suits me. Yours especially.",
		],
		"8": [
			"I think about what you'd think of a piece before I even finish it.",
			"Somchai asked why I've been smiling at my work bench. I didn't have a good answer. Or — I did, I just didn't say it.",
		],
		"9": [
			"Stay while I finish this one? I'd like you here when it's done.",
			"I carved something for you. Not for the festival. Just for you.",
		],
		"10": [
			"I used to think the wood was the only thing that needed my full attention. That's not true anymore.",
			"Every piece I make now, some part of it is for you, whether I mean to or not.",
		],
		"1_warned": [
			"Someone's been asking whether I've... noticed you. I said I hadn't decided what I noticed yet.",
		],
		"rival": [
			"Another woodcarver's apprentice asked about you at the market. Said you had a good eye for craft.",
			"Someone left word at Somchai's stall asking when you'd stop by again.",
		],
	},

	"klong": {
		"1": [
			"Come to see the drumming? Stick around, it gets louder.",
			"New face! Careful, I might drag you into the dance circle.",
		],
		"2": [
			"You clapped along last time. I saw that.",
			"Most people just watch. You looked like you wanted to join.",
		],
		"3": [
			"I'm teaching the festival rhythm to the kids this week. Want to learn too?",
			"You've got good timing, for someone who claims they can't dance.",
		],
		"4": [
			"I don't perform for just anyone up close like this. Consider it a preview.",
			"You ask what the rhythms mean. Nobody asks that. I like that you did.",
		],
		"5": [
			"Saved you a spot up front for the next festival. Best seat, honestly.",
			"I catch myself performing a little harder when I know you're watching.",
		],
		"6": [
			"I don't let just anyone see me practice the hard parts, the mistakes and all.",
			"Some nights I'd rather sit and talk with you than run the set one more time.",
		],
		"7": [
			"I've started timing rehearsals around when you usually show up.",
			"Loud is easy. Being this honest with someone is harder. Worth it, though.",
		],
		"8": [
			"I think about your face in the crowd before I even step up to drum.",
			"Everyone else gets the performance. You get whatever this is underneath it.",
		],
		"9": [
			"Stay after the crowd clears tonight? Just the two of us and the drums going quiet.",
			"I've started writing a rhythm that's just for you. Haven't played it for anyone else.",
		],
		"10": [
			"I used to think the crowd was the only thing that made me feel alive. That was before you.",
			"Every festival from here on, I want you exactly where you were tonight — right next to me.",
		],
		"1_warned": [
			"Someone asked if I'd 'made a move' on you yet. Told them it's none of their business. Is it, though?",
		],
		"rival": [
			"Someone from the coast asked about you after the last festival. Wanted to know if you were 'spoken for.'",
			"A drummer from another village keeps asking when you'll be back for the next show.",
		],
	},

	"yaa": {
		"1": [
			"Looking for herbs? I keep the good ones past the reeds, not on display.",
			"Careful with the lotus stems, they bruise easy. Like most gentle things.",
		],
		"2": [
			"You came back for more than just herbs, I think.",
			"Most people rush past the garden. You actually looked at it.",
		],
		"3": [
			"This one calms fever, that one settles the stomach. Ask, I don't mind explaining.",
			"You have a gentle hand with the plants. Not everyone does.",
		],
		"4": [
			"I don't usually share what I'm growing until it's ready. I might, for you.",
			"You remembered what I told you about the basil. That matters more than you'd think.",
		],
		"5": [
			"I set aside a cutting for you. Didn't plan to, just did.",
			"There's a calm about you that matches the garden. I like having you here.",
		],
		"6": [
			"I don't tell many people about the rare plants past the tree line. You're one of the few.",
			"Some afternoons I'd rather sit with you among the herbs than tend them alone.",
		],
		"7": [
			"I've started timing my harvest around when you usually visit.",
			"Quiet company suits this garden. And you suit the quiet.",
		],
		"8": [
			"I think about what you'd say about a new plant before I even show anyone else.",
			"You've made this garden feel less like the only company I need.",
		],
		"9": [
			"Stay past sunset? The herbs smell different once the day cools.",
			"I've started growing things I think you'd like, not just what's useful. Didn't plan that. Just happened.",
		],
		"10": [
			"I used to think I preferred the garden to people. That was before you.",
			"Wherever you are is gentler and better than anywhere I'd be without you.",
		],
		"1_warned": [
			"Someone's been asking after you at the herb stall. Said you two should talk sometime. I didn't love hearing that, if I'm honest.",
		],
		"rival": [
			"Another herbalist passing through asked about you. Said your name came up more than once on the road.",
			"Someone left a note asking when you'd be back this way. Didn't sign it.",
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

## TASK-054: per-NPC liked gifts. loved = +20 affinity + special line,
## liked = +10, anything else food = +5 (v1 fallback).
const GIFT_PREFERENCES: Dictionary = {
	"ek": {"loved": ["mango_sticky_rice", "mango"], "liked": ["rice_grain", "sticky_rice", "thai_basil"]},
	# TASK-335: Ploy is a dessert-maker — she loves being brought the finer
	# cooked sweets rather than raw ingredients (distinct from Ek/Fah's
	# raw-produce/fish preferences).
	"ploy": {"loved": ["mango_sticky_rice", "banana_rice_cake"], "liked": ["banana", "coconut", "palm_sugar"]},
	"fah": {"loved": ["pla_nin_mid", "lotus_soup", "lotus_root"], "liked": ["fish_sauce", "egg", "som_tam"]},
	"elder": {"loved": ["lotus_root", "banana_rice_cake"], "liked": ["rice_grain", "thai_basil"]},
	"child": {"loved": ["mango_sticky_rice", "durian"], "liked": ["egg", "banana"]},
	"handler": {"loved": ["tom_yum", "fish_sauce"], "liked": ["rice_grain", "egg"]},
	# TASK-338: Nok, veteran farmer — simple staple crops, no fuss.
	# "ginger" was the first draft here but isn't in GameData.FOOD_ITEMS
	# (the auto-gift picker's source list), so it would never actually be
	# reachable via _give_gift() — swapped for thai_basil, which is.
	"nok": {"loved": ["sticky_rice", "thai_basil"], "liked": ["rice_grain", "banana"]},
	"monk": {"loved": ["jasmine_rice", "lotus_root"], "liked": ["banana", "mango", "sticky_rice"]},
	"trader": {"loved": ["pla_kraben_big", "pla_buk_big"], "liked": ["durian", "coconut", "palm_sugar"]},
	# TASK-341: 3 more romance candidates. All loved/liked items confirmed
	# present in GameData.FOOD_ITEMS (the auto-gift picker's only source).
	"chang": {"loved": ["thai_basil_stirfry", "som_tam"], "liked": ["rice_grain", "egg"]},
	"klong": {"loved": ["mango_sticky_rice", "pandan_sticky_rice"], "liked": ["banana", "egg"]},
	"yaa": {"loved": ["thai_basil", "lotus_root"], "liked": ["pandan_leaf", "banana_leaf"]},
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
