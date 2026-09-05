extends Node
## FlavorDialogue — TASK-383. Flat npc_id -> Array[String] flavor-line
## pools for the 14 new background NPCs (family + wanderers). NOT part
## of DialogueDB.gd's tiered stranger/friendly/close/romantic system --
## these NPCs have no affinity, so a flat rotating pool is the entire
## contract. Line text is locked verbatim from TASK-383-prompt.md.

const FLAVOR_LINES: Dictionary = {
	"charoen": [
		"Fah's out on the water before I even wake these days. Good. That's how it should be.",
		"I taught her everything about that canal. She's found spots I never did.",
		"Careful near the deep channel — that current's older than both of us.",
	],
	"somsri": [
		"Ploy's mango sticky rice recipe was mine first. Don't tell her I said the sugar ratio needs work.",
		"That girl could sell rocks if she smiled at you first.",
		"Come by in the morning — I'm still teaching her the palm sugar trick.",
	],
	"gaew": [
		"Mali's convinced every season is a competition. I just want a good harvest.",
		"She gets that stubborn streak from our mother, not me.",
		"Watch the eastern bund with her — she'll race you there and call it 'checking the water level.'",
	],
	"boonchu": [
		"I played that same drum forty years ago. Rin plays it louder.",
		"She used to hide under the stage during festivals. Now she won't leave it.",
		"The rhythm's in the family. Don't ask me why.",
		"During Loy Krathong, I still lead the opening beat. Rin takes over by the second song — she plays it louder than I ever did.",
	],
	"ampai": [
		"Yaa knows the lotus roots better than I do now. I taught her to be curious first, careful second.",
		"Mind the mud near the reeds. Yaa never minds it. I still do.",
		"She brings me tea from her garden every week. I pretend I don't know it's a gift, not a chore.",
	],
	"ying": [
		"He worries about that sluice gate more than he worries about dinner. I've made my peace with it.",
		"Ask him about the valley sometime. He'll talk for an hour and somehow make it interesting.",
		"Thirty years married to a man who talks to water for a living. I wouldn't change it.",
	],
	"nam": [
		"He gave up plenty to wear those robes. I still bring him his favorite curry anyway.",
		"Our mother worried he'd be lonely at the temple. He's not. He just doesn't complain.",
		"He'd never ask for help carrying anything. So I just carry it before he notices.",
		"During Songkran, I bring the Monk his favorite curry before the water throwing starts. He always pretends to be surprised.",
	],
	"tong": [
		"Uncle says a good trader never says what the village has too much of. I'm still learning not to blurt it out.",
		"He's letting me run the stall alone next season. I'm terrified. Don't tell him.",
		"Everyone thinks trading is just talking. It's mostly just remembering who owes what.",
	],
	"kham": [
		"He hasn't slept through a rainy season in years. Every drop is his responsibility now, apparently.",
		"Ask him about the old sluice gate story sometime. He tells it slightly differently than the elder does.",
		"Being married to the village headman mostly means everyone thinks I know things. I mostly don't.",
	],
	"kaew": [
		"I used to be scared of the buffalo. Now I'm scared of disappointing my sister more.",
		"She says I have good hands for this. I say I've just had a lot of practice not panicking.",
		"Someday I'll run this on my own. Today I'm still asking her twice before I do anything.",
	],
	"buppha": [
		"Nok's farmed that plot since before some of you were born. Stubborn, like his father.",
		"I still bring him lunch even though he insists he's fine. He is not fine. He's just proud.",
		"This valley raised three generations of us. I plan on seeing a fourth.",
	],
	"daeng": [
		"I come here to relax, not to catch anything. Fah thinks that's a waste of a good rod.",
		"Some people fish for fish. I fish for the quiet.",
		"Careful, the current's stronger than it looks today. I'd know — I've been pulled in twice.",
	],
	"ploen": [
		"Have you heard about the trader's nephew running the stall alone? Bold.",
		"I don't spread rumors. I just repeat things loudly near people who do.",
		"The village hasn't had proper gossip since the last festival. You're overdue for something interesting.",
	],
	"add": [
		"Kwan let me hold the chisel once. Just once. I dropped it.",
		"I'm going to be a wood carver too. Or a festival drummer. Haven't decided.",
		"Race you to the canal! ...okay maybe not today, my legs are tired.",
	],
	"ferryman": [
		"Mind the deep water off the dock. It doesn't give things back.",
		"I fish at dusk. Mornings belong to everyone else.",
		"The Elder tells it her way. I let her.",
	],
	"fish_keeper": [
		"Bring me a fresh catch and I'll show you what salt and patience can do.",
		"Wild turmeric grows thick around my cabin — helps the jars keep. Take some if you pass by.",
		"A kept fish feeds you twice: once today, once when the season turns.",
	],
	"scrap_collector": [
		"One field's rubbish is another week's roof patch. I just carry it between.",
		"I sleep wherever the edge is empty. The whole valley's my spare room.",
		"People throw away the most interesting things. Not judging — just collecting.",
	],
}
