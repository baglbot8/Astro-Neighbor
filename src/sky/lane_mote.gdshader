shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;
// SPIKE (2026-09-21, scratch only). THE STUFF THE SHIP IS FLYING THROUGH.
//
// The user's fifth note: "the movement direction also help you figure out where you're facing".
// Nothing in the old lane moved except the two planets, and both of them are 500+ metres away, so
// the picture held still while the ship was supposedly doing 35 m/s. This is the fix, and it is
// deliberately NOT a screen-space streak overlay: these are real motes at real depths from 3 m to
// 90 m out, so the perspective does the work the user described for free -
//
//   * a mote near the edge of the window sweeps past fast, one near the vanishing point crawls;
//   * look forward and they bloom OUT of a point ahead of you, look left and they all run right.
//     You can read your heading off the picture alone, which is the whole request.
//
// The mesh is a unit quad, axis-billboarded around the WORLD LANE AXIS (+Z) rather than fully
// camera-facing: a streak has a direction, and a streak that swivels to face you loses it. The
// degenerate case - looking straight down the lane, where the streak points at your eye - is not a
// special case here: the quad simply foreshortens to a dot, which is what a mote coming at you
// looks like. That is why POSITION is built by hand instead of using billboard mode.

uniform float head_bias : hint_range(0.0, 1.0) = 0.80;
uniform float near_fade : hint_range(0.5, 12.0) = 4.5;
uniform float gain : hint_range(0.0, 3.0) = 1.0;

varying float v_fade;

void vertex() {
	vec3 org = MODEL_MATRIX[3].xyz;
	float w = length(MODEL_MATRIX[0].xyz);
	float l = length(MODEL_MATRIX[1].xyz);
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 axis = vec3(0.0, 0.0, 1.0);
	vec3 tc = cam - org;
	float dist = length(tc);
	tc /= max(dist, 0.0001);
	vec3 cr = cross(axis, tc);
	float cl = length(cr);
	vec3 right = cl > 0.002 ? cr / cl : vec3(1.0, 0.0, 0.0);
	vec3 wp = org + right * VERTEX.x * w + axis * VERTEX.y * l;
	// a mote about to hit the glass would be a white flash; fade it out first
	v_fade = smoothstep(0.0, near_fade, dist) * (1.0 - smoothstep(70.0, 110.0, dist));
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
}

void fragment() {
	// across the streak: a soft round profile, never a hard-edged stick
	float across = 1.0 - abs(UV.x - 0.5) * 2.0;
	across = across * across * (3.0 - 2.0 * across);
	// along it: bright at the head (+Z, the way it is going), trailing off behind
	float along = mix(1.0 - head_bias, 1.0, pow(clamp(1.0 - UV.y, 0.0, 1.0), 1.6));
	ALBEDO = COLOR.rgb * across * along * v_fade * COLOR.a * gain;
	ALPHA = 1.0;
}
