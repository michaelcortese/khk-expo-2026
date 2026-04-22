extends Node2D
# Animated procedural character sprite.
# Call setup(card_id, owner_player) before add_child().
# Drive animation by calling set_anim_state("idle" | "walk" | "attack").

var _card_id:    String = "knight"
var _team_col:   Color  = Color.WHITE
var _anim_state: String = "idle"
var _anim_t:     float  = 0.0

const WALK_FREQ := 6.0   # stride cycles per second
const ATK_FREQ  := 2.5   # attack swings per second

# Knight sprite sheet variables
var _knight_sprite: Sprite2D          = null
var _knight_textures: Dictionary      = {}
var _knight_dir: String               = "right"
var _knight_frame: int                = 1
var _knight_frame_timer: float        = 0.0
const KNIGHT_FRAME_INTERVAL: float    = 0.18   # seconds per walk frame

# Archer sprite sheet variables
var _archer_sprite: Sprite2D          = null
var _archer_textures: Dictionary      = {}
var _archer_dir: String               = "right"
var _archer_frame: int                = 1
var _archer_frame_timer: float        = 0.0
const ARCHER_FRAME_INTERVAL: float    = 0.16

# Mini Pekka sprite sheet variables
var _mpekka_sprite: Sprite2D          = null
var _mpekka_textures: Dictionary      = {}
var _mpekka_dir: String               = "right"
var _mpekka_frame: int                = 1
var _mpekka_frame_timer: float        = 0.0
const MPEKKA_FRAME_INTERVAL: float    = 0.16

# Goblin Gang sprite sheet variables
var _goblin_sprite: Sprite2D          = null
var _goblin_textures: Dictionary      = {}
var _goblin_dir: String               = "right"
var _goblin_frame: int                = 1
var _goblin_frame_timer: float        = 0.0
const GOBLIN_FRAME_INTERVAL: float    = 0.14

# Barbarian sprite sheet variables
var _barbarian_sprite: Sprite2D       = null
var _barbarian_textures: Dictionary   = {}
var _barbarian_dir: String            = "right"
var _barbarian_frame: int             = 1
var _barbarian_frame_timer: float     = 0.0
const BARBARIAN_FRAME_INTERVAL: float = 0.13

# Giant sprite sheet variables
var _giant_sprite: Sprite2D           = null
var _giant_textures: Dictionary       = {}
var _giant_dir: String                = "right"
var _giant_frame: int                 = 1
var _giant_frame_timer: float         = 0.0
const GIANT_FRAME_INTERVAL: float     = 0.22

# Hog Rider sprite sheet variables
var _hogrider_sprite: Sprite2D        = null
var _hogrider_textures: Dictionary    = {}
var _hogrider_dir: String             = "right"
var _hogrider_frame: int              = 1
var _hogrider_frame_timer: float      = 0.0
const HOGRIDER_FRAME_INTERVAL: float  = 0.14

# Wizard sprite sheet variables
var _wizard_sprite: Sprite2D          = null
var _wizard_textures: Dictionary      = {}
var _wizard_dir: String               = "right"
var _wizard_frame: int                = 1
var _wizard_frame_timer: float        = 0.0
const WIZARD_FRAME_INTERVAL: float    = 0.18

# ── Palette ───────────────────────────────────────────────────────────────────
const SKIN    := Color(0.97, 0.82, 0.65)
const SKIN_D  := Color(0.80, 0.62, 0.45)
const BLACK   := Color(0.10, 0.08, 0.08)
const WHITE   := Color(0.95, 0.95, 0.95)
const GOLD    := Color(0.95, 0.78, 0.10)
const STEEL   := Color(0.70, 0.72, 0.80)
const STEEL_D := Color(0.45, 0.46, 0.52)
const WOOD    := Color(0.55, 0.38, 0.18)
const WOOD_D  := Color(0.38, 0.24, 0.10)
const GREEN   := Color(0.22, 0.52, 0.18)
const GREEN_D := Color(0.14, 0.34, 0.10)
const LIME    := Color(0.30, 0.78, 0.22)
const PURPLE  := Color(0.42, 0.10, 0.65)
const ORANGE  := Color(0.92, 0.50, 0.05)

# ── Public API ────────────────────────────────────────────────────────────────

func setup(card_id: String, player_idx: int) -> void:
	_card_id  = card_id
	_team_col = Color(0.20, 0.50, 1.00) if player_idx == 0 else Color(1.00, 0.18, 0.18)
	if _card_id == "knight":
		_setup_knight_sprites()
	elif _card_id == "archer":
		_setup_archer_sprites()
	elif _card_id == "mini_pekka":
		_setup_mpekka_sprites()
	elif _card_id == "goblin_gang" or _card_id == "spear_goblin":
		_setup_goblin_sprites()
	elif _card_id == "hog_rider":
		_setup_hogrider_sprites()
	elif _card_id == "wizard":
		_setup_wizard_sprites()
	elif _card_id == "barbarian":
		_setup_barbarian_sprites()
	elif _card_id == "giant":
		_setup_giant_sprites()

