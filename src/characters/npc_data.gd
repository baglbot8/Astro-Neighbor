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
			"Oh ho! A visitor! Welcome to Violet Hollow!",
			"I'm Zorp. I grow the glowing garden here.",
			"See my moustache wiggle? That means I'm happy!",
		],
		"greet": {
			"low": [
				"Hello, hello! Mind the glowing puddles.",
				"You came back! My moustache wiggled.",
				"Oh ho! Welcome to my glowing garden!",
				"Hello there! Come see what's glowing today.",
			],
			"mid": [
				"There you are! I saved you a nice glow cap.",
				"My favourite visitor! Come in, come in!",
				"You're back! My day just got brighter.",
				"Hello, friend! My flowers missed you. So did I.",
			],
			"high": [
				"THERE you are! I was waving at the sky for you.",
				"My best friend! Come, come, the crystals sang!",
				"Oh ho ho! Look who it is! Hello, hello!",
				"You! Hooray! Let me twirl my moustache for you.",
			],
		},
		"small_talk": [
			"I talk to my flowers. They glow when I do.",
			"The rivers here hum at night. Listen sometime.",
			"I named a crystal after you. It is very shiny.",
			"My moustache isn't hair. It's four wiggly arms!",
			"I grew a flower. It grew sideways. Cheeky thing!",
			"Two moons! One for me, and one for my garden.",
			"I've grown glow caps since before you were born!",
			"Oh ho! A new mushroom tree popped up last night!",
			"I hum to my crystals. They hum back, you know.",
			"When I was young, the rivers glowed SO bright.",
			"I knitted this scarf myself. It's a bit lumpy.",
			"Fen is the only flower who talks back to me!",
			"Bolt told me a joke. He says it wasn't a joke.",
			"Grig grumbles, but he plants my flowers. Ha!",
		],
		"time_lines": {
			"dawn": ["Both moons are still up! Good morning, you two!", "Morning dew glows here. Don't drink it!"],
			"day": ["The purple grass is extra squishy today.", "Lovely day for gardening! Every day is."],
			"dusk": ["The rivers turn gold about now. Look!", "Oh ho, sunset! My glow caps are waking up."],
			"night": ["Shhh. Hear that? The crystals are singing.", "Night is the best time. Everything glows!"],
		},
		"deco_lines": {
			"none": ["Your planet looks a bit bare. Plant something!", "An empty planet! Like my garden, long ago."],
			"few": ["You put some things out! Show me, show me!", "A few nice things. Your planet is growing!"],
			"many": ["Oh ho! Your planet is full of lovely things!", "So many things! Like a garden, but of stuff!"],
		},
		"favor": {
			"play": [
				"Want to fly my river rings again? Oh ho!",
			],
			"fetch": [
				"Oh ho, a little favour? My garden needs help.",
				"Could you gather %d %s for me?",
			],
			"bring": [
				"I'm making something! It's a surprise.",
				"Bring me %d %s and I'll show you!",
			],
			"deliver": [
				"I grew a present for %s. It glows a bit.",
				"Could you carry it over? Gently, now.",
			],
			"progress": [
				"Keep going! Gardens grow slowly too.",
				"Lovely progress! My moustache approves.",
			],
			"thanks": [
				"PERFECT! Look at them! Just look!",
				"Take this. A little thank-you from my garden.",
			],
			"decline": [
				"No? That's fine. I'll water my flowers.",
				"Another time, then! My garden can wait.",
			],
			"remind": [
				"Still gathering? Take your time, friend.",
				"No rush! Well... a little rush. Oh ho!",
			],
			"gift": [
				"A present for me? It glows! Oh ho!",
				"Tell them thank you! No, wait, I'll tell them!",
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
			"I am Bolt. I fix things in this yard.",
			"I have counted 4,181 bolts. So far.",
		],
		"greet": {
			"low": [
				"Hello, friend. I am glad you came.",
				"Hello. I cleaned my screen for you.",
				"You are here. That is good. I like good.",
				"Hello! I counted things for you. Many things.",
			],
			"mid": [
				"Hello, friend. I counted the days since your last visit.",
				"You came back. My chest dial is spinning.",
				"Hello! I saved you the shiniest gear.",
				"Hello again. I oiled my knees for this.",
			],
			"high": [
				"Best friend! My dial is spinning very fast.",
				"You! I oiled a hinge just for you.",
				"Hello! I made a chart of all our talks.",
				"My best friend is here. I checked twice.",
			],
		},
		"small_talk": [
			"I have 4,182 bolts now. I found one more.",
			"I fixed 12 things today. One was my own foot.",
			"The ring above us is 1.4 kilometres wide.",
			"I like Tuesdays. They are very well built.",
			"My left foot squeaks. I named it Squeak.",
			"There are 61 orange lights here. I checked.",
			"I sorted my screws by size. Then by colour.",
			"Do you need oil? I have 3 cans of spare oil.",
			"You are my favourite visitor. I did the maths.",
			"I counted your steps today. You took 214.",
			"Zorp laughs at my facts. I do not know why.",
			"I built a small chair. It has 4 legs. Correct.",
			"My chest dial spins when I am happy. Watch.",
			"Vela and I swap spare parts. It is very fair.",
		],
		"time_lines": {
			"dawn": ["Good morning. I woke up at 6:14 exactly.", "Morning light makes the metal look pink."],
			"day": ["Daytime. I work 3 percent faster in the sun.", "The metal is warm. I like warm metal."],
			"dusk": ["Evening. The orange lights switch on now.", "Sunset takes 41 minutes here. I timed it."],
			"night": ["Night. I work the night shift. And the day one.", "The ring glows at night. I recommend it."],
		},
		"deco_lines": {
			"none": ["Your planet has 0 decorations. I counted.", "An empty planet is very tidy. I suppose."],
			"few": ["Your planet has some things. Good start.", "I like where you put your things. Very neat."],
			"many": ["I counted your decorations. So many!", "Your planet is great. I made a chart."],
		},
		"favor": {
			"play": [
				"More bolts shook loose. Could you catch them?",
			],
			"fetch": [
				"Could you help me? I am running low.",
				"Please find %d %s. I will wait here.",
			],
			"bring": [
				"I am building something small. I need parts.",
				"Bring me %d %s. I will build a thing.",
			],
			"deliver": [
				"I built a gift for %s. It ticks.",
				"Please carry it over. Do not drop it.",
			],
			"progress": [
				"Good progress. Please keep going.",
				"Good. My chart has a line going up.",
			],
			"thanks": [
				"Thank you! My chest dial is spinning. That is joy.",
				"Take this. I am very grateful.",
			],
			"decline": [
				"That is fine. I will count something else.",
				"Okay. I will ask again another day.",
			],
			"remind": [
				"My request is still open. No pressure.",
				"This is a gentle reminder. Very gentle.",
			],
			"gift": [
				"A package, for me. It ticks nicely.",
				"This is the best delivery of the day.",
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
			"Welcome to Cosmo Depot! I'm Pip.",
			"Fast talk, fast deals. That's me.",
			"Pop's my best friend. He's the muscle.",
		],
		"greet": {
			"low": ["Welcome to Cosmo Depot!", "Hi hi! Browsing? Buying? Both?", "Ooh, a customer! Best kind of visitor.", "Step right up, customer!"],
			"mid": ["You're back! Great taste, customer.", "Hi! We restocked. Sort of. A bit.", "Welcome back to Cosmo Depot!", "There's my favourite shopper!"],
			"high": ["Our BEST customer! Every time!", "Hi! We saved you the good shelf.", "You again! In the best way, customer.", "My favourite face at the counter!"],
		},
		"small_talk": [
			"I sold out of lamps before breakfast today.",
			"Pop carries the heavy stuff. I carry the plan.",
			"I sorted the lamps by brightness today!",
			"We sell things! That's the whole shop!",
			"Pop dropped a crate again. Don't tell him I said.",
			"Our star logo? I drew it. Mostly.",
			"Someone bought a whole rug today!",
			"I handle the deals. Pop handles the lifting.",
			"Best deals in the whole system, customer.",
			"We opened at dawn. I was already awake.",
			"If you shake a lamp, nothing happens. Trust me.",
			"Business is booming! Softly booming.",
			"I keep every shelf exactly where it should be.",
			"Pop and I split one apron budget. Don't ask.",
		],
		"time_lines": {
			"dawn": ["We open early! Pop opens earlier.", "Morning! The lamps are still warm."],
			"day": ["Busy shop today! Come on in.", "Best browsing light right now!"],
			"dusk": ["Almost closing! Almost. Not yet.", "Dusk shoppers get the best deals."],
			"night": ["We're technically open. Technically.", "Pop's asleep standing up again."],
		},
		"deco_lines": {
			"none": ["Your planet is EMPTY! We can fix that!", "No decorations? That's a shopping list!"],
			"few": ["You've started decorating! Proud of you!", "A few pieces already! Good taste!"],
			"many": ["Your planet is our best advert!", "So many of our things! I love it!"],
		},
		"favor": {
			"fetch": ["Stock emergency! Sort of an emergency.", "Could you find %d %s, customer?"],
			"bring": ["We need supplies and Pop is 'busy'.", "Bring %d %s and we'll owe you one!"],
			"deliver": ["We made a care package for %s!", "Take it over? Pop packed it. Careful."],
			"progress": ["You're getting there! Keep going!", "Almost! I'm counting the days."],
			"thanks": ["YES! Deal! You're my favourite, customer.", "Take this. On the house, this time."],
			"decline": ["Aw, okay! I'll ask Pop. Somehow.", "That's fine! I'll figure it out."],
			"remind": ["Still looking? No rush! Slight rush.", "Our shelves miss you. So do I."],
			"gift": ["A parcel! Ooh, exciting!", "Ooh it's heavy. Heavy is good!"],
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
			"Hi! I'm Pop. I work at Cosmo Depot.",
			"Pip's the boss. I carry the heavy stuff.",
			"I give great hugs. Ask anyone.",
		],
		"greet": {
			"low": ["Welcome to Cosmo Depot!", "Hi! Come on in.", "Hello! Mind the crate. That crate.", "Hi! Want a hug? I'm very soft."],
			"mid": ["Hi again! Good to see you.", "Hi! We dusted the shelves for you.", "You came back! I saved you a hug.", "Hello, friend! Pip likes you too."],
			"high": ["My favourite! Come here, hug time.", "Hi hi! The good shelf is yours.", "You! I've been hoping you'd visit.", "Best friend! Careful, I might hug you."],
		},
		"small_talk": [
			"I dropped a crate today. Oops.",
			"My feelers pick up everything. Even whispers.",
			"Pip drew our logo. I coloured it in.",
			"I folded the rugs. They're a little crooked.",
			"I nap standing up. Saves floor space.",
			"I like customers. You're one of those.",
			"I carried a whole stack of crates today.",
			"The lamp rolled away. Whole lamp. Oops.",
			"Pip talks fast. I just nod along.",
			"We're out of blue lamps. Sorry about that.",
			"I stack boxes really well. Very neat stacks.",
			"Pip says I'm slow. I say I'm careful.",
			"I like quiet mornings before we open.",
			"Sat on a crate by accident. Oops. Sorry, crate.",
		],
		"time_lines": {
			"dawn": ["I'm already up. I unlocked the shop myself.", "Morning! Pip is still yawning."],
			"day": ["Best hours of the day, these.", "Busy day! Two whole customers!"],
			"dusk": ["Closing soon. Ish. Don't rush.", "Dusk makes everything look nicer."],
			"night": ["Still open. I think. Pip?", "Night shift is quiet. I like quiet."],
		},
		"deco_lines": {
			"none": ["Nothing on your planet at all? Oh!", "An empty planet! Lots of room for hugs."],
			"few": ["A few pieces! Nice and tidy.", "You've begun! Pip will be thrilled."],
			"many": ["Your planet is packed! Wonderful.", "So many items! Your planet looks great."],
		},
		"favor": {
			"fetch": ["We're short on stock. Again.", "Find %d %s? I lost track of ours."],
			"bring": ["We need materials. Kind of urgently.", "Bring %d %s and the shop is saved!"],
			"deliver": ["We wrapped something for %s.", "Deliver it? I tied the bow. Sorry."],
			"progress": ["Good progress! Pip is watching.", "Nearly there! I can feel it."],
			"thanks": ["Yay! We're back in business!", "Here, take this. From the good shelf."],
			"decline": ["Oh. Okay! I'll do it. Slowly.", "No worries! I'll figure it out."],
			"remind": ["Still on that errand? Take your time.", "Our shelves miss you. Mostly."],
			"gift": ["A delivery! For us! Yay!", "It's heavy. I'll pretend it isn't."],
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
		# 3.0 put her dead centre on the door axis, 0.05-1.03 m INSIDE the front-steps collider
		# (clothes_store.gd:59 step_block spans 2.02-3.05 m out on this axis) -- measured stuck-in-
		# steps, the same class of bug as the Professor (docs/OPEN_ISSUES.md, this fix). 3.6 clears
		# the steps' outer edge (3.05 m) by 0.55 m, past her own 0.34 m body radius with margin.
		"home_offset_m": 3.6,
		"home_side_m": 0.0,
		"wander_radius_m": 5.0,
		"intro": [
			"Welcome, darling! I'm Stella.",
			"I run Suit-Up. Best outfits in space.",
			"Stand still — let me look at you.",
		],
		"greet": {
			"low": ["Welcome to Suit-Up, darling.", "Hello! Let me see that outfit.", "Come in, come in. Mind the pins.", "Ooh, a new face! Love it already."],
			"mid": ["Back for more? Great instincts.", "Hello, darling. That colour suits you.", "Ah, my favourite customer returns!", "Welcome back! I saved you a colour."],
			"high": ["My muse! Sit. Let me admire you.", "Darling! I made something for you.", "You! Yes! The look is coming together.", "There's my star. Come in, sit down."],
		},
		"small_talk": [
			"A helmet is just a hat with style.",
			"Never wear two golds. One gold. Always.",
			"Space is dark. Your clothes don't have to be.",
			"I dream in fabric. Mostly stripes.",
			"That suit? Old, but still lovely, darling.",
			"Boots first. Everything else follows boots.",
			"I measured a comet once. True story.",
			"Pastels look great in orbit. Trust me.",
			"A good stripe can save the whole day.",
			"I sew by starlight. Very calming.",
			"Confidence is the real accessory, darling.",
			"My tape measure has seen four planets.",
			"Colour first, comfort second, always.",
			"I love making people feel good in their clothes.",
		],
		"time_lines": {
			"dawn": ["Morning light is the honest light.", "Early! Good time for fittings."],
			"day": ["Perfect light for choosing colours.", "Midday. The mirrors are kindest now."],
			"dusk": ["Dusk. Everything looks fancy now.", "Golden hour. My favourite fabric."],
			"night": ["Night shopping. Very glamorous.", "The lamps make every colour softer."],
		},
		"deco_lines": {
			"none": ["Your planet needs some style, darling.", "Bare planet? That's a fresh start!"],
			"few": ["A few pieces already! Lovely.", "You've begun styling your planet. Nice!"],
			"many": ["Your planet is fully styled!", "Darling, your planet has a LOOK."],
		},
		"favor": {
			"fetch": ["A tiny favour, if you have a moment.", "Fetch me %d %s? For a new trim."],
			"bring": ["I'm short on materials for an order.", "Bring me %d %s and I'll make magic."],
			"deliver": ["I made something for %s. A gift.", "Would you carry it? Don't crease it."],
			"progress": ["Coming along nicely, darling.", "Good, good. Keep going, darling."],
			"thanks": ["Perfect. Exactly what I needed.", "Take this. It didn't suit my window."],
			"decline": ["Of course. Fashion can wait.", "Another time. No trouble at all."],
			"remind": ["Still hunting? Take your time, darling.", "My order can wait. Mostly."],
			"gift": ["A parcel! Beautifully carried, too.", "Oh, the wrapping! Someone has taste."],
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
		# 3.2 sat him DEAD CENTRE ON THE DOOR AXIS, INSIDE the front steps: town_hall.gd:59 bakes a
		# step_block spanning 2.93-4.05 m out on this exact axis, so his own home spot was on the
		# steps -- not just his wander -- which is the actual "stuck on the door" bug (measured:
		# 150/150 Footprint contacts, docs/OPEN_ISSUES.md, this fix). 4.6 clears the steps' outer
		# edge (4.05 m) by 0.55 m, past his own 0.34 m body radius with margin to spare.
		"home_offset_m": 4.6,
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
			"I've named so many stars. I forget which ones.",
			"A good telescope is worth two maps.",
			"My goggles are for stargazing. And soup steam.",
			"I once waved at a comet. It waved back. Probably.",
			"The sky never rushes. I try not to, either.",
			"More rocks fall up here than you'd think.",
			"I keep a notebook of every falling star.",
			"It's very loud over at the event space. Nova's there.",
			"I oil my telescope on Sundays. Tradition.",
			"No clouds out here. Terrible for excuses.",
			"Look up long enough and you'll see everything.",
			"I lost my pencil. It's behind my ear. It always is.",
			"I once fell asleep looking through my scope.",
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
			# STORY_HOME_SPEC.md 5.3: the old "telescope needs a small repair" retired (ruling 2.10 -
			# his telescope already works; it is how he watches the meteor).
			"bring": ["I'm charting that meteor, and I've run short.", "Bring me %d %s, if it's no trouble."],
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
			"mid": ["Hey, my regular! Good to see you again!", "You're back! The speakers remembered you.", "Hey! I saved a track just for you."],
			"high": ["My favourite person! The floor is yours.", "Yooo! Best friend on the decks tonight!", "You! Yes! This next one is dedicated!"],
		},
		"small_talk": [
			"Bass is just a hug you can hear.",
			"I float so I can dance all day. No sore feet!",
			"120 beats every minute. Every single time.",
			"Silence? Never met her. Sounds fake.",
			"I remix the planet's hum on Fridays.",
			"Ever dance in low gravity? Life-changing.",
			"My visor shows the beat. Look! LOOK!",
			"Track five is my baby. Don't skip it.",
			"If it doesn't glow, it doesn't go.",
			"I once DJ'd for four rocks and a moth.",
			"Turn it up. No, further. Perfect.",
			"Every planet has a rhythm. Ours is funky.",
			"I love a good light show. LOVE it.",
			"Dancing fixes almost everything. Try it.",
		],
		"time_lines": {
			"dawn": ["Sunrise set! Softer. Still loud.", "Sunrise needs a good beat too. Trust me."],
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
			"deliver": ["Made something special for %s!", "Run it over for me? Don't scratch it."],
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
			"Hi! Come sit in the sun with me. It's warm.",
			"I'm Fen. I'm a flower. My sun never sets!",
			"So for me, it's like lunch all day long.",
		],
		"greet": {
			"low": [
				"Hello, friend. Come sit in the sun with me.",
				"Hi there! Watch out, the salt is crunchy.",
				"Welcome to Long Dusk. The sun stays low here.",
				"Oh, hello! You made a nice shadow just now.",
			],
			"mid": [
				"You're back! My petals perked right up.",
				"Hi, friend! The sun's out. It's always out.",
				"Hello again! The moths said you were coming.",
				"Hey! Sit by the pool with me for a bit.",
			],
			"high": [
				"My friend! I saved you the sunniest spot.",
				"There you are! My leaves did a little wave.",
				"Hi hi! Come on, the pools are glowing today.",
				"You came all this way! That makes me smile.",
			],
		},
		"small_talk": [
			"My sun never sets. It's like lunch all day.",
			"Pool water is my favourite drink. Cold and fresh.",
			"The glow moths visit my flower every evening.",
			"I sprouted right by that pool over there.",
			"My roots go deep. They tickle a little.",
			"Sunbathing is my job. I'm very good at it.",
			"The old arch is a nice spot to sit and rest.",
			"No moon here. Just me and my big, warm sun.",
			"Zorp and I swap gardening tips. He talks a LOT.",
			"Salt crunches when you walk. I like the sound.",
			"I turn my petals to the sun. It feels so nice.",
			"Some evenings the whole ground turns orange.",
			"Gloop never hurries. I like that about Gloop.",
			"A good drink and some sun. That's all I need.",
		],
		"time_lines": {
			"dawn": ["Morning? The sun barely moves. I don't mind.", "Early. The pools are still sleepy."],
			"day": ["Midday. The sun sits just above the ground.", "The shade here is long enough for a nap."],
			"dusk": ["Evening. My favourite. Well, it's always this.", "The pools turn orange now. So pretty. Look!"],
			"night": ["It got dark! No moon, just lots of stars.", "Night. My petals close up. Just a little."],
		},
		"deco_lines": {
			"none": ["Your planet is bare. Plant something nice!", "Nothing out yet? That's fine. Take your time."],
			"few": ["You put some things out. Nice start!", "A few things! Your planet is sprouting."],
			"many": ["Your planet looks so cared for. I love it.", "So many things! Like a garden in full bloom."],
		},
		"favor": {
			"play": [
				"The moths wandered off again. Guide them home?",
			],
			"fetch": [
				"Could you help me with something small?",
				"Could you gather %d %s for my garden?",
			],
			"bring": [
				"I'm fixing up my garden. I need a few things.",
				"Bring me %d %s and I'll plant something new.",
			],
			"deliver": [
				"I grew a little gift for %s. It smells nice.",
				"Could you carry it over? Mind the petals.",
			],
			"progress": [
				"No hurry. The sun isn't going anywhere.",
				"Nice! It's coming along. Keep going.",
			],
			"thanks": [
				"Thank you. My petals feel brighter already.",
				"Take this. I grew it just for you.",
			],
			"decline": [
				"Of course. Maybe another sunny day.",
				"That's okay! Every day here is sunny.",
			],
			"remind": [
				"My little favour still stands. No rush.",
				"Pop by when you're ready. I'll be here.",
			],
			"gift": [
				"A present? For me? Oh, that's so sweet.",
				"Please tell them thank you. It made my day.",
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
			"Hmph. Stop there. Mind the stairs.",
			"I'm Grig. I carved the big stairs up this hill.",
			"Every one of them. By hand.",
		],
		"greet": {
			"low": [
				"Hmph. A visitor. Mind the stairs.",
				"Hello. Walk up the middle, not the edge.",
				"You again. Fine. Come up, then.",
				"Welcome to my hill. Take the stairs slowly.",
			],
			"mid": [
				"Hmph. You again. Good. Mind the stairs.",
				"Back again? You're getting good at stairs.",
				"Hello. I swept the stairs. Not for you. Mostly.",
				"Good day. I saved you the flattest stair.",
			],
			"high": [
				"There you are. Sit. I carved you a seat.",
				"You! Come up. I carved a new stair for you.",
				"My best neighbour. My only neighbour. Still best.",
				"Hmph. I missed you. Don't tell anyone.",
			],
		},
		"small_talk": [
			"I carved every stair on this hill. By hand.",
			"Stone is good. Stone stays where you put it.",
			"Hard work is the best work. Hmph.",
			"You stand on the edge. Everyone does. Don't.",
			"My chisel is older than your planet. Probably.",
			"Dust gets in the corners. I sweep. It comes back.",
			"Zorp is loud. But his flowers are nice. Hmph.",
			"Bolt is a real worker. I respect that.",
			"Pop carries stones for me. Nobody else is allowed.",
			"Moss grows on the shady side. Only the shady side.",
			"Never run down stairs. That's how you fall.",
			"The ring up there looks flat, like a line. I like it.",
			"Chalk is soft. That's why it's easy to carve.",
			"A good stair fits your foot. Mine all do.",
		],
		"time_lines": {
			"dawn": ["Morning. Good. The chalk is still cool.", "Early. The stairs throw long shadows now."],
			"day": ["Midday. Good light for carving.", "Hot out. Stay on the shady stairs."],
			"dusk": ["Evening. The stairs turn gold. Enjoy it.", "Sunset. Time to put the chisel down."],
			"night": ["Two moons up. The big one lights the stairs.", "Night. The ring is a bright line up there."],
		},
		"deco_lines": {
			"none": ["Nothing out yet. Fine. Start somewhere.", "An empty planet. Start in a corner. Always."],
			"few": ["A few things. Line them up next time.", "You've started. Mind your spacing."],
			"many": ["Hmph. Well done. Most of it is well placed.", "Your planet looks good. I like it. Mostly."],
		},
		"favor": {
			"play": [
				"Help me find water again? Walk slow, like before.",
			],
			"fetch": [
				"Got a job for you, if your legs are good.",
				"Gather %d %s for me? For the stairs.",
			],
			"bring": [
				"I'm carving a new stair. I'm short on stuff.",
				"Bring me %d %s and I'll finish it.",
			],
			"deliver": [
				"I carved something for %s. Flat and neat.",
				"Carry it carefully. Don't chip the corners.",
			],
			"progress": [
				"Good. Slow and steady gets it done.",
				"Keep at it. Good workers don't stop.",
			],
			"thanks": [
				"Hmph. Good work. ...Thank you. There, I said it.",
				"Take this. I made it myself.",
			],
			"decline": [
				"No? Fine. The stone isn't going anywhere.",
				"Another day, then. I've got stairs to sweep.",
			],
			"remind": [
				"My job still needs doing. Mind the loose stair.",
				"No rush. My stairs have waited this long.",
			],
			"gift": [
				"A parcel? For me? Hmph. ...That's nice.",
				"Tell them thanks. Don't tell them I smiled.",
			],
		},
	},
	# ==========================================================================================
	## Vela — the lightbulb who listens to the stars, and the cast's second robot neighbour (he/him).
	##
	## HIS VOICE (docs/CAST_VOICES_DRAFT.md, approved 2026-09-27): gentle, dreamy, a little shy, and
	## clever about far-off sounds. He has no mouth, so he says aloud when his bulb glows ("My bulb just
	## lit up."). Plain whole sentences; no filing, logging or counting (numbers are Bolt's joke only).
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
			"Oh! Hello. Sorry, I was listening to the stars.",
			"I'm Vela. My dishes hear songs from far away.",
			"See my bulb glowing? That means I'm glad.",
		],
		"greet": {
			"low": [
				"Oh, hello! My bulb just lit up. That means I'm glad.",
				"Hello. Mind the cables in the snow.",
				"Oh! A visitor. Hello. I'm a bit shy.",
				"Hello. It's cold. Stand near my bulb. It's warm.",
			],
			"mid": [
				"Oh, it's you! My bulb is glowing already.",
				"Welcome back. I saved you a quiet spot.",
				"Hello, friend. Want to listen to the sky?",
				"You came back! I hoped you would.",
			],
			"high": [
				"My friend! Look, I'm glowing. I can't help it.",
				"Oh, you! I saved a star song for you.",
				"Hello, dear friend. Sit with me a while.",
				"You're here! My bulb is as bright as it goes.",
			],
		},
		"small_talk": [
			"Space is full of sounds. I listen all night.",
			"My dishes hear songs from very far away.",
			"I have no mouth, so my bulb does my smiling.",
			"The cold doesn't bother me. I'm a warm light.",
			"I heard a whole star song once. It was lovely.",
			"Snow makes everything quiet. I like quiet.",
			"The frozen lake shows the sky upside down.",
			"DJ Nova plays slow songs just for me. Shh.",
			"Bolt and I swap spare parts. He's very fair.",
			"The wind hums in the masts. It's a bit off-key.",
			"When I get an idea, my bulb lights up. Ping!",
			"I like listening more than talking. Is that okay?",
			"The masts keep their lamps on, so nobody gets lost.",
			"My glass gets foggy on cold mornings. Oops.",
		],
		"time_lines": {
			"dawn": ["Good morning. The sky is so quiet now.", "Dawn. The snow looks pink. Pretty."],
			"day": ["Midday. The sun is noisy on my dishes.", "Good day. My dishes are warm to the touch."],
			"dusk": ["Evening. The far-away songs start now.", "Dusk is my favourite. Listen. Hear that?"],
			"night": ["Night. The whole sky is singing. Lovely.", "It's late. I'm still listening, if you need me."],
		},
		"deco_lines": {
			"none": ["Your planet is empty. That's okay.", "Nothing out yet. You have lots of time."],
			"few": ["A few nice things. I like how they're spaced.", "You've started! My bulb flickered. That's good."],
			"many": ["Your planet is so lovely. Truly.", "So many things! I looked at every one."],
		},
		"favor": {
			"play": [
				"Would you answer my calls again? It's fun.",
			],
			"fetch": [
				"Um, could I ask a small favour?",
				"Could you gather %d %s for my dishes?",
			],
			"bring": [
				"One of my dishes went quiet. I need parts.",
				"Could you bring me %d %s? Then I can fix it.",
			],
			"deliver": [
				"I wrote a little star song for %s.",
				"Could you take it to them? It's not fragile.",
			],
			"progress": [
				"That's lovely. There's no hurry at all.",
				"Good progress. I'll be here, listening.",
			],
			"thanks": [
				"Thank you! I'm glowing. I can't help it.",
				"Please take this. It means a lot to me.",
			],
			"decline": [
				"Oh, that's okay. Maybe another day.",
				"That's fine. I'll keep listening.",
			],
			"remind": [
				"My little favour still stands. No hurry.",
				"Whenever you're ready. I'll be here.",
			],
			"gift": [
				"A present for me? Oh! My bulb just lit up.",
				"Please tell them thank you. It's lovely.",
			],
		},
	},
}


