class_name NpcData
extends RefCounted
## Every neighbour's identity and every line they can say. Pure data — no nodes, no scene access —
## so Planet can load it during terrain setup (it calls `get_npc(id)` to reserve NPC home spots).
##
##   var d := NpcData.get_data("zorp")
##   d["planet"] · d["display_name"] · d["voice_profile"] · d["accent"] · d["home_dir"]
##   d["greet"]["low" | "mid" | "high"]      friendship tiers 0-2 / 3-5 / 6+
##   d["small_talk"]                          >= 12 lines, distinct voice per NPC
##   d["time_lines"]["dawn"|"day"|"dusk"|"night"]
##   d["deco_lines"]["none"|"few"|"many"]     reactions to GameState.placed_decorations["home"]
##   d["favor"]["fetch"|"bring"|"deliver"|"progress"|"thanks"|"decline"|"remind"|"gift"]
##
## Hub shopkeepers also carry "building" / "home_offset_m" / "home_side_m": NPC derives their real
## spot from `planet.building_dir(building)` at spawn, and `home_dir` is only the coarse fallback
## used for the planet's reserved zone.
##
## Writing rules (docs/STYLE_GUIDE.md): warm, playful, <= 60 characters per line.

const TIER_LOW := "low"
const TIER_MID := "mid"
const TIER_HIGH := "high"