func set_direction(dir: String) -> void:
	match _card_id:
		"knight":
			if _knight_dir == dir:
				return
			_knight_dir = dir
			_update_knight_texture()
		"archer":
			if _archer_dir == dir:
				return
			_archer_dir = dir
			_update_archer_texture()
		"mini_pekka":
			if _mpekka_dir == dir:
				return
			_mpekka_dir = dir
			_update_mpekka_texture()
		"goblin_gang", "spear_goblin":
			if _goblin_dir == dir:
				return
			_goblin_dir = dir
			_update_goblin_texture()
		"hog_rider":
			if _hogrider_dir == dir:
				return
			_hogrider_dir = dir
			_update_hogrider_texture()
		"wizard":
			if _wizard_dir == dir:
				return
			_wizard_dir = dir
			_update_wizard_texture()
		"barbarian":
			if _barbarian_dir == dir:
				return
			_barbarian_dir = dir
			_update_barbarian_texture()
		"giant":
			if _giant_dir == dir:
				return
			_giant_dir = dir
			_update_giant_texture()

func set_anim_state(state: String) -> void:
	if _anim_state == state:
		return
	_anim_state = state
	if state == "idle":
		_anim_t = 0.0
		match _card_id:
			"knight":
				_knight_frame       = 1
				_knight_frame_timer = 0.0
				_update_knight_texture()
			"archer":
				_archer_frame       = 1
				_archer_frame_timer = 0.0
				_update_archer_texture()
			"mini_pekka":
				_mpekka_frame       = 1
				_mpekka_frame_timer = 0.0
				_update_mpekka_texture()
			"goblin_gang", "spear_goblin":
				_goblin_frame       = 1
				_goblin_frame_timer = 0.0
				_update_goblin_texture()
			"hog_rider":
				_hogrider_frame       = 1
				_hogrider_frame_timer = 0.0
				_update_hogrider_texture()
			"wizard":
				_wizard_frame       = 1
				_wizard_frame_timer = 0.0
				_update_wizard_texture()
			"barbarian":
				_barbarian_frame       = 1
				_barbarian_frame_timer = 0.0
				_update_barbarian_texture()
			"giant":
				_giant_frame       = 1
				_giant_frame_timer = 0.0
				_update_giant_texture()
			_:
				queue_redraw()   # one final draw to show rest pose

func _setup_knight_sprites() -> void:
	for dir in ["up", "down", "left", "right"]:
		for frame in [1, 2]:
			var key: String = dir + "_" + str(frame)
			_knight_textures[key] = load("res://assets/knight_assets/knight_" + key + ".png")
	_knight_sprite                = Sprite2D.new()
	_knight_sprite.texture        = _knight_textures["right_1"]
	_knight_sprite.scale          = Vector2(2.0, 2.0)
	_knight_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_knight_sprite)

func _setup_archer_sprites() -> void:
	for dir in ["up", "down", "left", "right"]:
		for frame in [1, 2]:
			var key: String = dir + "_" + str(frame)
			_archer_textures[key] = load("res://assets/archer_assets/archer_" + key + ".png")
	_archer_sprite                = Sprite2D.new()
	_archer_sprite.texture        = _archer_textures["right_1"]
	_archer_sprite.scale          = Vector2(2.0, 2.0)
	_archer_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_archer_sprite)

func _update_archer_texture() -> void:
	if _archer_sprite == null:
		return
	var key: String = _archer_dir + "_" + str(_archer_frame)
	if _archer_textures.has(key):
		_archer_sprite.texture = _archer_textures[key]

func _setup_mpekka_sprites() -> void:
	for dir in ["up", "down", "left", "right"]:
		for frame in [1, 2]:
			var key: String = dir + "_" + str(frame)
			_mpekka_textures[key] = load("res://assets/mini_pekka_assets/mini_pekka_" + key + ".png")
	_mpekka_sprite                = Sprite2D.new()
	_mpekka_sprite.texture        = _mpekka_textures["right_1"]
	_mpekka_sprite.scale          = Vector2(2.0, 2.0)
	_mpekka_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_mpekka_sprite)

func _update_mpekka_texture() -> void:
	if _mpekka_sprite == null:
		return
	var key: String = _mpekka_dir + "_" + str(_mpekka_frame)
	if _mpekka_textures.has(key):
		_mpekka_sprite.texture = _mpekka_textures[key]

func _setup_goblin_sprites() -> void:
	for dir in ["up", "down", "left", "right"]:
		for frame in [1, 2]:
			var key: String = dir + "_" + str(frame)
			_goblin_textures[key] = load("res://assets/goblin_gang_assets/goblin_gang_" + key + ".png")
	_goblin_sprite                = Sprite2D.new()
	_goblin_sprite.texture        = _goblin_textures["right_1"]
	_goblin_sprite.scale          = Vector2(2.0, 2.0)
	_goblin_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_goblin_sprite)

func _update_goblin_texture() -> void:
	if _goblin_sprite == null:
		return
	var key: String = _goblin_dir + "_" + str(_goblin_frame)
	if _goblin_textures.has(key):
		_goblin_sprite.texture = _goblin_textures[key]

func _setup_barbarian_sprites() -> void:
	for dir in ["up", "down", "left", "right"]:
		for frame in [1, 2]:
			var key: String = dir + "_" + str(frame)
			_barbarian_textures[key] = load("res://assets/barbarian_assets/barbarian_" + dir + "_frame" + str(frame) + ".png")
	_barbarian_sprite                = Sprite2D.new()
	_barbarian_sprite.texture        = _barbarian_textures["right_1"]
	_barbarian_sprite.scale          = Vector2(2.0, 2.0)
	_barbarian_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_barbarian_sprite)

