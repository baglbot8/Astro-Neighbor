# CAST_VOICES_DRAFT.md — a fresh voice for every neighbour

**Status:** DRAFT for the lead, 2026-09-27. Not a contract yet. Read-only research: nothing in the game
was changed. Source build: `.astro_scratch/safari6-0921/merge11` (`src/characters/models/*`,
`npc_data.gd`, `src/projects/data/*.gd`, `src/campaign/*_lines.gd`, `src/spike/gloop_lines.gd`).

**Why:** the user (2026-09-27): the dialogue is "very cryptic and a bit confusing. Not many neighbors
speak normally"; Fen talks "about ruins a lot" and "never really says plant related things"; Grig is
"always talking about steps but its unclear what that is"; characters swing between "smart" and
"dumb"; Pip and Pop "still act like twins". Also: **Vela is a lightbulb, and he is a he.**

## 1. What is wrong today (measured on the lines, not guessed)

1. **Four neighbours share one voice: the note-taker.** Bolt counts, Fen logs, Grig numbers, Vela
   files. The same jokes repeat across them: "counted twice" / "logged it. Twice" (Bolt, Fen, Grig),
   "I keep spares. I always keep spares." (Fen AND Grig, word for word), "Recorded." (Grig, Vela).
   When everyone is a clipboard, nobody has a personality.
2. **Clipped fragments instead of sentences.** "Correctly ordered." "Rare entry, that." "Six-A."
   "Resolution: low. Recalibrate. Retry." A 10-year-old has to decode them.
3. **Private jargon never explained.** Grig: riser, tread, curing, tier, chalk shelf. Fen: crust,
   pan, rim, stone three, pool four. Vela: gain, array, channel, plate. Stella: silhouette, hemline,
   couture, capsule collection. Game words leak in: "safari-side", "Fine or better", "Once a safari".
4. **Lines written for the old models.** Fen's voice was written for the three-eyestalk "pan-watcher"
   and survived two redesigns into a flower; not one Fen line mentions sun, water, roots or petals.
   Pip and Pop's whole script is the old twin gag (antenna counting, finishing each other's "...").
   Vela is "she/her" in lines and code, and nothing she says is about being a bulb.
5. **Gloop talks about photos as food** ("thin soup", "get me a slice", "crust on it"). Cute once,
   but a kid cannot tell what Gloop wants.

## 2. Rules for every line (proposed for STYLE_GUIDE once approved)

- Plain, whole, short sentences. A 10-year-old understands it the first time, read once.
- **One trait, one smartness level, per character** (table below). A line that breaks the level is cut.
- **At most one verbal habit**, used in at most one line in four. A habit may add flavour, never hide
  what the line means.
- Only **Bolt** uses numbers as a joke. Nobody else counts, logs, files or numbers things.
- Any word a kid might not know is said once in plain words first ("the big stairs I carved").
- No game-system words in a character's mouth (safari-side, stardust grade names, tiers).
- Lines stay <= 60 characters (all samples below were checked).

| Who | Smartness | One trait | Habit (max one) |
|---|---|---|---|
| Zorp | curious kid, bright but gets Earth wrong | excitable | starts a line with "Fun fact!" |
| Bolt | very good with numbers, bad at jokes and feelings | literal and loyal | gives a number |
| Fen | wise and slow, like a grandparent | calm, sunny gardener | talks about sun and water as food |
| Grig | practical, hands-on, not bookish | grumpy outside, soft inside | "Hmph." |
| Vela | clever, dreamy, a bit shy | gentle listener | glows when happy (said aloud) |
| Prof. Comet | the real scientist; very smart, forgetful | kind and hopeful | loses things |
| Pip | quick and sharp, a little bossy | fast-talking little boss | calls you "customer" |
| Pop | slow and simple, never mean | big, gentle, clumsy | "Oops." |
| Stella | expert in her one thing | confident, generous | "darling" |
| DJ Nova | street-smart, not bookish | loud party-lover | one word in CAPS |
| Gloop | simple and sleepy | slow, cosy shopkeeper | "Mmm." |
| Norm | tries hard, gets human things wrong | pretend-human | "as a normal human" |

---

## 3. The cast

### Zorp — the glowing-garden alien (he)
**Looks now:** a lavender chibi alien with big black oval eyes, a scarf, and a beard of four fat curly
tentacles where his mouth would be. **World:** Violet Hollow — glowing rivers, mushroom trees,
crystals that chime at night, two moons.

**Personality:** the excitable, curious one. Bright and quick, but his "Earth facts" are funny and
wrong — he is never dumb about his own world. Loves his glowing garden, the singing crystals, and
you (the first Earth person he has met). Says "I", never "Zorp is pleased".

