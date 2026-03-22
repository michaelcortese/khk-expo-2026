extends Node2D
## Layer 1 — draws the static arena background.
## Green field, tinted team halves, oval dirt track, center divider.

const FIELD_L  := -120.0
const FIELD_R  :=  1080.0
const FIELD_T  :=  -80.0
const FIELD_B  :=   560.0
const CENTER_X :=   480.0

func _draw() -> void:
	# Green base
	draw_rect(Rect2(FIELD_L, FIELD_T, FIELD_R - FIELD_L, FIELD_B - FIELD_T),
		Color(0.18, 0.45, 0.15))

	# Grid lines
	var grid_col := Color(0.13, 0.35, 0.11, 0.55)
	var step     := 48.0
	var x: float  = ceil(FIELD_L / step) * step
	while x <= FIELD_R:
		draw_line(Vector2(x, FIELD_T), Vector2(x, FIELD_B), grid_col, 1.0)
		x += step
	var y: float  = ceil(FIELD_T / step) * step
	while y <= FIELD_B:
		draw_line(Vector2(FIELD_L, y), Vector2(FIELD_R, y), grid_col, 1.0)
		y += step

	# Team half-tints  (blue left, orange right)
	var h := FIELD_B - FIELD_T
	draw_rect(Rect2(FIELD_L,  FIELD_T, CENTER_X - FIELD_L, h), Color(0.10, 0.30, 0.90, 0.10))
	draw_rect(Rect2(CENTER_X, FIELD_T, FIELD_R - CENTER_X,  h), Color(0.90, 0.45, 0.10, 0.10))

	# Oval dirt track
	var cx       := (FIELD_L + FIELD_R) * 0.5
	var cy       := (FIELD_T + FIELD_B) * 0.5
	var rx_outer := (FIELD_R - FIELD_L) * 0.36
	var ry_outer := (FIELD_B - FIELD_T) * 0.40
	var track    := 36.0
	var steps    := 80
	var outer    := PackedVector2Array()
	var inner    := PackedVector2Array()
	for i in range(steps):
		var a := TAU * float(i) / float(steps)
		outer.append(Vector2(cx + cos(a) * rx_outer,           cy + sin(a) * ry_outer))
		inner.append(Vector2(cx + cos(a) * (rx_outer - track), cy + sin(a) * (ry_outer - track)))
	draw_colored_polygon(outer, Color(0.80, 0.70, 0.50, 0.78))
	draw_colored_polygon(inner, Color(0.18, 0.45, 0.15, 1.00))

	# Center divider
	draw_line(Vector2(CENTER_X, FIELD_T + 22.0), Vector2(CENTER_X, FIELD_B - 22.0),
		Color(1.0, 1.0, 1.0, 0.35), 2.0)