func _update_barbarian_texture() -> void:
	if _barbarian_sprite == null:
		return
	var key: String = _barbarian_dir + "_" + str(_barbarian_frame)
	if _barbarian_textures.has(key):
		_barbarian_sprite.texture = _barbarian_textures[key]

func _setup_giant_sprites() -> void:
	for dir in ["up", "down", "left", "right"]:
		for frame in [1, 2]:
			var key: String = dir + "_" + str(frame)
			_giant_textures[key] = load("res://assets/gaint_assets/gaint_" + dir + "_frame" + str(frame) + ".png")
	_giant_sprite                = Sprite2D.new()
	_giant_sprite.texture        = _giant_textures["right_1"]
	_giant_sprite.scale          = Vector2(2.0, 2.0)
	_giant_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_giant_sprite)

func _update_giant_texture() -> void:
	if _giant_sprite == null:
		return
	var key: String = _giant_dir + "_" + str(_giant_frame)
	if _giant_textures.has(key):
		_giant_sprite.texture = _giant_textures[key]

func _setup_hogrider_sprites() -> void:
	for dir in ["up", "down", "left", "right"]:
		for frame in [1, 2]:
			var key: String = dir + "_" + str(frame)
			_hogrider_textures[key] = load("res://assets/hogrider_assets/hogrider_" + dir + "_frame" + str(frame) + ".png")
	_hogrider_sprite                = Sprite2D.new()
	_hogrider_sprite.texture        = _hogrider_textures["right_1"]
	_hogrider_sprite.scale          = Vector2(2.0, 2.0)
	_hogrider_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_hogrider_sprite)

func _update_hogrider_texture() -> void:
	if _hogrider_sprite == null:
		return
	var key: String = _hogrider_dir + "_" + str(_hogrider_frame)
	if _hogrider_textures.has(key):
		_hogrider_sprite.texture = _hogrider_textures[key]

func _setup_wizard_sprites() -> void:
	for dir in ["up", "down", "left", "right"]:
		for frame in [1, 2]:
			var key: String = dir + "_" + str(frame)
			_wizard_textures[key] = load("res://assets/wizard_assets/wizard_" + dir + "_frame" + str(frame) + ".png")
	_wizard_sprite                = Sprite2D.new()
	_wizard_sprite.texture        = _wizard_textures["right_1"]
	_wizard_sprite.scale          = Vector2(2.0, 2.0)
	_wizard_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_wizard_sprite)

func _update_wizard_texture() -> void:
	if _wizard_sprite == null:
		return
	var key: String = _wizard_dir + "_" + str(_wizard_frame)
	if _wizard_textures.has(key):
		_wizard_sprite.texture = _wizard_textures[key]

func _update_knight_texture() -> void:
	if _knight_sprite == null:
		return
	var key: String = _knight_dir + "_" + str(_knight_frame)
	if _knight_textures.has(key):
		_knight_sprite.texture = _knight_textures[key]

func _process(delta: float) -> void:
	if _anim_state == "idle":
		return
	_anim_t += delta
	match _card_id:
		"knight":
			if _anim_state == "walk":
				_knight_frame_timer += delta
				if _knight_frame_timer >= KNIGHT_FRAME_INTERVAL:
					_knight_frame_timer -= KNIGHT_FRAME_INTERVAL
					_knight_frame = 2 if _knight_frame == 1 else 1
					_update_knight_texture()
			return   # uses Sprite2D child — no queue_redraw needed
		"archer":
			if _anim_state == "walk":
				_archer_frame_timer += delta
				if _archer_frame_timer >= ARCHER_FRAME_INTERVAL:
					_archer_frame_timer -= ARCHER_FRAME_INTERVAL
					_archer_frame = 2 if _archer_frame == 1 else 1
					_update_archer_texture()
			return
		"mini_pekka":
			if _anim_state == "walk":
				_mpekka_frame_timer += delta
				if _mpekka_frame_timer >= MPEKKA_FRAME_INTERVAL:
					_mpekka_frame_timer -= MPEKKA_FRAME_INTERVAL
					_mpekka_frame = 2 if _mpekka_frame == 1 else 1
					_update_mpekka_texture()
			return
		"goblin_gang", "spear_goblin":
			if _anim_state == "walk":
				_goblin_frame_timer += delta
				if _goblin_frame_timer >= GOBLIN_FRAME_INTERVAL:
					_goblin_frame_timer -= GOBLIN_FRAME_INTERVAL
					_goblin_frame = 2 if _goblin_frame == 1 else 1
					_update_goblin_texture()
			return
		"barbarian":
			if _anim_state == "walk":
				_barbarian_frame_timer += delta
				if _barbarian_frame_timer >= BARBARIAN_FRAME_INTERVAL:
					_barbarian_frame_timer -= BARBARIAN_FRAME_INTERVAL
					_barbarian_frame = 2 if _barbarian_frame == 1 else 1
					_update_barbarian_texture()
			return
		"giant":
			if _anim_state == "walk":
				_giant_frame_timer += delta
				if _giant_frame_timer >= GIANT_FRAME_INTERVAL:
					_giant_frame_timer -= GIANT_FRAME_INTERVAL
					_giant_frame = 2 if _giant_frame == 1 else 1
					_update_giant_texture()
			return
		"hog_rider":
			if _anim_state == "walk":
				_hogrider_frame_timer += delta
				if _hogrider_frame_timer >= HOGRIDER_FRAME_INTERVAL:
					_hogrider_frame_timer -= HOGRIDER_FRAME_INTERVAL
					_hogrider_frame = 2 if _hogrider_frame == 1 else 1
					_update_hogrider_texture()
			return
		"wizard":
			if _anim_state == "walk":
				_wizard_frame_timer += delta
				if _wizard_frame_timer >= WIZARD_FRAME_INTERVAL:
					_wizard_frame_timer -= WIZARD_FRAME_INTERVAL
					_wizard_frame = 2 if _wizard_frame == 1 else 1
					_update_wizard_texture()
			return
	queue_redraw()

