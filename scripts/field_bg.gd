extends Node2D

const FIELD_L  := -120.0
const FIELD_R  :=  1080.0
const FIELD_T  :=  -80.0
const FIELD_B  :=   560.0
const CENTER_X :=   480.0

# River / bridge geometry (must match game_manager.gd and troop_unit.gd)
const RIVER_X  := 455.0
const RIVER_W  :=  50.0
const BRIDGE_TOP_Y0 :=  70.0
const BRIDGE_TOP_Y1 := 170.0
const BRIDGE_BOT_Y0 := 310.0
const BRIDGE_BOT_Y1 := 410.0

func _draw() -> void:
	_draw_grass()
	_draw_team_tints()
	_draw_track()
	_draw_river()
	_draw_bridges()
	_draw_river_banks()

func _draw_grass() -> void:
	# Base green
	draw_rect(Rect2(FIELD_L, FIELD_T, FIELD_R - FIELD_L, FIELD_B - FIELD_T),
		Color(0.18, 0.45, 0.15))
	# Alternating grass stripes for depth
	var stripe_w := 48.0
	var x: float = ceil(FIELD_L / stripe_w) * stripe_w
	var col_a := Color(0.17, 0.43, 0.14, 0.5)
	var col_b := Color(0.20, 0.48, 0.17, 0.5)
	var toggle := false
	while x < FIELD_R:
		if toggle:
			draw_rect(Rect2(x, FIELD_T, stripe_w, FIELD_B - FIELD_T), col_a)
		x += stripe_w
		toggle = not toggle
	# Subtle grid
	var grid_col := Color(0.12, 0.33, 0.10, 0.30)
	var y: float = ceil(FIELD_T / stripe_w) * stripe_w
	while y <= FIELD_B:
		draw_line(Vector2(FIELD_L, y), Vector2(FIELD_R, y), grid_col, 1.0)
		y += stripe_w

func _draw_team_tints() -> void:
	var h := FIELD_B - FIELD_T
	draw_rect(Rect2(FIELD_L,  FIELD_T, RIVER_X - FIELD_L, h),
		Color(0.10, 0.30, 0.90, 0.08))
	draw_rect(Rect2(RIVER_X + RIVER_W, FIELD_T, FIELD_R - RIVER_X - RIVER_W, h),
		Color(0.90, 0.20, 0.10, 0.08))

func _draw_track() -> void:
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
	draw_colored_polygon(outer, Color(0.76, 0.65, 0.44, 0.70))
	draw_colored_polygon(inner, Color(0.18, 0.45, 0.15, 1.00))

func _draw_river() -> void:
	var full_h := FIELD_B - FIELD_T
	# Deep water base
	draw_rect(Rect2(RIVER_X, FIELD_T, RIVER_W, full_h), Color(0.08, 0.22, 0.55))
	# Lighter water shimmer strips
	var shimmer_cols: Array = [
		Color(0.10, 0.28, 0.68, 0.6),
		Color(0.14, 0.35, 0.75, 0.4),
		Color(0.18, 0.42, 0.82, 0.25),
	]
	var offsets: Array = [4.0, 14.0, 24.0]
	var widths:  Array = [8.0, 10.0, 6.0]
	for i in range(shimmer_cols.size()):
		draw_rect(Rect2(RIVER_X + offsets[i], FIELD_T, widths[i], full_h),
			shimmer_cols[i])
	# Small wave lines
	var wave_col := Color(0.35, 0.60, 0.95, 0.30)
	var wy: float = FIELD_T + 20.0
	while wy < FIELD_B:
		# skip bridge regions (cleaner look)
		if not (wy > BRIDGE_TOP_Y0 - 5 and wy < BRIDGE_TOP_Y1 + 5) and \
		   not (wy > BRIDGE_BOT_Y0 - 5 and wy < BRIDGE_BOT_Y1 + 5):
			draw_line(Vector2(RIVER_X + 5, wy), Vector2(RIVER_X + RIVER_W - 5, wy),
				wave_col, 1.5)
		wy += 22.0

func _draw_bridges() -> void:
	_draw_one_bridge(BRIDGE_TOP_Y0, BRIDGE_TOP_Y1)
	_draw_one_bridge(BRIDGE_BOT_Y0, BRIDGE_BOT_Y1)

func _draw_one_bridge(y0: float, y1: float) -> void:
	var bh := y1 - y0
	# Bridge deck (wood planks)
	draw_rect(Rect2(RIVER_X - 6, y0, RIVER_W + 12, bh), Color(0.55, 0.38, 0.18))
	# Individual planks
	var plank_col  := Color(0.62, 0.44, 0.22)
	var gap_col    := Color(0.40, 0.26, 0.10)
	var plank_h    := 12.0
	var gap_h      :=  4.0
	var py         := y0 + 4.0
	while py + plank_h <= y1 - 4.0:
		draw_rect(Rect2(RIVER_X - 4, py, RIVER_W + 8, plank_h), plank_col)
		draw_rect(Rect2(RIVER_X - 4, py + plank_h, RIVER_W + 8, gap_h), gap_col)
		py += plank_h + gap_h
	# Side rails
	draw_rect(Rect2(RIVER_X - 8, y0, 4, bh), Color(0.35, 0.22, 0.08))
	draw_rect(Rect2(RIVER_X + RIVER_W + 4, y0, 4, bh), Color(0.35, 0.22, 0.08))

func _draw_river_banks() -> void:
	# Muddy bank edges on each side of the river
	var bank_w := 8.0
	var bank_col := Color(0.38, 0.28, 0.14, 0.85)
	draw_rect(Rect2(RIVER_X - bank_w, FIELD_T, bank_w, FIELD_B - FIELD_T), bank_col)
	draw_rect(Rect2(RIVER_X + RIVER_W, FIELD_T, bank_w, FIELD_B - FIELD_T), bank_col)
