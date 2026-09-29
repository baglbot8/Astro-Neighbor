shader_type spatial;
// THE METEOR'S STEAM (builder METEOR3, spec 9.6.6: "a bit of a steam haze ... some appearing and disappearing
// rising white dots"). One shader, two uses (one compile), both unshaded, blended, writing no depth:
//   mode 0 - a rising steam mote: a soft round dot on a camera-facing quad; its fade is the instance's COLOR.a
//            (MeteorSteam sets it every frame).
//   mode 1 - the horizon haze: the inside of a big sphere that rides the eye. Steam-coloured where the view
//            meets the rock's horizon (`up_dir` = the rock's up under the eye), clear overhead. Drawn first of
//            the transparent things (render_priority) and depth-tested, so the rock in front hides it and the
//            plumes still add on top of it.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform int mode = 0;
uniform vec3 steam : source_color = vec3(0.70, 0.62, 0.64);
uniform float amount = 0.5;
uniform vec3 up_dir = vec3(0.0, 1.0, 0.0);
uniform float band_low = -0.45;
uniform float band_high = 0.4;

varying vec3 local_dir;

void vertex() {
	local_dir = VERTEX;
}

void fragment() {
	if (mode == 0) {
		float r = length(UV - vec2(0.5)) * 2.0;
		ALBEDO = vec3(0.96, 0.95, 0.97);
		ALPHA = COLOR.a * (1.0 - smoothstep(0.25, 1.0, r));
	} else {
		float elev = dot(normalize(local_dir), normalize(up_dir));
		float a = 1.0 - smoothstep(band_low, band_high, elev);
		ALBEDO = steam;
		ALPHA = amount * a * a;
	}
}