# ── Draw helpers ──────────────────────────────────────────────────────────────

func _r(x: float, y: float, w: float, h: float, col: Color) -> void:
	draw_rect(Rect2(x, y, w, h), col)

func _c(cx: float, cy: float, r: float, col: Color) -> void:
	draw_circle(Vector2(cx, cy), r, col)

func _rst() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ── Animation helpers ─────────────────────────────────────────────────────────

# Walk leg angle: side = +1 right leg, -1 left leg
func _leg(wp: float, side: float, amp: float) -> float:
	return sin(wp + (0.0 if side > 0 else PI)) * amp

# Walk arm angle: arms swing opposite to same-side leg
func _arm(wp: float, side: float, amp: float) -> float:
	return sin(wp + (PI if side > 0 else 0.0)) * amp

# Attack weapon angle (backswing then strike then recovery)
func _atk(ap: float, back: float, fwd: float) -> float:
	if ap < 0.35:
		return lerp(0.0, -back, ap / 0.35)
	elif ap < 0.55:
		return lerp(-back, fwd, (ap - 0.35) / 0.20)
	else:
		return lerp(fwd, 0.0, (ap - 0.55) / 0.45)

# Body lean during attack (tilts forward on strike)
func _lean(ap: float) -> float:
	if ap < 0.35: return lerp(0.0, 0.15, ap / 0.35)
	elif ap < 0.55: return lerp(0.15, 0.28, (ap - 0.35) / 0.20)
	else: return lerp(0.28, 0.0, (ap - 0.55) / 0.45)

# ── Dispatch ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	if _card_id in ["knight", "archer", "mini_pekka", "goblin_gang", "spear_goblin", "hog_rider", "wizard", "barbarian", "giant"]:
		return   # rendered by Sprite2D child node
	var wp := 0.0   # walk phase 0..TAU
	var ap := 0.0   # attack phase 0..1

	if _anim_state == "walk":
		wp = fmod(_anim_t * WALK_FREQ, TAU)
	elif _anim_state == "attack":
		ap = fmod(_anim_t * ATK_FREQ, 1.0)

	match _card_id:
		"knight":       _draw_knight(wp, ap)
		"archer":       _draw_archer(wp, ap)
		"giant":        _draw_giant(wp, ap)
		"barbarian":    _draw_barbarian(wp, ap)
		"wizard":       _draw_wizard(wp, ap)
		"goblin":       _draw_goblin(wp, ap)
		"spear_goblin": _draw_goblin(wp, ap)
		"hog_rider":    _draw_barbarian(wp, ap)
		"mini_pekka":   _draw_knight(wp, ap)
		_:              _draw_knight(wp, ap)


# ──────────────────────────────────────────────────────────────────────────────
# KNIGHT  — plate armor, sword (right), team-colored shield (left)
# ──────────────────────────────────────────────────────────────────────────────
func _draw_knight(wp: float, ap: float) -> void:
	var ll := _leg(wp, -1, 0.38)   # left leg angle
	var rl := _leg(wp,  1, 0.38)   # right leg angle
	var la := _arm(wp, -1, 0.25)   # left (shield) arm angle
	var ra := _arm(wp,  1, 0.25)   # right (sword) arm angle
	if ap > 0.0:
		ra = _atk(ap, 0.80, 0.60)
		la = -ra * 0.2              # shield pulls back slightly on strike

	var lean := _lean(ap)

	# ── Right leg (drawn first / behind) ──────────────────────────────────────
	draw_set_transform(Vector2(3, 2), rl, Vector2.ONE)
	_r(-2.5, 0, 5, 7, STEEL)       # plate
	_r(-3,   6, 6, 4, STEEL_D)     # boot
	_rst()

	# ── Left leg ──────────────────────────────────────────────────────────────
	draw_set_transform(Vector2(-3, 2), ll, Vector2.ONE)
	_r(-2.5, 0, 5, 7, STEEL)
	_r(-3,   6, 6, 4, STEEL_D)
	_rst()

	# ── Body (with lean transform) ─────────────────────────────────────────────
	draw_set_transform(Vector2(0, 0), lean, Vector2.ONE)

	# Waist band
	_r(-7, 1, 14, 3, GOLD)

	# Torso
	_r(-8, -6, 16, 8, STEEL)
	_r(-6, -4, 12, 2, GOLD)        # pectoral stripe
	_r(-1, -6,  2, 8, STEEL_D)     # center seam

	# Shoulder pads (static)
	_r(-12, -8, 4, 4, STEEL)
	_r(  8, -8, 4, 4, STEEL)

	# ── Shield arm (left) ─────────────────────────────────────────────────────
	draw_set_transform(Vector2(-8, -5), la, Vector2.ONE)
	_r(-2, 0, 4, 8, STEEL)         # arm plate
	_r(-8,-4, 7,14, _team_col)     # shield face
	_r(-8,-4, 7, 2, GOLD)          # shield rim
	_c(-5, 3, 2, Color(1,1,1,0.22))  # shield boss
	_rst()

	# ── Sword arm (right) ─────────────────────────────────────────────────────
	draw_set_transform(Vector2(8, -5), ra, Vector2.ONE)
	_r(-2, 0, 4, 8, STEEL)         # arm plate
	_r( 3,-10, 3,22, Color(0.82,0.84,0.90))  # blade
	_r( 1, -1, 7, 2, GOLD)         # crossguard
	_r( 3,  8, 3, 3, WOOD_D)       # grip
	_rst()

	# ── Helmet ────────────────────────────────────────────────────────────────
	_c(0, -12, 8, STEEL)
	_r(-5,-14, 10, 4, STEEL)       # ridge
	_r(-4,-12,  8, 3, BLACK)       # visor
	_r(-8,-10,  2, 4, STEEL_D)     # left cheek
	_r( 6,-10,  2, 4, STEEL_D)     # right cheek
	_r(-2,-15,  4, 2, GOLD)        # crest

	_rst()   # end body lean