**Friends:** grows flowers for everyone (he gives Grig the seed); best buddies with Fen, "the only
flower who talks back"; thinks Bolt is the funniest person alive, though Bolt is not joking.

| Beat | Line |
|---|---|
| Greeting | "Hi hi! My tentacles wiggled. I knew it was you!" |
| Small talk | "Fun fact! Earth people sleep lying DOWN. Wild!" |
| Favour ask | "Can you pick 3 glow caps? My garden needs them!" |
| Thanks | "You did it! My whole garden is glowing for you!" |
| Last-photo hint | "That chime? It's what I fall asleep to. Every night." |

**Changes:** keep the energy; cut third-person "Zorp", cut "science is patient" (he is a gardener,
not a scientist). **Cut:** "Zorp is pleased. Zorp is very pleased!", "My samples await. No rush.
Some rush.", "Take this. It was cluttering my hollow." (hollow = his world; kids read "a hole").

### Bolt — the fix-it robot (he)
**Looks now:** a boxy, pale-teal walking robot with a screen face (small dark eyes, a smile), one
antenna with a blinking light, claw hands, and a dial on his chest that spins when he talks.
**World:** Chrome Yard — metal plates, machines, a big ring overhead, masts.

**Personality:** literal, loyal, and proud of fixing things. The ONLY neighbour who counts. Smart
with numbers, clueless about jokes — he answers jokes seriously, which is the joke. Loves his
machines, tidy toolboxes and you. Talks in whole plain sentences, not "status reports".

**Friends:** Zorp's giggling confuses him; he secretly oils the Professor's cane; he and Vela are the
two robots and swap spare parts.

| Beat | Line |
|---|---|
| Greeting | "Hello, friend. This is visit number 9. I counted." |
| Small talk | "I fixed 12 things today. One was my own foot." |
| Favour ask | "Could you find 5 bolts? My machine is wobbly." |
| Thanks | "Thank you! My chest dial is spinning. That is joy." |
| Last-photo hint | "That mast fits me just right. I climbed it 412 times." |

**Changes:** keep the numbers, drop the robot-jargon (detected, nominal, logged, archived, efficiency).
**Cut:** "Visitor detected. Visitor welcomed.", "Rust is just metal being emotional.", "Please deliver
it. Handle with 60% care.", "Data received. Resolution: low. Recalibrate. Retry."

### Fen — the flower who loves the long sunset (he, per current text)
**Looks now:** a walking plant: a pale bud face with two small dark eyes, inside a big ring of petals
like a collar, on a slim green stem, with four long vines for arms and legs that curl up at the tips.
**World:** Long Dusk — the sun sits low forever, a warm orange salt flat, fourteen round pools, an old
stone arch and a row of standing stones, glow moths.

**Personality:** the calm, sunny gardener. A plant who LOVES that his sun never sets — it is lunch
all day. Wise and slow like a kind grandparent; never cryptic. Loves the low warm sun, the water in
his pools, and his glow moths (they visit his flower). The stone arch is just "the old arch" and a
nice place to sit — he does not know who built it and does not talk about it much.

**Friends:** Zorp is his gardening buddy; he is the one who remembers the old days for Vela (the
warm-dish page); he likes Gloop because Gloop, too, never hurries.

| Beat | Line |
|---|---|
| Greeting | "Hello, friend. Come sit in the sun with me." |
| Small talk | "My sun never sets. It is like lunch all day long." |
| Favour ask | "My roots are thirsty. Could you fetch 3 dew drops?" |
| Thanks | "Thank you. My petals feel brighter already." |
| Last-photo hint | "I sprouted by that pool. I will miss it." |

**Changes:** rewrite him almost completely: from terse note-keeper to sunny flower. Keep the patience,
the moths and the pools; drop the logbook, the numbered pools and stones, the "crust". The finale
callback "Nine years of notes. I am not done watching." becomes "My roots are here. I'm not going."
**Cut:** "You cast a good shadow. Seven metres, near.", "Take the shade of stone three.", "I number
the pools. Fourteen. Sometimes thirteen.", "Salt grows back overnight. Quietly. Rudely.", "Walk slow.
The crust remembers every foot.", "Logged as: neighbour, in full. Rare entry, that."
**Also:** his safari is titled "The Misty Ruins" in `fen.gd` — the word "ruins" is probably where the
user's confusion started. Suggest "The Glowing Pools".

