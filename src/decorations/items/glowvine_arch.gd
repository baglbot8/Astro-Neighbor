extends DecoItem
## Glow-Vine Arch (Moss's stall, The Tangle) - the showpiece of the stall: two old roots rising from
## splayed feet and twisting round each other overhead, with moss beards and three strands of glowing
## vine beads hanging from the span. You walk under it (non-blocking: the collider would sit in the
## middle of the gap), like the root arches over the Tangle's own trails.

const BARK := Color("#76697a")
const BARK_DARK := Color("#5c5163")
const MOSS := Color("#6b8a4e")
const THREAD := Color("#4f5f4c")
const BEAD := Color("#b8ecd2")


func _init() -> void:
	footprint = 1.2
	blocking = false
	collide_radius = 0.4
	collide_height = 2.3


func _build() -> void:
	var kit := DecoKit.new()
	var glow := DecoKit.new()
	var span := 0.95
	var apex := 2.25
	var main := PackedVector3Array()
	var mr := PackedFloat32Array()
	var mc := PackedColorArray()
	var twin := PackedVector3Array()
	var tr := PackedFloat32Array()
	var tc := PackedColorArray()
	var n := 22
	for i in n + 1:
		var t := float(i) / float(n)
		var ang := PI * t
		var p := Vector3(-cos(ang) * span, sin(ang) * apex - 0.12, 0.05 * sin(3.0 * ang))
		main.append(p)
		var foot := absf(t - 0.5) * 2.0
		mr.append(lerpf(0.09, 0.19, pow(foot, 2.2)))
		mc.append(BARK.lerp(MOSS, clampf(sin(ang) - 0.6, 0.0, 1.0) * 0.9))
		var w := TAU * 2.0 * t
		twin.append(p + Vector3(0.0, cos(w) * 0.13, sin(w) * 0.14))
		tr.append(lerpf(0.05, 0.08, pow(foot, 2.0)))
		tc.append(BARK_DARK.lerp(MOSS, clampf(sin(ang) - 0.7, 0.0, 1.0)))
	JungleMeshes.tube(kit, main, mr, mc, 9, false)
	JungleMeshes.tube(kit, twin, tr, tc, 6, false)
	# splayed feet: three root fingers each side
	for side in [-1.0, 1.0]:
		for k in 3:
			var a := (float(k) - 1.0) * 0.8
			var o := Vector3(side * cos(a), 0.0, sin(a))
			var f0 := Vector3(side * span, 0.22, 0.0)
			JungleMeshes.tube(kit, PackedVector3Array([f0, f0 + o * 0.22 + Vector3(0.0, -0.12, 0.0), f0 + o * 0.42 + Vector3(0.0, -0.26, 0.0)]),
				PackedFloat32Array([0.08, 0.055, 0.03]), PackedColorArray([BARK, BARK_DARK, BARK_DARK]), 6, true)
	# moss beards under the span
	for k in 6:
		var t := 0.24 + 0.52 * float(k) / 5.0
		var ang := PI * t
		var p := Vector3(-cos(ang) * span, sin(ang) * apex - 0.12 - 0.15, 0.0)
		var l := 0.22 + 0.10 * float((k * 5) % 3)
		JungleMeshes.tube(kit, PackedVector3Array([p, p + Vector3(0.01, -l * 0.5, 0.02), p + Vector3(0.0, -l, 0.0)]),
			PackedFloat32Array([0.04, 0.03, 0.012]), PackedColorArray([MOSS, MOSS.darkened(0.1), MOSS.darkened(0.2)]), 5, true)
	# three glowing vine strands
	for k in 3:
		var t := 0.34 + 0.16 * float(k)
		var ang := PI * t
		var top := Vector3(-cos(ang) * span, sin(ang) * apex - 0.20, 0.10 if k == 1 else -0.08)
		var count := 5 - k % 2
		var step := 0.14
		var bottom := top - Vector3(0.0, step * float(count), 0.0)
		kit.cylinder(bottom, 0.010, 0.012, top.y - bottom.y, THREAD, Basis.IDENTITY, 4)
		for b in count:
			var y := top.y - step * (float(b) + 0.8)
			glow.sphere(Vector3(top.x, y, top.z), 0.036 * (1.0 - 0.3 * float(b) / float(count)), BEAD,
				Vector3(1.0, 1.25, 1.0), 6)
	add_body(kit.commit())
	add_glow(glow.commit(), 2.4, "Vines", 0.35, 0.3)
	add_light(Vector3(0.0, 1.5, 0.0), Color("#b8ecd2"), 1.3, 5.0)
	add_ground_glow(1.4, Color("#a8dcc4"), 0.2)