# ──────────────────────────────────────────────────────────────────────────────
# ARCHER  — hooded ranger, bow (left), quiver (right back)
# ──────────────────────────────────────────────────────────────────────────────
func _draw_archer(wp: float, ap: float) -> void:
	var ll := _leg(wp, -1, 0.35)
	var rl := _leg(wp,  1, 0.35)
	var draw_arm  := 0.0    # bow draw arm (right)
	var bow_arm   := 0.0    # bow hold arm (left)

	if ap > 0.0:
		# Draw bow: right arm pulls back, left arm stays forward
		draw_arm = _atk(ap, 0.55, -0.10)   # right arm (draw hand)
		bow_arm  = _atk(ap,  0.10,  0.20)  # bow arm angles slightly
	else:
		draw_arm = _arm(wp, 1, 0.22)
		bow_arm  = _arm(wp,-1, 0.22)

	var lean := _lean(ap) * 0.5   # archers lean less than melee

	# ── Right leg ─────────────────────────────────────────────────────────────
	draw_set_transform(Vector2(3, 2), rl, Vector2.ONE)
	_r(-2, 0, 4, 7, GREEN_D)
	_r(-2, 6, 5, 4, WOOD_D)       # boot
	_rst()

	# ── Left leg ──────────────────────────────────────────────────────────────
	draw_set_transform(Vector2(-3, 2), ll, Vector2.ONE)
	_r(-2, 0, 4, 7, GREEN_D)
	_r(-3, 6, 5, 4, WOOD_D)
	_rst()

	# ── Body (with lean) ──────────────────────────────────────────────────────
	draw_set_transform(Vector2(0, 0), lean, Vector2.ONE)

	# Belt / tunic
	_r(-6, -5, 12, 8, GREEN)
	_r(-6,  2, 12, 3, _team_col)  # sash/belt
	_r(-4, -7,  8, 3, WOOD)       # collar

	# Quiver (right back, static)
	_r(7, -10, 4, 11, WOOD)
	_r(8,  -9, 2,  2, STEEL)      # arrow ends

	# ── Bow arm (left, holds bow) ──────────────────────────────────────────────
	draw_set_transform(Vector2(-8, -5), bow_arm, Vector2.ONE)
	_r(-2,  0, 4, 8, GREEN)       # arm
	# Bow
	draw_line(Vector2(-5,-12), Vector2(-9,  0), WOOD, 2.5)
	draw_line(Vector2(-9,  0), Vector2(-5, 12), WOOD, 2.5)
	_rst()

	# ── Draw arm (right, pulls string) ────────────────────────────────────────
	draw_set_transform(Vector2(8, -5), draw_arm, Vector2.ONE)
	_r(-2,  0, 4, 8, GREEN)       # arm
	_c(-2,  8, 2.5, SKIN)         # hand gripping string
	if ap > 0.0:
		# Arrow nocked on bowstring — pulls back with arm
		_r(-6, -1, 12, 1, Color(0.85, 0.78, 0.40))  # arrow shaft
	_rst()

	# Bowstring (drawn from bow arm to draw arm — approximate with line)
	var bow_tip_t := Vector2(-14, -12) # approximate bow tip positions
	var bow_tip_b := Vector2(-14,  12)
	if ap == 0.0:
		draw_line(bow_tip_t, bow_tip_b, Color(GOLD.r,GOLD.g,GOLD.b,0.7), 1.0)

	# ── Hood + face ───────────────────────────────────────────────────────────
	_c(0, -11, 7, GREEN)
	_r(-7,-11, 14, 5, GREEN)
	_r(-3, -9,  6, 5, BLACK)      # shadow inside hood
	_c(0,  -8,  2, SKIN)

	_rst()   # end body lean