### Grig — the stair carver (he)
**Looks now:** a big, slow stone creature with a tall rounded head, ONE huge eye on a thick stalk,
an under-bite with two little tusks, cracked grey skin, and a necklace of chalk tiles.
**World:** Chalk Steps — a white chalk hill he has carved into giant stairs, a ring of standing
stones on top, two big moons, a ring edge-on in the sky.

**Personality:** grumpy on the outside, soft on the inside. A hard worker who spent his whole life
carving huge stairs up his hill so everyone can reach the top. Practical, not bookish. Loves stone,
hard work, and — secretly — the view from the top. Never counts or numbers (that is Bolt's). The
word "steps" is always made clear: "my stairs", "the big stairs I carved".

**Friends:** grumbles at Zorp's noise but plants Zorp's flowers; respects Bolt as "a real worker";
Pop is the only one he lets carry stones for him.

| Beat | Line |
|---|---|
| Greeting | "Hmph. You again. Good. Mind the stairs." |
| Small talk | "I carved every stair on this hill. By hand." |
| Favour ask | "My chisel's blunt. Bring me 4 hard rocks?" |
| Thanks | "Hmph. Good work. ...Thank you. There, I said it." |
| Last-photo hint | "I forgot how nice the view is from up here." |

**Changes:** from "blunt numberer of risers" to "grumpy builder with a soft heart". Drop every
building term (riser, tread, curing, tier, shelf) and all numbering. The finale callbacks become
"Closed my stairs for the day." and "Best view there is. I'm staying."
**Cut:** "Stop there. That riser is still curing.", "A riser is knee high or it is not a riser.",
"Nine hundred steps cut. I have views on eight.", "The big moon lights the treads. The small sulks.",
"Ah! I numbered a riser after you. Six-A.", "Chalk forgives nothing. Measure twice. Again."

### Vela — the lightbulb who listens to the stars (HE)
**Looks now:** a robot whose head is a big glass lightbulb screwed into a socket, with two green
camera-lens eyes on a hoop in front of it, no mouth, and brushed-metal plates. **World:** Still Frost
— a snowy plain, a row of eight tall radio masts with warm amber lamps, big dishes, a frozen lake.

**Personality:** gentle, dreamy, a little shy. Clever — he listens to faraway space sounds on his
radio dishes and hears songs in them. His bulb glows when he is happy or has an idea, and he says so,
because he has no mouth to smile with ("Oh! My bulb just lit up."). Loves quiet, far-off sounds, and
being the warm light on a cold planet. Polite without being stiff: no "most sincerely", no filing.

**Friends:** the quiet opposite of DJ Nova, who he secretly adores ("he plays the slow songs for
me"); swaps parts with Bolt; asks Fen, who remembers the old days, about when his dish was warm.

| Beat | Line |
|---|---|
| Greeting | "Oh, hello! My bulb just lit up. That means I'm glad." |
| Small talk | "Space is full of sounds. I listen to them all night." |
| Favour ask | "Dish two went quiet. Could you bring me 3 wires?" |
| Thanks | "Thank you! I'm glowing. I can't help it." |
| Last-photo hint | "I'll keep this photo always. It's my home." |

**Changes:** he/him everywhere (lines, safari file comments, `npc_data.gd` header). Lightbulb jokes
come from warmth and glowing, not from records. **Pronoun fixes:** `vela.gd:270` "Page, torn out for
her" -> "for him"; Gloop's `gloop_lines.gd:88,92` "She said..." / "She held it..." -> "He".
**Cut:** "I do not sleep. I lower my gain and drift.", "Your planet is unfurnished. A clean signal.",
"I have no mouth. I manage. Lights are eloquent.", "Precisely right. Thank you, most sincerely.",
"The mirror moon, in the ice. Once a safari. Sharp."

### Professor Comet — the sky scientist (he)
**Looks now:** an old brass robot in an open grey lab coat and tie, round glasses, stargazing goggles
up on his forehead, white hair puffs, a pencil behind his ear, and a wooden cane.
**World:** the Commons (hub); his telescope by the town hall.

**Personality:** the real scientist, and the only one who is smart in a book way. Kind, hopeful and
forgetful — he loses his pencil, never his kindness. Loves the sky, the meteor puzzle, and tea.
Already reads well; keep him.

**Friends:** everyone's grandpa; the only one not packing; kindly teased by all ("push a meteor?").

| Beat | Line |
|---|---|
| Greeting | "Ah, hello, friend! Mind my telescope." |
| Small talk | "I lost my pencil. It's behind my ear. It always is." |
| Favour ask | "Could you fetch 3 star rocks for my charts?" |
| Thanks | "Wonderful! Just what my charts needed." |
| Story hint | "Funny thing. That streak is in all your photos." |

**Changes:** light touch. **Cut:** "Kindness is like starlight. It travels far." (fine but preachy),
"Do visit the event space. It thumps." ("thumps" is unclear; say "It's very loud. Nova's there.").

### Pip — the little saucer pilot, boss of Cosmo Depot (she, as Gloop already says)
**Looks now:** a tiny green alien with big black almond eyes, riding in a small flying saucer with two
levers, a star-tipped antenna off the back of the saucer.

**Personality:** the fast-talking little boss. Quick and sharp with deals, a little bossy, never mean.
Loves her saucer, a good sale and her shop. Calls you "customer" (even when you are a friend).

**Pip and Pop now:** **not twins, not siblings — best friends who run the shop together.** Pip is the
small, fast brains of the shop; Pop is the big, slow, gentle muscle. Tiny boss and big helper is a
pair a kid gets instantly from the picture.

| Beat | Line |
|---|---|
| Greeting | "Welcome to Cosmo Depot! Best shop in space!" |
| Small talk | "I fly to work. Pop walks. Pop is always late." |
| Favour ask | "We're out of lamps! Grab me 3 glow bulbs?" |
| Thanks | "Deal! You're my favourite customer, customer." |
| Story hint | "Don't tell anyone. We never packed the lamps." |

**Changes:** drop the antenna counting, "Pop owes me a rock", and "Pop, look!" as filler.
**Cut:** "That's my brother Pop. He has two antennae.", "One antenna. Best antenna. Fact.", "I only
have one. It's the cooler amount.", "Take this. It fell off a shelf. Legally."

### Pop — the big fuzzy helper at Cosmo Depot (he)
**Looks now:** a big round apricot-orange fuzzy monster, a wide smile full of little teeth, two
feelers with fluffy tips, and a shop bag across his body. Waddles; a bit clumsy.

**Personality:** big, gentle, slow and clumsy — the simple one, but never the butt of cruel jokes.
Loves customers, carrying heavy things, and hugs. Drops things and says "Oops." Does not finish
Pip's sentences (the "..." gag reads as a mistake now that they are not twins).

| Beat | Line |
|---|---|
| Greeting | "Hi! Want a hug? I'm very soft." |
| Small talk | "I dropped a lamp today. Oops. It still works!" |
| Favour ask | "I can carry lots. Can you find 3 crates for me?" |
| Thanks | "Yay! Thank you! I'd hug you, but I'm holding boxes." |
| Story hint | "Pip says we're leaving. I'm keeping my box open." |

**Changes:** new voice. **Cut:** every line starting "..." (e.g. "...to Cosmo Depot! Pip started
it.", "...which is why we never sell soup."), "Two antennae. Double the listening!", "Pip talks. I do
the arithmetic." (he is not the numbers one). **Story callback:** the finale's Pip/Pop pair can stay
("We unpacked the lamps already..." / "...we never really packed them. Shh.") — it is the one place
the "..." hand-off still earns its keep.

### Stella — the space tailor (she)
**Looks now:** a fellow astronaut in a dusty-rose suit with a plum trouser and mauve jacket panel, a
rose-tinted visor (no face), a soft work cap and a measuring tape around her shoulders.

**Personality:** confident, generous fashion expert. Smart in her one thing, explains it simply.
Loves colour, boots and making people feel good. Says "darling" now and then.

**Friends:** keeps trying to measure Norm; he keeps saying "no thank you".

| Beat | Line |
|---|---|
| Greeting | "Welcome to Suit-Up, darling! Love the boots." |
| Small talk | "Space is dark. Your clothes don't have to be." |
| Favour ask | "Bring me 3 star threads? I'm making a new cap." |
| Thanks | "Perfect! You have great taste, darling." |
| Story hint | "I packed my best fabric. Then unpacked it. Twice." |

**Changes:** swap grown-up fashion words for kid ones. **Cut:** "Oh! A new face. And a new
silhouette.", "Visor tints are the new hemlines.", "A few pieces! A capsule collection.", "Coming
along! Patience makes couture."

### DJ Nova — the floating DJ robot (he)
**Looks now:** a hovering egg-shaped robot in lilac and violet, big headphones with fins, a dark
visor with mint light eyes, a mouth made of a light strip that bounces to the beat, riding a tiny
glowing turntable. No legs.

**Personality:** loud, happy party-lover. Street-smart, not bookish. Loves music, lights and dancing.
One word per line may be in CAPS. Already fairly plain; trim slang.

**Friends:** plays slow songs just for Vela; makes the Professor dance at the finale.

| Beat | Line |
|---|---|
| Greeting | "YO! Welcome to the loudest place in space!" |
| Small talk | "I float so I can dance all day. No sore feet!" |
| Favour ask | "My speaker's broken! Find me 3 wires, please?" |
| Thanks | "You fixed it! This next song is for YOU!" |
| Story hint | "Nobody's leaving till I play one last song." |

**Changes:** light touch. **Cut:** "I wrote a track about a comet. It slaps.", "Made a mixtape for
%s. It goes hard.", "Applause is just clapping with feelings.", "My headphones cost more than my
hover jets."

### Gloop — the sleepy photo seller (they/it; no pronoun in shipped text)
**Looks now:** a berry-red jelly blob, wide at the bottom like a puddle, with a drip on top and a
little glowing star floating inside. No legs.

**Personality:** slow, sleepy, cosy shopkeeper. Simple and kind. Loves selling your photos, naps and
the little star inside (a pet, not a snack). Says "Mmm." when something is good. **Photos are
photos**, not food.

**Friends:** tells you who bought what (already a lovely feature — keep it).

| Beat | Line |
|---|---|
| Greeting | "Mmm. Hello. Got some photos for me?" |
| Small talk | "I sell your photos at night. I nap in the day." |
| Hand-in ask | "Leave your photos here. Come back in the morning." |
| Thanks / payout | "Morning! Your photos sold. Here are your coins." |
| Story hint | "Everyone is packing. Not me. I'm too squishy." |

**Changes:** drop the food talk. **Cut:** "Oh. Hello. You taste like cold air.", "No pictures today?
That is a thin soup.", "The worlds are full. Go get me a slice.", "This one has a crust on it.
Perfect.", "I keep a star in me. It is my snack. Later." Grade reactions become plain: "Ooh, a great
one!" / "Nice one." / "A bit blurry. I'll still try."

### Norm — the "normal human" (he)
**Looks now:** a squat chibi in a ragged astronaut suit with a crack in his visor and a big orange
tentacle poking out, plus little tentacles sneaking out of the arms and legs.

**Personality:** tries very hard to pass as a human and gets it funny-wrong — the joke must be
readable by a kid. Friendly, eager, not dumb about quizzes; dumb about humans. Says "as a normal
human". Already the clearest comic voice in the cast; keep it.

**Friends:** avoids Stella's tape measure; Zorp is sure Norm is "a very unusual Earth person".

| Beat | Line |
|---|---|
| Greeting | "Hello, fellow human. I am Norm. Very normal." |
| Small talk | "I love eating food with my mouth. As humans do." |
| Quiz offer | "Want to answer 3 questions? A human game." |
| Thanks | "Correct! My tentacle is doing a happy curl." |
| Story hint | "A meteor? Humans are not scared of those. Right?" |

**Changes:** light touch; swap long words. **Cut:** "Excellent! I am filing you under 'suspiciously
informed'.", "For you! A bronze trophy. I found it. Somewhere honest." (says "stolen" too subtly).

---

## 4. Behaviour ideas that match the new voices (optional, for the lead)

- **Fen** stands in the sun patches and turns his petal collar toward the low sun when idle.
- **Grig** grumbles-emotes ("think") at the player first, then a small happy hop on the second talk.
- **Vela**: his bulb brightens when he talks and when you give a gift (the emissive already exists).
- **Pop** trails a step behind Pip's saucer on the Commons; Pip zips, Pop waddles.
- **Gloop** is asleep (slow squash) in the day unless you walk up.

## 5. Scope and next step

- Files a rewrite touches: `npc_data.gd` (all 12 in-file characters; about 60 lines each),
  `src/projects/data/{zorp,bolt,fen,grig,vela}.gd` (intro, steps, part_lines), `visitor_lines.gd`,
  `finale_lines.gd` (the callbacks named above), `norm_lines.gd`, `gloop_lines.gd`.
- `STORY_HOME_SPEC.md` 5.4/5.5 quote the old lines verbatim; the lead amends it with the new ones.
- Keep format tokens intact: fetch/bring need one line with `%d` and `%s`, deliver one bare `%s`
  (see the note above Vela in `npc_data.gd`).
- Suggested split: one Sonnet builder per file group (disjoint), one critic with this file's rules
  and the smartness table as its checklist, plus a "read it aloud to a 10-year-old" pass.
- Open for the user: Pip's pronoun (Gloop's "she" is the only shipped one) and Fen's (lines say "he";
  the model declares none). Recommend keeping both as written: Pip she, Fen he.