const DATA := {
	# ==========================================================================================
	"zorp": {
		"planet": "zorp",
		"display_name": "Zorp",
		"voice_profile": "zorp",
		"accent": "#8a4fe8",
		"home_dir": Vector3(0.45, 0.84, -0.30),
		"wander_radius_m": 9.0,
		"intro": [
			"Oh! Oh! A visitor from the blue planet!",
			"I am Zorp. I collect facts about Earth.",
			"Fact one: you have knees. Two of them!",
		],
		"greet": {
			"low": [
				"Greetings, Earth friend!",
				"You came back! My antenna tingled.",
				"Hello hello! Mind the glowing puddles.",
				"Welcome to the Violet Hollow!",
			],
			"mid": [
				"Zorp is pleased. Zorp is very pleased!",
				"There you are! I saved you a nice rock.",
				"My favourite neighbour, in the flesh!",
				"You have returned! My day improves.",
			],
			"high": [
				"THERE you are! I was practising waving.",
				"Best friend! Look, I waved correctly!",
				"You! Yes! Hello! I have SO many questions.",
				"My favourite Earthling has landed.",
			],
		},
		"small_talk": [
			"Do you also photosynthesize? Be honest.",
			"On Earth, is the sky always that one blue?",
			"I tried sleeping lying down. Very strange.",
			"Your knees fold the WRONG way. Fascinating.",
			"The rivers here hum at night. Listen sometime.",
			"I named a crystal after you. It is shiny.",
			"Is it true Earth soup is served hot? Wild.",
			"My antenna picks up your planet's radio!",
			"Explain 'weekend' to me. Slowly, please.",
			"I grew a plant. It grew sideways. Rude.",
			"Do Earth clouds taste like anything?",
			"I floated for six hours yesterday. Bliss.",
			"Someone told me Earth has oceans. Plural!",
			"I practised your handshake on a rock.",
		],
		"time_lines": {
			"dawn": ["The two moons are still up. Cosy!", "Morning dew here glows. Try not to drink it."],
			"day": ["The violet grass is extra squishy today.", "Perfect weather for standing around!"],
			"dusk": ["The rivers turn gold about now. Look!", "Dusk makes my antenna feel fizzy."],
			"night": ["Shhh. The crystals are singing.", "Night here is the good kind of dark."],
		},
		"deco_lines": {
			"none": ["Your planet is very... open. Roomy!", "You should put a thing on your planet."],
			"few": ["I heard you placed something! Show me?", "A decorated planet is a happy planet."],
			"many": ["Your planet is famous in this system!", "So many things! I counted twice. Twice!"],
		},
		"favor": {
			"fetch": [
				"Small favour? I dropped my study samples.",
				"Could you gather %d %s for me?",
			],
			"bring": [
				"I am building something. Do not ask what.",
				"Bring me %d %s and I will show you!",
			],
			"deliver": [
				"I made a present for %s. It hums a bit.",
				"Could you carry it over? Do not shake it.",
			],
			"progress": [
				"Ooh, keep going! Science is patient.",
				"That is progress! My antenna approves.",
			],
			"thanks": [
				"PERFECT. Look at them! Look!",
				"Take this. It was cluttering my hollow.",
			],
			"decline": [
				"No? That is fine. I will hum instead.",
				"Another time! I have plenty of humming.",
			],
			"remind": [
				"Still collecting? Take your time, friend.",
				"My samples await. No rush. Some rush.",
			],
			"gift": [
				"Zorp received a package! It hums!",
				"Tell them thank you. Actually, I will.",
			],
		},
	},
	# ==========================================================================================
	"bolt": {
		"planet": "bolt",
		"display_name": "Bolt",
		"voice_profile": "bolt",
		"accent": "#2fa8a0",
		"home_dir": Vector3(-0.42, 0.86, 0.28),
		"wander_radius_m": 9.0,
		"intro": [
			"Hello. You are visitor number one.",
			"I am Bolt. I maintain this yard.",
			"I have counted 4,181 bolts. So far.",
		],
		"greet": {
			"low": [
				"Hello. Systems nominal. You look nominal.",
				"Visitor detected. Visitor welcomed.",
				"Good. You are here. That is good.",
				"Hello! I have counted things for you.",
			],
			"mid": [
				"You are visit number nine. I keep records.",
				"Friend detected. Happiness at 82 percent.",
				"Hello! I saved you the shiniest gear.",
				"You came back. My log is pleased.",
			],
			"high": [
				"Best friend detected. Happiness: 100.",
				"You! I oiled a hinge in your honour.",
				"Hello! I made a chart about our talks.",
				"Friendship level: maximum. Confirmed twice.",
			],
		},
		"small_talk": [
			"I have 4,182 bolts. I found one more.",
			"A gear turned twelve times today. Twelve.",
			"The ring above us is 1.4 kilometres wide.",
			"I like Tuesdays. They are structurally sound.",
			"My left foot squeaks. I have named it Squeak.",
			"There are 61 orange lights here. I checked.",
			"Rust is just metal being emotional.",
			"I sorted my screws by size. Then by mood.",
			"Do you also require oil? I have spare oil.",
			"Statistically, you are my favourite visitor.",
			"I counted your steps. You took 214.",
			"This planet spins. I checked. It does.",
			"I built a small chair. It has four legs.",
			"My chest dial spins when I am happy. Watch.",
		],
		"time_lines": {
			"dawn": ["Startup complete. 06:14. Approximately.", "Dawn light makes the plates look pink."],
			"day": ["Daylight. Efficiency is up 3 percent.", "The plates are warm. I like warm plates."],
			"dusk": ["Dusk. The orange lights switch on now.", "Sunset takes 41 minutes here. I timed it."],
			"night": ["Night shift. I am the only shift.", "The ring glows at night. I recommend it."],
		},
		"deco_lines": {
			"none": ["Your planet has zero decorations. Zero.", "An empty planet is a tidy planet, I suppose."],
			"few": ["Your planet has some furniture. Good start.", "I approve of your object placement."],
			"many": ["I counted your decorations. Impressive.", "Your planet scores highly. I made a chart."],
		},
		"favor": {
			"fetch": [
				"A request. My inventory is short.",
				"Please locate %d %s. Precision appreciated.",
			],
			"bring": [
				"I require materials for a small project.",
				"Bring %d %s. I will build a thing.",
			],
			"deliver": [
				"I assembled a gift for %s. It ticks.",
				"Please deliver it. Handle with 60%% care.",
			],
			"progress": [
				"Progress logged. Continue, please.",
				"Good. My chart shows an upward line.",
			],
			"thanks": [
				"Received. Counted. Correct. Excellent.",
				"Take this. My gratitude is at maximum.",
			],
			"decline": [
				"Understood. Request archived, not deleted.",
				"That is fine. I will count something else.",
			],
			"remind": [
				"My request is still open. No pressure.",
				"Reminder issued gently. Very gently.",
			],
			"gift": [
				"A package. For me. It ticks correctly.",
				"Logged as: best delivery of the day.",
			],
		},
	},
	# ==========================================================================================
	"pip": {
		"planet": "hub",
		"display_name": "Pip",
		"voice_profile": "pip",
		"accent": "#6fbf3f",
		"home_dir": Vector3(-0.50, 0.50, 0.71),
		"building": "deco_store",
		"home_offset_m": 3.0,
		"home_side_m": -1.4,
		"wander_radius_m": 5.0,
		"intro": [
			"Welcome to Cosmo Depot! I'm Pip!",
			"That's my brother Pop. He has two antennae.",
			"I only have one. It's the cooler amount.",
		],
		"greet": {
			"low": ["Welcome to Cosmo Depot!", "Hi hi! Browsing? Buying? Both?", "Ooh, a customer! Pop, a customer!"],
			"mid": ["You're back! Pop owes me a rock.", "Hi! We restocked. Sort of. A bit.", "Welcome back to Cosmo Depot!"],
			"high": ["Our BEST customer! Pop, look, look!", "Hi! We saved you the good shelf.", "You again! I mean that in a nice way!"],
		},
		"small_talk": [
			"Pop says the shelves are alphabetical...",
			"I sorted the lamps by brightness today!",
			"We sell things! That's the whole shop!",
			"Pop dropped a crate. I'm not telling.",
			"One antenna. Best antenna. Fact.",
			"Our star logo? I drew it. Mostly.",
			"Someone bought a rug! A whole rug!",
			"I can carry three crates. Almost three.",
			"Pop says I talk too much. Pop is wrong.",
			"We opened at dawn. I was asleep for it.",
			"If you shake a lamp, it does nothing.",
			"Business is booming! Softly booming.",
			"I counted the shelves. Twice. Same answer.",
			"Pop and I share one apron budget.",
		],
		"time_lines": {
			"dawn": ["We open early! Pop opens earlier.", "Morning! The lamps are still warm."],
			"day": ["Busy day! Well. A day.", "Best browsing light right now!"],
			"dusk": ["Almost closing! Almost. Not yet.", "Dusk shoppers get the best rugs."],
			"night": ["We're technically open. Technically.", "Night shift! Pop is asleep standing up."],
		},
		"deco_lines": {
			"none": ["Your planet is EMPTY! We can fix that!", "No decorations? That's a shopping list!"],
			"few": ["You've started decorating! Proud of you!", "A few pieces already! Good taste!"],
			"many": ["Your planet is our best advert!", "So many of our items! Pop, look!"],
		},
		"favor": {
			"fetch": ["Stock emergency! Sort of an emergency.", "Could you find %d %s? Pop lost ours."],
			"bring": ["We need supplies and Pop is 'busy'.", "Bring %d %s and we'll owe you one!"],
			"deliver": ["We made a care package for %s!", "Take it over? Pop packed it. Sorry."],
			"progress": ["You're getting there! Pop is impressed!", "Almost! I'm keeping score, you know."],
			"thanks": ["YES! Pop, we're saved!", "Take this. It fell off a shelf. Legally."],
			"decline": ["Aw. Okay! Pop can do it. Somehow.", "That's fine! I'll ask Pop. Again."],
			"remind": ["Still looking? No rush! Slight rush.", "Our shelves miss you. So do I."],
			"gift": ["A parcel! Pop, we got a parcel!", "Ooh it's heavy. Heavy is good!"],
		},
	},
	# ==========================================================================================
	"pop": {
		"planet": "hub",
		"display_name": "Pop",
		"voice_profile": "pop",
		"accent": "#b8c93a",
		"home_dir": Vector3(-0.56, 0.46, 0.69),
		"building": "deco_store",
		"home_offset_m": 3.0,
		"home_side_m": 1.4,
		"wander_radius_m": 5.0,
		"intro": [
			"...and that's our shop! I'm Pop!",
			"Pip started that sentence. I finish them.",
			"Two antennae. Double the listening!",
		],
		"greet": {
			"low": ["...to Cosmo Depot! Pip started it.", "Hello! Pip is behind you. Probably.", "Welcome! Mind the crate. That crate."],
			"mid": ["...back again! Pip said you would be.", "Hi! We dusted the shelves for you.", "You returned! Pip owes me a rock."],
			"high": ["...our favourite! Pip agrees. Loudly.", "Hi hi! The good shelf is yours.", "You! Pip has been talking about you!"],
		},
		"small_talk": [
			"...and that's why the shelves are like that.",
			"Pip says one antenna is cooler. It isn't.",
			"I dropped a crate. Pip is telling everyone.",
			"...so then the lamp rolled away. Whole lamp.",
			"I hear twice as well. That's science.",
			"Pip drew our logo. I coloured it in.",
			"...which is why we never sell soup.",
			"I alphabetised the rugs. By feel.",
			"Two antennae, two opinions. Both mine.",
			"...and THAT is the end of that story.",
			"I nap standing up. It saves floor space.",
			"Pip talks. I do the arithmetic.",
			"...anyway, we're out of blue lamps.",
			"I like customers. You are one of those.",
		],
		"time_lines": {
			"dawn": ["...open already! I unlocked it myself.", "Morning! Pip is still yawning."],
			"day": ["...best hours of the day, these.", "Midday rush! Both customers!"],
			"dusk": ["...closing soon. Ish. Don't rush.", "Dusk light makes everything look pricier."],
			"night": ["...still open. I think. Pip?", "Night shift is quiet. I like quiet."],
		},
		"deco_lines": {
			"none": ["...nothing on your planet at all? Oh!", "An empty planet! What a canvas!"],
			"few": ["...a few pieces! A tasteful few.", "You've begun! Pip will be thrilled."],
			"many": ["...your planet is packed! Wonderful.", "So many items! I counted. Twice."],
		},
		"favor": {
			"fetch": ["...and we're short on stock. Again.", "Find %d %s? Pip 'organised' ours away."],
			"bring": ["...so we need materials. Urgently. Ish.", "Bring %d %s and the shop is saved!"],
			"deliver": ["...we wrapped something for %s.", "Deliver it? Pip tied the bow. Sorry."],
			"progress": ["...good progress! Pip is watching.", "Nearly there! I can feel it. Twice."],
			"thanks": ["...PERFECT. Pip, we're back in business!", "Here, take this. It's from the good shelf."],
			"decline": ["...oh. Fine! I'll ask Pip. Wish me luck.", "No worries! I'll do it. Slowly."],
			"remind": ["...still on that errand? Take your time.", "Our shelves await. Patiently. Mostly."],
			"gift": ["...a delivery! For us! Pip, look!", "It's heavy. I'll pretend it isn't."],
		},
	},
	# ==========================================================================================
	"stella": {
		"planet": "hub",
		"display_name": "Stella",
		"voice_profile": "stella",
		"accent": "#ff5d8f",
		"home_dir": Vector3(0.50, 0.50, 0.71),
		"building": "clothes_store",
		"home_offset_m": 3.0,
		"home_side_m": 0.0,
		"wander_radius_m": 5.0,
		"intro": [
			"Oh! A new face. And a new silhouette.",
			"I'm Stella. I run Suit-Up.",
			"Stand still — I'm measuring you already.",
		],
		"greet": {
			"low": ["Welcome to Suit-Up, darling.", "Hello! Let me look at that outfit.", "Come in, come in. Mind the pins."],
			"mid": ["Back for more? Excellent instincts.", "Hello, darling. That colour suits you.", "Ah! My favourite silhouette returns."],
			"high": ["My muse! Sit. Let me admire you.", "Darling! I designed something for you.", "You! Yes! The look is coming together."],
		},
		"small_talk": [
			"A helmet is just a hat with ambition.",
			"Never wear two golds. One gold. Always.",
			"Space is black. Your outfit shouldn't be.",
			"I dream in fabric. Mostly in pleats.",
			"Visor tints are the new hemlines.",
			"That suit? Two seasons ago. Still lovely.",
			"Boots first. Everything else follows boots.",
			"I measured a comet once. It was a 42.",
			"Pastels in orbit. Trust me on this.",
			"A good stripe can save an entire day.",
			"I hem by starlight. It's very calming.",
			"Confidence is the accessory, darling.",
			"My tape measure has seen four planets.",
			"Colour first, comfort second, gravity last.",
		],
		"time_lines": {
			"dawn": ["Morning light is the honest light.", "Early! Good. Fittings before breakfast."],
			"day": ["Perfect light for choosing colours.", "Midday. The mirrors are at their kindest."],
			"dusk": ["Dusk. Everything looks expensive now.", "Golden hour. My favourite fabric."],
			"night": ["Night shopping. Very glamorous.", "The lamps make every colour softer."],
		},
		"deco_lines": {
			"none": ["An undecorated planet is an unhemmed dress.", "Your planet needs accessories, darling."],
			"few": ["A few pieces! A capsule collection.", "You've begun styling your planet. Lovely."],
			"many": ["Your planet is fully accessorised!", "Darling, your planet has a LOOK."],
		},
		"favor": {
			"fetch": ["A tiny favour, if you have a moment.", "Fetch me %d %s? For a new trim."],
			"bring": ["I'm short on materials for a commission.", "Bring me %d %s and I'll make magic."],
			"deliver": ["I ran up something for %s. A gift.", "Would you carry it? Don't crease it."],
			"progress": ["Coming along! Patience makes couture.", "Good, good. Keep going, darling."],
			"thanks": ["Perfect. These are exactly right.", "Take this. It didn't suit my window."],
			"decline": ["Of course. Fashion waits, occasionally.", "Another time. The trim can wait."],
			"remind": ["Still hunting? Take your time, darling.", "My commission is patient. Mostly."],
			"gift": ["A parcel! And beautifully carried, too.", "Oh, the wrapping! Someone has taste."],
		},
	},
	# ==========================================================================================
	"mayor_orbit": {
		"planet": "hub",
		# SHOWN AS PROFESSOR COMET (docs/CORE_LOOP.md "Changed after the build plan"): a scientist who
		# watches the sky, not a mayor - no running the town, no renaming. The id stays "mayor_orbit"
		# so saves, his NPC scene and his voice routing ("mayor_orbit" -> the shared doot) never move.
		# His voice in writing: warm and a little scatter-brained, forever mid-observation. He loses
		# his pencil, never his kindness. None of these lines assume the campaign: old saves hear them.
		"display_name": "Professor Comet",
		"voice_profile": "mayor_orbit",
		"accent": "#c9a15c",
		"home_dir": Vector3(0.0, 0.99, 0.12),
		"building": "town_hall",
		"home_offset_m": 3.2,
		"home_side_m": 0.0,
		"wander_radius_m": 4.0,
		"intro": [
			"Oh! Hello! Sorry, I was counting meteors.",
			"I'm Professor Comet. I watch the sky.",
			"If it twinkles, I've probably named it.",
		],
		"greet": {
			"low": ["Ah, hello! Mind my telescope.", "Good day! The sky is busy today.", "Hello there. I've lost my notes again."],
			"mid": ["Ah, my favourite stargazer!", "Hello again! I saved you a comet.", "You're back! Sit, the view is lovely."],
			"high": ["My dear friend! Come and look at this!", "Ah, you! The sky's brighter already.", "Hello, friend. Tea? I've mislaid the tea."],
		},
		"small_talk": [
			"I've named 212 stars. I forget which ones.",
			"A good telescope is worth two maps.",
			"My goggles are for stargazing. And soup steam.",
			"I once waved at a comet. It waved back. Probably.",
			"The sky never rushes. I try not to, either.",
			"More rocks fall up here than you'd think.",
			"I keep a notebook of every falling star.",
			"Kindness is like starlight. It travels far.",
			"I oil my telescope on Sundays. Tradition.",
			"No clouds out here. Terrible for excuses.",
			"Look up long enough and you'll see everything.",
			"I lost my pencil. It's behind my ear. It always is.",
			"Do visit the event space. It thumps.",
			"Every speck up there is somebody's sunshine.",
		],
		"time_lines": {
			"dawn": ["Dawn! The last stars are saying goodnight.", "Early riser! The best sky is an early sky."],
			"day": ["Daytime. The stars are still up there, you know.", "Bright out. Perfect for polishing lenses."],
			"dusk": ["Dusk! Here come the first stars. Count them!", "Evening. My favourite time to look up."],
			"night": ["Night sky! Oh, isn't it splendid?", "Late, isn't it? The sky is wide awake."],
		},
		"deco_lines": {
			"none": ["Your planet looks bare from my scope. Bare is a start.", "I peeked through my scope. No furniture yet!"],
			"few": ["I spotted your new things through my scope!", "A few pieces already. Very cosy, from up here."],
			"many": ["Your planet twinkles from here. Truly lovely.", "Such a cosy world! I can see it from my scope."],
		},
		"favor": {
			"fetch": ["Might I trouble you, my friend?", "Would you gather %d %s for my notes?"],
			"bring": ["My telescope needs a small repair.", "Bring me %d %s, if it's no trouble."],
			"deliver": ["I've a parcel bound for %s.", "Would you carry it? I'd only get lost."],
			"progress": ["Coming along nicely. No hurry at all.", "Good, good. The stars will wait."],
			"thanks": ["Wonderful! Just what my notes needed.", "Take this, with a stargazer's thanks."],
			"decline": ["Quite all right. Another day, perhaps.", "No trouble at all. Off you go."],
			"remind": ["My little errand still stands, friend.", "Whenever suits you. The sky's in no rush."],
			"gift": ["A parcel! For me? How thrilling.", "Do thank them. I'll note it in my log."],
		},
	},
	# ==========================================================================================
	"dj_nova": {
		"planet": "hub",
		"display_name": "DJ Nova",
		"voice_profile": "dj_nova",
		"accent": "#7b5bd6",
		"home_dir": Vector3(0.0, 0.30, 0.955),
		"building": "event_space",
		"home_offset_m": 3.0,
		"home_side_m": 0.0,
		"wander_radius_m": 4.0,
		"intro": [
			"YO! New face on the dance floor!",
			"I'm DJ Nova. I run the beats around here.",
			"Rule one: there are no rules. Rule two: dance.",
		],
		"greet": {
			"low": ["YO! Welcome to the loudest rock in space!", "Hey hey! You feel that bass? That's me.", "New listener detected! Turn it UP!"],
			"mid": ["Ayyy, my regular! Drop in, drop out!", "You're back! The speakers remembered you.", "Hey! I saved a track just for you."],
			"high": ["MY PERSON! The floor is officially yours.", "Yooo! Best friend on the decks tonight!", "You! Yes! This next one is dedicated!"],
		},
		"small_talk": [
			"Bass is just a hug you can hear.",
			"I wrote a track about a comet. It slaps.",
			"120 beats per minute. Every single time.",
			"My headphones cost more than my legs.",
			"Silence? Never met her. Sounds fake.",
			"I remix the planet's hum on Fridays.",
			"You ever dance in low gravity? Life-changing.",
			"My visor shows the beat. Look! LOOK!",
			"Track five is my baby. Don't skip track five.",
			"If it doesn't glow, it doesn't go.",
			"I once DJ'd for four rocks and a moth.",
			"Turn it up. No, further. Perfect.",
			"Every planet has a rhythm. Ours is funky.",
			"Applause is just clapping with feelings.",
		],
		"time_lines": {
			"dawn": ["Sunrise set! Softer. Still loud.", "Dawn beats hit different. Trust me."],
			"day": ["Daytime set! Bright and bouncy!", "The sun's up, so is the volume!"],
			"dusk": ["Golden hour! Time for the slow jams.", "Dusk set incoming! Grab a spot!"],
			"night": ["NIGHT SET! This is my hour!", "Lights down, bass up. Perfect."],
		},
		"deco_lines": {
			"none": ["Your planet's got no vibe yet. Fix it!", "Empty planet? That's a blank record!"],
			"few": ["Your planet's got a starter beat going!", "A few pieces! The vibe is building!"],
			"many": ["Your planet is a whole ALBUM. Respect.", "That's a five-star venue you've built!"],
		},
		"favor": {
			"fetch": ["Quick one! My rig needs a part.", "Grab me %d %s? For the light show."],
			"bring": ["I'm building a new speaker. It's big.", "Bring %d %s and I'll name a track for you."],
			"deliver": ["Made a mixtape for %s. It goes hard.", "Run it over for me? Don't scratch it."],
			"progress": ["Ooh, you're on beat! Keep going!", "That's the rhythm! Almost there!"],
			"thanks": ["YESSS! The rig lives! You legend!", "Take this. It was clashing with my lights."],
			"decline": ["All good! I'll improvise. I always do.", "No worries! The show goes on regardless."],
			"remind": ["Still hunting my part? No stress, friend.", "The rig can wait. The beat can't. Kidding."],
			"gift": ["A DELIVERY! For me! Turn it up!", "Ooh, this one's got weight to it. Nice."],
		},
	},
	# ==========================================================================================
	"fen": {
		"planet": "fen",
		"display_name": "Fen",
		"voice_profile": "fen",
		"accent": "#6f8cb8",
		"home_dir": Vector3(0.6820, 0.6428, -0.3492),
		"wander_radius_m": 9.0,
		"intro": [
			"Sit. The light does this for another six hours.",
			"I am Fen. I watch the pools. That is the work.",
			"Nine years of notes. Pool four moved. Twice.",
		],
		"greet": {
			"low": [
				"Ah. A visitor. Mind the crust near the rim.",
				"Hello. You are the first thing to move today.",
				"Welcome to the long dusk. It is always this.",
				"You cast a good shadow. Seven metres, near.",
			],
			"mid": [
				"You again. The pools noticed. I noticed too.",
				"Good. Sit. I have the logbook open anyway.",
				"Ah, my neighbour. The light kept for you.",
				"Hello, friend. Take the shade of stone three.",
			],
			"high": [
				"There you are. I saved you a page in the book.",
				"My friend! Sit. The whole evening is ours.",
				"Ah! I wrote your name beside pool nine.",
				"You came the long way. I watched you arrive.",
			],
		},
		"small_talk": [
			"Pool four has moved again. Eleven centimetres.",
			"Nine years I have watched that water wander.",
			"The sun has been setting since I was young.",
			"Shadows here are honest. They tell you the hour.",
			"I number the pools. Fourteen. Sometimes thirteen.",
			"Salt grows back overnight. Quietly. Rudely.",
			"No moon here. Nothing to argue with the sun.",
			"The dust hangs. It never decides to fall.",
			"Walk slow. The crust remembers every foot.",
			"My logbook is heavier than I am. Nearly.",
			"I have a favourite stone. It is the fourth.",
			"Mirror pools lie about depth. Never trust one.",
			"You blink more than I do. I counted.",
			"Some evenings the whole pan turns copper.",
		],
		"time_lines": {
			"dawn": ["Dawn, in theory. The light barely shifts.", "Early. The pools have not woken up yet."],
			"day": ["Noon. The sun is a hand off the horizon.", "Midday shade is long enough to nap in."],
			"dusk": ["Dusk. As ever. It suits me, this hour.", "The pools are pure copper now. Look."],
			"night": ["Dark at last. No moon to spoil the stars.", "Night. The crust ticks as it cools."],
		},
		"deco_lines": {
			"none": ["Your planet is bare. Bare is a fine start.", "Nothing placed yet? Take your time. I did."],
			"few": ["A few things placed. I noted them down.", "You have begun. Begin slowly, that is best."],
			"many": ["Your planet is full of care. It shows.", "So many pieces. I would need a new page."],
		},
		"favor": {
			"fetch": [
				"A small thing, if your legs are willing.",
				"Could you gather %d %s for the logbook?",
			],
			"bring": [
				"I am marking the rims. I need materials.",
				"Bring me %d %s and I will mark pool nine.",
			],
			"deliver": [
				"I copied a page out for %s. It is dry now.",
				"Would you carry it over? Do not fold it.",
			],
			"progress": [
				"Good. There is no hurry on a world like this.",
				"Coming along. The light will wait for you.",
			],
			"thanks": [
				"Perfect. These go beside the old notes.",
				"Take this. It has sat unused for years.",
			],
			"decline": [
				"Of course. The pools are patient. So am I.",
				"Another day, then. There are plenty of days.",
			],
			"remind": [
				"My little errand still stands. No rush.",
				"When you pass by again, the note is ready.",
			],
			"gift": [
				"A parcel. For me. Well. Well well.",
				"Tell them thank you. I will write it down.",
			],
		},
	},
	# ==========================================================================================
	"grig": {
		"planet": "grig",
		"display_name": "Grig",
		"voice_profile": "grig",
		"accent": "#c2894f",
		"home_dir": Vector3(0.24, -0.86, -0.45),
		"wander_radius_m": 7.0,
		"intro": [
			"Stop there. That riser is still curing.",
			"I am Grig. I cut the steps. All of them.",
			"Nine hundred and four. I number every one.",
		],
		"greet": {
			"low": [
				"Mind the riser. It was here before you.",
				"Hello. Feet on the tread, not on the edge.",
				"A visitor. Walk up, not across. Up.",
				"Welcome to the steps. Take them slowly.",
			],
			"mid": [
				"You. Good. You have learned where to stand.",
				"Hello again. Step twelve missed you.",
				"Back up the stairs? Your footing improves.",
				"Good day. I saved you the flattest shelf.",
			],
			"high": [
				"My friend! Sit on step forty. It is level.",
				"You! Come up. I cut a new one for you.",
				"Best neighbour on the steps. And the only one.",
				"Ah! I numbered a riser after you. Six-A.",
			],
		},
		"small_talk": [
			"Nine hundred steps cut. I have views on eight.",
			"A riser is knee high or it is not a riser.",
			"I cut step one before the ring tilted over.",
			"Chalk forgives nothing. Measure twice. Again.",
			"You stand on the edge. Everyone does. Do not.",
			"The big moon lights the treads. The small sulks.",
			"My wedge is older than your planet. Probably.",
			"Dust settles in the corners. I sweep. It returns.",
			"Step two hundred is my finest. Come and see.",
			"I count in risers, not in days. Simpler.",
			"The ring is edge-on. A line, not a hoop. Better.",
			"Lichen grows on the cool side. Only the cool.",
			"Never run down. Down is where mistakes live.",
			"I numbered them all twice. The numbers agreed.",
		],
		"time_lines": {
			"dawn": ["Dawn. The risers throw their longest lines.", "Early. Good. The chalk is still cool."],
			"day": ["Midday. Every step edge is a shadow line.", "Good light. Count the tiers from here."],
			"dusk": ["Dusk. The treads go gold. Briefly. Enjoy it.", "Evening. Dust settles on step ninety."],
			"night": ["Two moons up. The big one shows the treads.", "Night. The ring is a bright wire overhead."],
		},
		"deco_lines": {
			"none": ["Nothing placed yet. A blank tread. Fine.", "An empty planet. Start at a corner. Always."],
			"few": ["A few pieces. Line them up next time.", "You have begun. Watch your spacing."],
			"many": ["Well placed, most of it. Well placed.", "Your planet is arranged. I approve. Mostly."],
		},
		"favor": {
			"fetch": [
				"A task, if your footing is good today.",
				"Would you gather %d %s? For the markers.",
			],
			"bring": [
				"I am cutting a new tread. I am short.",
				"Bring %d %s and the new tread gets a number.",
			],
			"deliver": [
				"I cut something for %s. Flat on both faces.",
				"Carry it level. Do not chip the corners.",
			],
			"progress": [
				"Progress. Steady is faster than quick.",
				"Good. Keep your weight over the tread.",
			],
			"thanks": [
				"Correct. Every one of them. Good work.",
				"Take this. It came off a very good step.",
			],
			"decline": [
				"No? Sensible. The stone is not going anywhere.",
				"Another day. I have eight hundred to check.",
			],
			"remind": [
				"My errand still stands. Mind the loose one.",
				"No rush. The steps have waited longer.",
			],
			"gift": [
				"A parcel. Squared corners. Someone was careful.",
				"For me? I shall number it. Then open it.",
			],
		},
	},
	# ==========================================================================================
	## Vela — the listener of the Long Array, and the cast's second robot neighbour.
	##
	## HER VOICE, and why it is not one of the eight already here. Bolt is clipped and literal
	## ("Systems nominal"), DJ Nova is loud, Mayor Orbit is a fond old politician, Fen is terse and
	## weathered, Grig is blunt. Vela is FORMAL AND WARM: whole courteous sentences, gentle humour,
	## and everything framed in terms of SOUND rather than sight, because she is a dish. She is the
	## only neighbour with no mouth, so several of her lines quietly acknowledge that her rim lamps
	## do the talking — which is also how a player learns to read them.
	##
	## FAVOUR FORMAT STRINGS. `FavorSystem.request_lines()` branches on what a line CONTAINS:
	## both %d and %s -> `% [count, item]`; a bare %s -> `% npc_name`; neither -> `%%` unescaped to
	## a literal percent. So "fetch" and "bring" each carry exactly one line with BOTH, "deliver"
	## carries exactly one line with a BARE %s, and no other line here contains a percent at all.
	"vela": {
		"planet": "vela",
		"display_name": "Vela",
		"voice_profile": "vela",
		"accent": "#a98a9e",
		"home_dir": Vector3(-0.3607, 0.7214, 0.5912),
		"wander_radius_m": 8.0,
		"intro": [
			"Good day. You have arrived in a quiet window.",
			"I am Vela. I keep the array and its records.",
			"Nine thousand hours of sky, all of it filed.",
		],
		"greet": {
			"low": [
				"Good day to you. Mind the cable runs.",
				"Welcome. The dishes are listening. Do speak up.",
				"A visitor. How very agreeable.",
				"Good day. I have set a chair out for you.",
			],
			"mid": [
				"Ah, you. The array noted your approach.",
				"Welcome back. I kept the quiet window for you.",
				"Good day, neighbour. Sit, if you would.",
				"You return. My records are pleased to say so.",
			],
			"high": [
				"My friend! The sky is being generous today.",
				"Ah, you. I saved a signal to play for you.",
				"Welcome, dear friend. Sit anywhere you like.",
				"You! Today's best hum is filed in your name.",
			],
		},
		"small_talk": [
			"The array hears further than it sees. So do I.",
			"I record everything and understand about half.",
			"Dish nine hums in the cold. I find it soothing.",
			"Politeness costs nothing and carries very far.",
			"I keep a file marked 'unexplained'. It is thick.",
			"Sound behaves oddly here. Do speak plainly.",
			"My rim lights say what my voice cannot. Watch.",
			"I do not sleep. I lower my gain and drift.",
			"The wind tunes the dishes. Badly, but sincerely.",
			"I heard a whole song once and lost the middle.",
			"A good antenna is patient. So is a good friend.",
			"I have no mouth. I manage. Lights are eloquent.",
			"Every hour I sweep the sky. Every hour, once.",
			"My knees click on cold mornings. I do not mind.",
		],
		"time_lines": {
			"dawn": ["Dawn. The array is at its most sensitive.", "Good morning. The sky is quiet and clean."],
			"day": ["Midday. A great deal of noise from the sun.", "Good day. The dishes are warm to the touch."],
			"dusk": ["Dusk. This is when the far signals arrive.", "Evening. My favourite hour on the field."],
			"night": ["Night. The whole sky speaks at once. Lovely.", "Late. I am still listening, if you need me."],
		},
		"deco_lines": {
			"none": ["Your planet is unfurnished. A clean signal.", "Nothing placed yet. There is time, and plenty."],
			"few": ["A few pieces placed, and tastefully spaced.", "You have begun. I noted it in the log."],
			"many": ["Your planet is beautifully appointed. Truly.", "So many pieces. I counted, then admired."],
		},
		"favor": {
			"fetch": [
				"A small request, if your day allows it.",
				"Might you gather %d %s for the array?",
			],
			"bring": [
				"I am repairing dish four. I lack materials.",
				"Bring me %d %s and I will tune it properly.",
			],
			"deliver": [
				"I have written something out for %s.",
				"Would you carry it over? It is not fragile.",
			],
			"progress": [
				"Coming along. There is no hurry in this.",
				"Good progress. The array will wait. So will I.",
			],
			"thanks": [
				"Precisely right. Thank you, most sincerely.",
				"Take this, with my thanks. It served me well.",
			],
			"decline": [
				"Of course. The request will keep. So will I.",
				"Quite all right. Another day, then.",
			],
			"remind": [
				"My small errand still stands. At your leisure.",
				"No hurry. The dish has waited nine years.",
			],
			"gift": [
				"A parcel, for me? How very kind. How lovely.",
				"I shall log it, then open it. In that order.",
			],
		},
	},
}