# ──────────────────────────────────────────────────────────────────────────────
# GIANT  — massive bruiser, stone club (right), slow heavy walk
# ──────────────────────────────────────────────────────────────────────────────
func _draw_giant(wp: float, ap: float) -> void:
	var BSKIN := Color(0.70, 0.82, 0.88)
	var BSKND := Color(0.50, 0.62, 0.70)
	var STONE := Color(0.48, 0.42, 0.35)

	var ll := _leg(wp, -1, 0.28)   # giants take slower steps
	var rl := _leg(wp,  1, 0.28)
	var club_ang := 0.0
	var l_arm_ang := _arm(wp, -1, 0.20)

	if ap > 0.0:
		club_ang  = _atk(ap, 1.0, 0.5)   # big overhead arc
		l_arm_ang = _atk(ap, 0.2, -0.1) * -1.0
	else:
		club_ang = _arm(wp, 1, 0.18)

	var lean := _lean(ap) * 0.6

	# ── Right leg ─────────────────────────────────────────────────────────────
	draw_set_transform(Vector2(5, 4), rl, Vector2.ONE)
	_r(-4,  0, 8, 9, WOOD)
	_r(-5,  8, 9, 5, BSKND)       # foot
	_rst()

	# ── Left leg ──────────────────────────────────────────────────────────────
	draw_set_transform(Vector2(-5, 4), ll, Vector2.ONE)
	_r(-4,  0, 8, 9, WOOD)
	_r(-5,  8, 9, 5, BSKND)
	_rst()

	# ── Body (with lean) ──────────────────────────────────────────────────────
	draw_set_transform(Vector2(0, 0), lean, Vector2.ONE)

	# Belt
	_r(-10, 2, 20, 2, GOLD)
	_r( -3, 1,  6, 4, _team_col)  # buckle

	# Overalls / pants
	_r(-10, 2, 20,12, WOOD)

	# Suspenders
	_r( -4,-9,  3,12, GOLD)
	_r(  1,-9,  3,12, GOLD)

	# Torso (big round belly)
	_c(0, -4, 12, BSKIN)
	_r(-12,-10,24, 8, BSKIN)

	# ── Left arm ──────────────────────────────────────────────────────────────
	draw_set_transform(Vector2(-12, -8), l_arm_ang, Vector2.ONE)
	_r(-4,  0, 8,10, BSKIN)
	_c(-1, 10, 5, BSKIN)           # fist
	_rst()

	# ── Club arm (right) ──────────────────────────────────────────────────────
	draw_set_transform(Vector2(12, -8), club_ang, Vector2.ONE)
	_r(-3,  0, 6,10, BSKIN)        # arm
	_c( 0, 11, 5, BSKIN)           # fist
	_r(-2, 12, 4,14, WOOD_D)       # club handle
	_r(-6,  7,12,10, STONE)        # club head
	_r(-6,  7,12, 2, Color(0.65,0.60,0.50))  # highlight
	_rst()

	# ── Head ──────────────────────────────────────────────────────────────────
	_c(0,-16,11, BSKIN)
	_r(-11,-17,22, 4, BSKIN)
	_c(-4,-17, 2, BLACK)
	_c( 4,-17, 2, BLACK)
	_c(-4,-17, 1, WHITE)
	_c( 4,-17, 1, WHITE)
	_c( 0,-14,1.5,BSKND)
	draw_line(Vector2(-4,-11), Vector2(-2,-10), BLACK, 1.5)
	draw_line(Vector2(-2,-10), Vector2( 2,-10), BLACK, 1.5)
	draw_line(Vector2( 2,-10), Vector2( 4,-11), BLACK, 1.5)
	# Rock helmet
	_r(-8,-25,16, 5, STONE)
	_r(-11,-22, 4, 3, STONE)
	_r( 7,-22,  4, 3, STONE)

	_rst()   # end body lean


