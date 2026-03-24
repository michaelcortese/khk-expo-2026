# Particle burst that plays when a tower is destroyed.
# Call start(world_pos, is_king) immediately after add_child().
extends Node2D

var _particles: Array = []
var _lifetime:  float = 0.0
const DURATION: float = 0.75

func start(world_pos: Vector2, is_king: bool) -> void:
	position = world_pos
	var count  := 36 if is_king else 22
	var sp_min := 60.0  if is_king else 40.0
	var sp_max := 260.0 if is_king else 180.0
	var sz_min := 4.0   if is_king else 3.0
	var sz_max := 12.0  if is_king else 8.0

	for i in range(count):
		var angle := randf() * TAU
		var speed := randf_range(sp_min, sp_max)
		# Mix of gold, orange, and white sparks
		var pick   := randf()
		var col: Color
		if pick < 0.4:
			col = Color(1.0, 0.85, 0.1)   # gold
		elif pick < 0.7:
			col = Color(1.0, 0.45, 0.05)  # orange
		else:
			col = Color(1.0, 1.0, 0.9)    # white flash
		_particles.append({
			"pos":  Vector2.ZERO,
			"vel":  Vector2(cos(angle), sin(angle)) * speed,
			"size": randf_range(sz_min, sz_max),
			"col":  col,
		})

func _process(delta: float) -> void:
	_lifetime += delta
	for p in _particles:
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.85   # friction
	queue_redraw()
	if _lifetime >= DURATION:
		queue_free()

func _draw() -> void:
	var alpha: float = 1.0 - (_lifetime / DURATION)
	alpha = alpha * alpha   # ease out
	for p in _particles:
		var c := Color(p["col"].r, p["col"].g, p["col"].b, alpha)
		var s: float = p["size"]
		draw_rect(Rect2(p["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), c)
