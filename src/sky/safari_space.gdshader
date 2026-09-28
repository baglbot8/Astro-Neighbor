shader_type sky;
render_mode use_debanding;
#include "res://src/sky/lane_sky.gdshaderinc"
// SPIKE (2026-09-21, scratch only). The NAKED-EYE sky on a flight: what is outside the window.
//
// ROUND 2 CHANGE (space builder). It used to carry its own private copy of the star grid and its
// own band, and safari_eyepiece.gdshader carried a second, different copy. Two skies, and the
// spyglass read as a sticker over a different night. Both now call lane_sky.gdshaderinc, keyed on
// the world direction, so there is exactly ONE sky and the glass is a magnified window onto it.
//
// The user's words this round: the old lane was "more outer space which seems too serious in tone
// / empty". Everything added here is against that - a dusty nebula with a warm core off the port
// bow and a cold drift astern, so the sky has a FRONT and a BACK you can tell apart. The lane
// furniture (planets, lanterns, motes) is real geometry and lives in space_lane.gd; this is only
// the backdrop behind it.

uniform float band_gain : hint_range(0.0, 2.0) = 1.0;
uniform float star_gain : hint_range(0.0, 3.0) = 1.0;
// The glass draws its stars for its own pixels (56 deg over the ~1095 px porthole on the phone
// frame: 0.0511 deg/px). The pad camera is SafariRun's fov 70 over 1179 px, rendered at the
// low-power 3D scale 0.75: 0.0792 deg per rendered pixel. 0.0792 / 0.0511 = 1.55, so a star here
// is drawn 1.55x wider in angle to cover the same pixels - the inversion, not a look.
uniform float star_size = 1.55;

// WAVE 3 (G5, R11): the naked-eye sky on the pad now draws the same game-style space as the glass
// (lane_sky.gdshaderinc: the planet sky's navy, the rocket sky's flat cloud patches and star
// grammar), so the scope coming up at t=0 is a magnified window onto the same sky, not a cut to a
// different one. This is a sky shader, so what it writes goes through the tonemapper; the glass
// is a canvas item and does not. The pad beat is 6 s; the numbers are checked on the pad frame.
void sky() {
	vec3 d = normalize(EYEDIR);
	vec3 col = lane_space_base(d) + lane_space_clouds(d) * band_gain;
	col += lane_star_field(d, TIME, star_size) * star_gain;
	COLOR = col;
}