# ──────────────────────────────────────────────────────────────────────────────
# BARBARIAN  — bare chest, dual axes, horned helmet, fast and aggressive
# ──────────────────────────────────────────────────────────────────────────────
func _draw_barbarian(wp: float, ap: float) -> void:
	var FUR  := Color(0.55, 0.40, 0.22)
	var FURD := Color(0.38, 0.27, 0.12)
	var HELM := Color(0.60, 0.58, 0.60)

	# Barbarians run faster so increase walk frequency visually
	var fast_wp := wp * 1.25
	var ll := _leg(fast_wp, -1, 0.40)
	var rl := _leg(fast_wp,  1, 0.40)

	var r_axe_ang := 0.0
	var l_axe_ang := 0.0

	if ap > 0.0:
		# Dual axes: one comes up as other comes down (staggered)
		r_axe_ang = _atk(ap, 0.9, 0.6)
		l_axe_ang = _atk(fmod(ap + 0.5, 1.0), 0.7, 0.5)  # half-phase offset
	else:
		r_axe_ang = _arm(fast_wp,  1, 0.30)
		l_axe_ang = _arm(fast_wp, -1, 0.30)

	var lean := _lean(ap) * 0.7

	# ── Right leg ─────────────────────────────────────────────────────────────
	draw_set_transform(Vector2(3, 2), rl, Vector2.ONE)
	_r(-2.5,0, 5, 7, FURD)
	_r(-3,  6, 6, 4, FUR)          # fur cuff
	_r(-3,  6, 6, 2, FURD)
	_rst()

	# ── Left leg ──────────────────────────────────────────────────────────────
	draw_set_transform(Vector2(-3, 2), ll, Vector2.ONE)
	_r(-2.5,0, 5, 7, FURD)
	_r(-3,  6, 6, 4, FUR)
	_r(-3,  6, 6, 2, FURD)
	_rst()

	# ── Body (with lean) ──────────────────────────────────────────────────────
	draw_set_transform(Vector2(0, 0), lean, Vector2.ONE)

	# Loincloth
	_r(-6,  2,12, 6, FUR)
	_r(-6,  2,12, 2, _team_col)

	# Bare chest
	_r(-7, -7,14,10, SKIN)
	draw_line(Vector2(0,-7), Vector2(0, 2), SKIN_D, 1.0)
	_r(-5, -3, 4, 2, SKIN_D)
	_r( 1, -3, 4, 2, SKIN_D)

	# Neck
	_r(-3, -9, 6, 3, SKIN)

	# ── Left axe arm ──────────────────────────────────────────────────────────
	draw_set_transform(Vector2(-8, -6), l_axe_ang, Vector2.ONE)
	_r(-3,  0, 5, 9, SKIN)         # arm
	_c(-1,  9, 3, SKIN)            # fist
	_r(-6,-10, 3,14, WOOD_D)       # axe handle
	_r(-10,-14, 8, 7, STEEL)       # axe head
	_r(-10,-14, 8, 2, WHITE)       # blade edge
	_rst()

	# ── Right axe arm ─────────────────────────────────────────────────────────
	draw_set_transform(Vector2(8, -6), r_axe_ang, Vector2.ONE)
	_r(-2,  0, 5, 9, SKIN)
	_c( 1,  9, 3, SKIN)
	_r( 3,-10, 3,14, WOOD_D)
	_r( 2,-14, 8, 7, STEEL)
	_r( 2,-14, 8, 2, WHITE)
	_rst()

	# ── Helmet + face ─────────────────────────────────────────────────────────
	_r(-8,-16,16, 9, HELM)
	_r(-9,-12,18, 4, FUR)          # fur brow
	# Horns
	_r(-11,-22, 3, 7, Color(0.85,0.80,0.72))
	_r(-10,-22, 2, 2, Color(1.0,0.95,0.85))
	_r(  8,-22, 3, 7, Color(0.85,0.80,0.72))
	_r(  9,-22, 2, 2, Color(1.0,0.95,0.85))
	# Face
	_r(-6,-16,12, 5, SKIN)
	_r(-5,-15, 3, 2, BLACK)        # eyes
	_r( 2,-15, 3, 2, BLACK)
	_r(-5,-16, 3, 1, FURD)         # angry brows
	_r( 2,-16, 3, 1, FURD)
	_r(-6,-13, 5, 1, _team_col)    # war paint
	_r( 1,-13, 5, 1, _team_col)

	_rst()


# ──────────────────────────────────────────────────────────────────────────────
# WIZARD  — robed mage, glowing staff (left), casting right hand
# ──────────────────────────────────────────────────────────────────────────────
func _draw_wizard(wp: float, ap: float) -> void:
	var ROBE := Color(0.28, 0.12, 0.58)
	var ROBD := Color(0.18, 0.07, 0.40)
	var ORB  := Color(0.55, 0.80, 1.00)

	var ll := _leg(wp, -1, 0.25)   # robes hide legs — subtle sway
	var rl := _leg(wp,  1, 0.25)
	var staff_ang := 0.0
	var cast_ang  := 0.0

	if ap > 0.0:
		staff_ang = _atk(ap, 0.60, 0.30)   # staff raises then thrusts
		cast_ang  = _atk(ap, 0.20, 0.50) * -1.0  # cast hand thrusts forward
	else:
		staff_ang = _arm(wp, -1, 0.15)
		cast_ang  = _arm(wp,  1, 0.15)

	# ── Robe hem (hides leg but still bobs) ───────────────────────────────────
	draw_set_transform(Vector2(0, 0), 0.0, Vector2.ONE)
	_r(-7,-5, 14,15, ROBE)         # robe body drawn first

	# Legs barely visible under robe
	draw_set_transform(Vector2(3, 8), rl, Vector2.ONE)
	_r(-2, 0, 4, 4, ROBD)
	_rst()
	draw_set_transform(Vector2(-3, 8), ll, Vector2.ONE)
	_r(-2, 0, 4, 4, ROBD)
	_rst()

	# ── Body ──────────────────────────────────────────────────────────────────
	_r(-7, -5,14,15, ROBE)         # redraw robe over legs
	draw_line(Vector2(0,-5), Vector2(0,10), ROBD, 1.0)
	_r(-7,  7,14, 2, Color(GOLD.r,GOLD.g,GOLD.b,0.8))  # hem stripe
	_r(-8, -1,16, 3, _team_col)    # belt
	_r(-3, -1, 6, 3, GOLD)         # buckle

	# Collar
	_r(-9,-8,18, 4, ROBE)
	_r(-5,-8,10, 2, GOLD)

	# ── Staff arm (left) ──────────────────────────────────────────────────────
	draw_set_transform(Vector2(-9, -5), staff_ang, Vector2.ONE)
	_r(-2,  0, 4, 8, ROBE)         # sleeve
	_c(-1,  8, 2.5, SKIN)          # hand
	_r(-2, 10, 3,20, WOOD_D)       # staff shaft
	_c(-1, 10, 5, ORB)             # glowing orb atop
	_c(-1, 10, 3, Color(0.80,0.95,1.0,0.7))
	_rst()

	# ── Cast arm (right) ──────────────────────────────────────────────────────
	draw_set_transform(Vector2(9, -5), cast_ang, Vector2.ONE)
	_r(-2, 0, 4, 8, ROBE)
	_c( 0, 8, 3.5, SKIN)
	if ap > 0.3 and ap < 0.65:     # magic burst during strike window
		_c(0, 8, 6, Color(0.5, 0.8, 1.0, 0.45))
		_c(0, 8, 4, Color(0.7, 0.9, 1.0, 0.30))
	_rst()

	# ── Head ──────────────────────────────────────────────────────────────────
	_c(0,-13, 7, SKIN)
	_r(-5,-10,10, 5, WHITE)        # beard
	_r(-4,-10, 8, 2, Color(0.85,0.85,0.85))
	_c(-3,-14, 1.5, BLACK)
	_c( 3,-14, 1.5, BLACK)
	_c(-3,-14, 0.7, Color(0.4,0.7,1.0))  # magic glow eyes
	_c( 3,-14, 0.7, Color(0.4,0.7,1.0))
	# Hat
	var hp := PackedVector2Array([Vector2(0,-28), Vector2(-9,-18), Vector2(9,-18)])
	draw_colored_polygon(hp, ROBE)
	_r(-10,-20,20, 3, ROBD)
	_r( -3,-22, 6, 2, GOLD)

	# Sparkles (appear during attack)
	if ap > 0.25 and ap < 0.7:
		var s := Color(0.7, 0.9, 1.0, (1.0 - abs(ap - 0.47) * 4.0) * 0.8)
		_c(-3, -3, 2, s)
		_c( 5, -6, 1.5, s)
		_c( 2,  0, 1, s)


