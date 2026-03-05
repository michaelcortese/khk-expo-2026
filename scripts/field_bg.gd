extends Node2D
## Procedurally draws the game field:
##   green tiled grid, blue/orange half-tints, beige oval track, wooden border.
## z_index = -4095 so it renders just above the grass.jpg background sprite.

const FIELD_L  : float = -120.0
const FIELD_R  : float =  1080.0
const FIELD_T  : float =  -80.0
const FIELD_B  : float =   560.0
const CENTER_X : float =   480.0
const BORDER_W : float =    22.0

func _draw() -> void:
	_draw_base()
	_draw_grid()
	_draw_half_tints()
	_draw_oval_track()
	_draw_center_divider()
	_draw_wooden_border()

func _draw_base() -> void:
	draw_rect(
		Rect2(FIELD_L, FIELD_T, FIELD_R - FIELD_L, FIELD_B - FIELD_T),
		Color(0.18, 0.45, 0.15, 1.0)
	)

func _draw_grid() -> void:
	var col  : Color = Color(0.13, 0.35, 0.11, 0.55)
	var step : float = 48.0
	var x    : float = ceil(FIELD_L / step) * step
	while x <= FIELD_R:
		draw_line(Vector2(x, FIELD_T), Vector2(x, FIELD_B), col, 1.0)
		x += step
	var y : float = ceil(FIELD_T / step) * step
	while y <= FIELD_B:
		draw_line(Vector2(FIELD_L, y), Vector2(FIELD_R, y), col, 1.0)
		y += step

func _draw_half_tints() -> void:
	var h : float = FIELD_B - FIELD_T
	draw_rect(
		Rect2(FIELD_L, FIELD_T, CENTER_X - FIELD_L, h),
		Color(0.10, 0.30, 0.90, 0.10)
	)
	draw_rect(
		Rect2(CENTER_X, FIELD_T, FIELD_R - CENTER_X, h),
		Color(0.90, 0.45, 0.10, 0.10)
	)

func _draw_oval_track() -> void:
	var cx       : float = (FIELD_L + FIELD_R) * 0.5
	var cy       : float = (FIELD_T + FIELD_B) * 0.5
	var rx_outer : float = (FIELD_R - FIELD_L) * 0.36
	var ry_outer : float = (FIELD_B - FIELD_T) * 0.40
	var track    : float = 36.0
	var steps    : int   = 80

	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in range(steps):
		var a : float = TAU * float(i) / float(steps)
		outer.append(Vector2(cx + cos(a) * rx_outer,           cy + sin(a) * ry_outer))
		inner.append(Vector2(cx + cos(a) * (rx_outer - track), cy + sin(a) * (ry_outer - track)))

	draw_colored_polygon(outer, Color(0.80, 0.70, 0.50, 0.78))
	draw_colored_polygon(inner, Color(0.18, 0.45, 0.15, 1.00))

func _draw_center_divider() -> void:
	draw_line(
		Vector2(CENTER_X, FIELD_T + BORDER_W),
		Vector2(CENTER_X, FIELD_B - BORDER_W),
		Color(1.0, 1.0, 1.0, 0.35),
		2.0
	)

func _draw_wooden_border() -> void:
	var wood : Color = Color(0.50, 0.28, 0.09)
	var w    : float = FIELD_R - FIELD_L
	var h    : float = FIELD_B - FIELD_T
	var b    : float = BORDER_W
	draw_rect(Rect2(FIELD_L,     FIELD_T,     w, b), wood)
	draw_rect(Rect2(FIELD_L,     FIELD_B - b, w, b), wood)
	draw_rect(Rect2(FIELD_L,     FIELD_T,     b, h), wood)
	draw_rect(Rect2(FIELD_R - b, FIELD_T,     b, h), wood)