## Every neighbour id this game knows about.
static func ids() -> Array:
	return DATA.keys()


## Data dictionary for an npc id, or {} when unknown.
static func get_data(npc_id: String) -> Dictionary:
	return DATA.get(npc_id, {})


## Instance form — Planet calls this during terrain setup to reserve NPC home spots.
func get_npc(npc_id: String) -> Dictionary:
	return DATA.get(npc_id, {})


## Friendship tier key for a friendship level (0-2 low, 3-5 mid, 6+ high).
static func tier_for(friendship: int) -> String:
	if friendship >= 6:
		return TIER_HIGH
	if friendship >= 3:
		return TIER_MID
	return TIER_LOW


## Greeting for this friendship level.
static func greeting(npc_id: String, friendship: int, rng: RandomNumberGenerator = null) -> String:
	var d := get_data(npc_id)
	if d.is_empty():
		return "Hello!"
	var pool: Array = d.get("greet", {}).get(tier_for(friendship), [])
	return _pick(pool, rng, "Hello!")


## One small-talk line, never the same as `avoid`.
static func small_talk(npc_id: String, avoid: String = "", rng: RandomNumberGenerator = null) -> String:
	var d := get_data(npc_id)
	var pool: Array = d.get("small_talk", [])
	if pool.size() > 1 and avoid != "":
		pool = pool.filter(func(l: Variant) -> bool: return str(l) != avoid)
	return _pick(pool, rng, "...")


