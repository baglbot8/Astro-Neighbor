class_name UIDraw
extends RefCounted
## Anti-aliased procedural drawing helpers for _draw() based widgets (icons, glyphs, key caps).
## All shapes are filled polygons with a thin antialiased outline in the same color, which hides the
## jagged polygon edge and gives the soft, rounded look the style guide asks for.

## Points of a rounded rectangle outline (clockwise), radius clamped to half the shorter side.
static func rounded_rect_points(rect: Rect2, radius: float, segments: int = 6) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var centers := [
		rect.position + Vector2(rect.size.x - r, r),
		rect.position + Vector2(rect.size.x - r, rect.size.y - r),
		rect.position + Vector2(r, rect.size.y - r),
		rect.position + Vector2(r, r),
	]
	for ci in 4:
		var c: Vector2 = centers[ci]
		var start := -PI * 0.5 + ci * PI * 0.5
		for s in segments + 1:
			var a := start + (PI * 0.5) * float(s) / float(segments)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts

## Filled rounded rectangle with AA edge.
static func rrect(ci: CanvasItem, rect: Rect2, color: Color, radius: float, outline_width: float = 1.2) -> void:
	var pts := rounded_rect_points(rect, radius)
	ci.draw_colored_polygon(pts, color)
	if outline_width > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, color, outline_width, true)

## Filled circle with AA edge.
static func circle(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	ci.draw_circle(center, radius, color, true, -1.0, true)

## Filled ellipse (scaled circle) with AA edge.
static func ellipse(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color, segments: int = 32) -> void:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	poly(ci, pts, color)

## Filled polygon (convex or concave) with AA outline.
static func poly(ci: CanvasItem, pts: PackedVector2Array, color: Color, outline_width: float = 1.2) -> void:
	if pts.size() < 3:
		return
	ci.draw_colored_polygon(pts, color)
	if outline_width > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, color, outline_width, true)

## Points of a 5-point star.
static func star_points(center: Vector2, outer: float, inner_ratio: float = 0.48, points: int = 5, rotation: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in points * 2:
		var r := outer if i % 2 == 0 else outer * inner_ratio
		var a := -PI * 0.5 + rotation + PI * float(i) / float(points)
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts

## A chunky star: fill + darker outline + a little white highlight.
static func star(ci: CanvasItem, center: Vector2, outer: float, fill: Color, edge: Color, edge_width: float = 2.0, rotation: float = 0.0) -> void:
	var pts := star_points(center, outer, 0.5, 5, rotation)
	ci.draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, edge, edge_width, true)
	# highlight dot on the upper-left arm
	circle(ci, center + Vector2(-outer * 0.22, -outer * 0.30), outer * 0.11, Color(1, 1, 1, 0.85))

## Four-point sparkle (thin star).
static func sparkle(ci: CanvasItem, center: Vector2, outer: float, color: Color, rotation: float = 0.0) -> void:
	var pts := star_points(center, outer, 0.28, 4, rotation)
	poly(ci, pts, color, 1.0)

## Rounded "capsule" line between two points.
static func capsule(ci: CanvasItem, a: Vector2, b: Vector2, width: float, color: Color) -> void:
	ci.draw_line(a, b, color, width, true)
	circle(ci, a, width * 0.5, color)
	circle(ci, b, width * 0.5, color)