## PACKING SMALL TALK (docs/STORY_HOME_SPEC.md 5.5): two lines mixed into the ordinary small-talk pool
## while the story runs and the finale has not happened yet, one line once it has. Read through
## `GameState.story_done` (set once, by the finale, and never cleared in a finished game) - never any
## of the finale's own stage machinery, which belongs to another builder's files.
const PACKING_TALK := {
	"zorp": {
		"before": [
			"Packing is HARD! Everything I own glows!",
			"The Professor wants to PUSH a meteor. Oh ho!",
		],
		"after": ["I unpacked EVERYTHING! It all still glows!"],
	},
	"bolt": {
		"before": [
			"I packed 212 boxes. I labelled 212 boxes.",
			"Push a meteor? I did the maths. It is very hard.",
		],
		"after": ["I unpacked 212 boxes. I am staying. 100 percent."],
	},
	"fen": {
		"before": [
			"I packed my watering can. And my sun hat.",
			"The Professor means well. He always does.",
		],
		"after": ["Unpacked my watering can. Time for a drink!"],
	},
	"grig": {
		"before": [
			"Packed. Unpacked. Packed again. Hmph.",
			"Push a meteor? With one ship? Hmph. No.",
		],
		"after": ["Unpacked. My stairs and I are staying put."],
	},
	"vela": {
		"before": [
			"I'll take my little dish. The big ones stay.",
			"The Professor wants our ships. But we need them.",
		],
		"after": ["Still listening. The sky sounds happier now."],
	},
}


## This neighbour's packing lines for right now (5.5's gate): "" for any neighbour not in the table.
static func _packing_lines(npc_id: String) -> Array:
	var pool: Variant = PACKING_TALK.get(npc_id, {})
	if not (pool is Dictionary):
		return []
	var key := "after" if GameState.story_done else "before"
	var lines: Variant = (pool as Dictionary).get(key, [])
	return lines if lines is Array else []


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


## One small-talk line, never the same as `avoid`. Mixes in this neighbour's packing lines (5.5, only
## before or only after the finale) with the ordinary pool, rather than picking between them.
static func small_talk(npc_id: String, avoid: String = "", rng: RandomNumberGenerator = null) -> String:
	var d := get_data(npc_id)
	var pool: Array = d.get("small_talk", []) + _packing_lines(npc_id)
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