## Comment about the current hour (dawn / day / dusk / night).
static func time_line(npc_id: String, hour: float, rng: RandomNumberGenerator = null) -> String:
	var phase := "night"
	if hour >= 5.0 and hour < 7.0:
		phase = "dawn"
	elif hour >= 7.0 and hour < 18.0:
		phase = "day"
	elif hour >= 18.0 and hour < 20.0:
		phase = "dusk"
	var pool: Array = get_data(npc_id).get("time_lines", {}).get(phase, [])
	return _pick(pool, rng, "")


## Comment about how decorated the player's home planet is.
static func decoration_line(npc_id: String, placed_count: int, rng: RandomNumberGenerator = null) -> String:
	var key := "none"
	if placed_count >= 8:
		key = "many"
	elif placed_count >= 1:
		key = "few"
	var pool: Array = get_data(npc_id).get("deco_lines", {}).get(key, [])
	return _pick(pool, rng, "")


## Lines from the "favor" block: "fetch" "bring" "deliver" "progress" "thanks" "decline" "remind" "gift".
static func favor_lines(npc_id: String, key: String) -> Array:
	var raw: Array = get_data(npc_id).get("favor", {}).get(key, [])
	return raw.duplicate()


static func _pick(pool: Array, rng: RandomNumberGenerator, fallback: String) -> String:
	if pool.is_empty():
		return fallback
	if rng == null:
		return str(pool[randi() % pool.size()])
	return str(pool[rng.randi_range(0, pool.size() - 1)])
