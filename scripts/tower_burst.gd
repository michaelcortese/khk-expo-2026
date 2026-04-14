extends Node2D
# Tower destruction explosion.
# Call start(world_pos, is_king) immediately after add_child().

const GRAVITY    := 220.0   # px/s² downward pull on debris
const DURATION   := 1.20    # total lifetime (seconds)
const RING_TIME  := 0.35    # how long the shockwave ring expands

var _t:       float = 0.0
var _is_king: bool  = false

# Shockwave ring
var _ring_max_r: float = 0.0

# Flash disc
var _flash_r: float = 0.0

# Sparks  (many small squares, no gravity)
var _sparks: Array = []

# Debris  (larger rotating chunks, affected by gravity)
var _debris: Array = []

# Smoke   (expanding grey circles)
var _smoke: Array = []

func start(world_pos: Vector2, is_king: bool) -> void:
	position  = world_pos
	_is_king  = is_king
	_ring_max_r = 130.0 if is_king else 85.0
	_flash_r    =  55.0 if is_king else 36.0

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# ── Sparks ────────────────────────────────────────────────────────────────
	var spark_n  := 48 if is_king else 28
	var sp_min   := 70.0  if is_king else 50.0
	var sp_max   := 280.0 if is_king else 200.0
	for _i in range(spark_n):
		var angle := rng.randf() * TAU
		var speed := rng.randf_range(sp_min, sp_max)
		var pick  := rng.randf()
		var col: Color
		if pick < 0.35:   col = Color(1.0, 0.85, 0.10)  # gold
		elif pick < 0.65: col = Color(1.0, 0.45, 0.05)  # orange
		elif pick < 0.85: col = Color(1.0, 1.0,  0.85)  # white
		else:             col = Color(0.8, 0.15, 0.05)   # red
		_sparks.append({
			"pos":  Vector2.ZERO,
			"vel":  Vector2(cos(angle), sin(angle)) * speed,
			"sz":   rng.randf_range(2.5, 6.0 if is_king else 4.5),
			"col":  col,
		})

	# ── Debris ────────────────────────────────────────────────────────────────
	var deb_n  := 14 if is_king else 8
	var db_min := 55.0  if is_king else 40.0
	var db_max := 160.0 if is_king else 110.0
	for _i in range(deb_n):
		var angle := rng.randf() * TAU
		var speed := rng.randf_range(db_min, db_max)
		var pick  := rng.randf()
		var col: Color
		if pick < 0.5:    col = Color(0.45, 0.32, 0.18)  # stone/wood
		elif pick < 0.80: col = Color(0.60, 0.45, 0.22)  # light stone
		else:             col = Color(0.30, 0.20, 0.10)   # dark wood
		_debris.append({
			"pos":    Vector2.ZERO,
			"vel":    Vector2(cos(angle), sin(angle)) * speed,
			"sz":     rng.randf_range(6.0, 14.0 if is_king else 10.0),
			"rot":    rng.randf() * TAU,
			"rot_v":  rng.randf_range(-8.0, 8.0),   # radians/s
			"col":    col,
		})

	# ── Smoke puffs ───────────────────────────────────────────────────────────
	var smk_n := 7 if is_king else 4
	for _i in range(smk_n):
		var angle := rng.randf() * TAU
		var speed := rng.randf_range(15.0, 50.0)
		_smoke.append({
			"pos":   Vector2(cos(angle), sin(angle)) * rng.randf_range(4.0, 18.0),
			"vel":   Vector2(cos(angle), sin(angle)) * speed + Vector2(0, -30),
			"r":     rng.randf_range(8.0, 20.0),
			"r_max": rng.randf_range(28.0, 55.0 if is_king else 38.0),
			"grey":  rng.randf_range(0.35, 0.60),
		})

func _process(delta: float) -> void:
	_t += delta

	# Sparks — friction only
	for s in _sparks:
		s["pos"] += s["vel"] * delta
		s["vel"] *= 0.82

	# Debris — friction + gravity
	for d in _debris:
		d["pos"] += d["vel"] * delta
		d["vel"].y += GRAVITY * delta
		d["vel"]   *= 0.92
		d["rot"]   += d["rot_v"] * delta

	# Smoke — expand radius toward r_max
	for sm in _smoke:
		sm["pos"] += sm["vel"] * delta
		sm["vel"] *= 0.94
		sm["r"]    = move_toward(sm["r"], sm["r_max"], sm["r_max"] * delta * 2.5)

	queue_redraw()
	if _t >= DURATION:
		queue_free()

func _draw() -> void:
	var life := clampf(_t / DURATION, 0.0, 1.0)

	# ── Flash disc (first 0.12 s only) ───────────────────────────────────────
	if _t < 0.12:
		var fa := 1.0 - (_t / 0.12)
		draw_circle(Vector2.ZERO, _flash_r, Color(1.0, 0.85, 0.5, fa * 0.90))

	# ── Shockwave ring ────────────────────────────────────────────────────────
	if _t < RING_TIME:
		var rt      := _t / RING_TIME                              # 0..1
		var r       := _ring_max_r * rt
		var ring_a  := (1.0 - rt) * (1.0 - rt) * 0.75
		# Draw as a thick outline using two filled circles
		draw_circle(Vector2.ZERO, r,        Color(1.0, 0.65, 0.15, ring_a))
		draw_circle(Vector2.ZERO, r * 0.82, Color(0.05, 0.05, 0.05, 0.0))   # punch-out center

	# ── Smoke ─────────────────────────────────────────────────────────────────
	var smk_a := maxf(0.0, 1.0 - life * 1.4) * 0.45
	for sm in _smoke:
		var g: float = sm["grey"]
		draw_circle(sm["pos"], sm["r"], Color(g, g, g, smk_a))

	# ── Debris ────────────────────────────────────────────────────────────────
	var deb_a := maxf(0.0, 1.0 - life * 1.1)
	for d in _debris:
		var sz: float  = d["sz"]
		var rot: float = d["rot"]
		var col: Color = d["col"]
		var half       := sz * 0.5
		# Rotated square as a polygon
		var pts := PackedVector2Array([
			d["pos"] + Vector2(cos(rot        ) * half, sin(rot        ) * half),
			d["pos"] + Vector2(cos(rot + PI*0.5) * half, sin(rot + PI*0.5) * half),
			d["pos"] + Vector2(cos(rot + PI    ) * half, sin(rot + PI    ) * half),
			d["pos"] + Vector2(cos(rot + PI*1.5) * half, sin(rot + PI*1.5) * half),
		])
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, deb_a))

	# ── Sparks ────────────────────────────────────────────────────────────────
	var sp_a := maxf(0.0, 1.0 - life * 1.3)
	sp_a = sp_a * sp_a
	for s in _sparks:
		var sz: float  = s["sz"]
		var col: Color = s["col"]
		draw_rect(
			Rect2(s["pos"] - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)),
			Color(col.r, col.g, col.b, sp_a)
		)