# ──────────────────────────────────────────────────────────────────────────────
# GOBLIN  — small, fast, dagger, big eyes, ear wiggle
# ──────────────────────────────────────────────────────────────────────────────
func _draw_goblin(wp: float, ap: float) -> void:
	var GSK  := Color(0.25, 0.72, 0.22)
	var GSKD := Color(0.16, 0.50, 0.14)
	var DGRY := Color(0.32, 0.28, 0.24)

	# Goblins run fast and erratic
	var gp := wp * 1.40
	var ll := _leg(gp, -1, 0.45)
	var rl := _leg(gp,  1, 0.45)
	var dagger_ang := 0.0

	if ap > 0.0:
		dagger_ang = _atk(ap, 0.7, 0.8)   # quick stabbing motion
	else:
		dagger_ang = _arm(gp, 1, 0.35)

	# ── Right leg ─────────────────────────────────────────────────────────────
	draw_set_transform(Vector2(2, 2), rl, Vector2.ONE)
	_r(-2, 0, 4, 5, GSKD)
	_r(-2, 4, 4, 3, DGRY)
	_rst()

	# ── Left leg ──────────────────────────────────────────────────────────────
	draw_set_transform(Vector2(-2, 2), ll, Vector2.ONE)
	_r(-2, 0, 4, 5, GSKD)
	_r(-2, 4, 4, 3, DGRY)
	_rst()

	# ── Body ──────────────────────────────────────────────────────────────────
	# Loincloth
	_r(-5, 0,10, 4, DGRY)
	_r(-5, 0,10, 2, _team_col)

	# Torso
	_r(-5,-6,10, 7, GSK)
	draw_line(Vector2(0,-6), Vector2(0, 1), GSKD, 1.0)

	# ── Left arm ──────────────────────────────────────────────────────────────
	var la := _arm(gp, -1, 0.35)
	draw_set_transform(Vector2(-6, -5), la, Vector2.ONE)
	_r(-2,  0, 4, 7, GSK)
	_c(-1,  7, 2.5, GSK)
	_rst()

	# ── Dagger arm (right) ────────────────────────────────────────────────────
	draw_set_transform(Vector2(6, -5), dagger_ang, Vector2.ONE)
	_r(-2,  0, 4, 7, GSK)
	_c( 0,  7, 2.5, GSK)
	_r(-1,  8, 2,11, Color(0.78,0.80,0.84))   # blade
	_r(-3,  6, 6, 2, GOLD)                     # guard
	_rst()

	# ── Head ──────────────────────────────────────────────────────────────────
	_c(0,-11, 7, GSK)
	# Ears (slightly wiggle with walk)
	var ear_wobble := sin(gp * 0.5) * 1.2
	_r(-12, int(-13+ear_wobble), 5, 5, GSK)
	_r(  7, int(-13-ear_wobble), 5, 5, GSK)
	_r(-13, int(-11+ear_wobble), 2, 3, GSKD)
	_r( 11, int(-11-ear_wobble), 2, 3, GSKD)
	# Big eyes
	_c(-3,-12, 2.5, Color(1.0, 0.85, 0.0))
	_c( 3,-12, 2.5, Color(1.0, 0.85, 0.0))
	_c(-3,-12, 1, BLACK)
	_c( 3,-12, 1, BLACK)
	# Grin
	_r(-4, -8, 8, 2, BLACK)
	_r(-3, -8, 2, 2, WHITE)
	_r( 0, -8, 2, 2, WHITE)
	_c(0,-10, 1.2, GSKD)   # nose
