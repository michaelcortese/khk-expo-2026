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

var _bg_frames:      Array = []
var _bg_cur_frame:   int   = 0
var _bg_frame_timer: float = 0.0
const BG_FRAME_INTERVAL := 0.5

func _ready() -> void:
	for i in [1, 2]:
		_bg_frames.append(
			load("res://assets/background_assets/background_frame%d.png" % i) as Texture2D)

func _process(delta: float) -> void:
	_bg_frame_timer += delta
	if _bg_frame_timer >= BG_FRAME_INTERVAL:
		_bg_frame_timer -= BG_FRAME_INTERVAL
		_bg_cur_frame    = 1 - _bg_cur_frame
		queue_redraw()

func _draw() -> void:
	# Animated background — fills the full field rect
	var field_rect := Rect2(FIELD_L, FIELD_T, FIELD_R - FIELD_L, FIELD_B - FIELD_T)
	if _bg_frames.size() == 2 and _bg_frames[_bg_cur_frame] != null:
		draw_texture_rect(_bg_frames[_bg_cur_frame], field_rect, false)
	else:
		# Fallback solid color if textures failed to load
		draw_rect(field_rect, Color(0.18, 0.45, 0.15))


func _draw_bridges() -> void:
	_draw_one_bridge(BRIDGE_TOP_Y0, BRIDGE_TOP_Y1)
	_draw_one_bridge(BRIDGE_BOT_Y0, BRIDGE_BOT_Y1)

func _draw_one_bridge(y0: float, y1: float) -> void:
	var bh := y1 - y0
	# Bridge deck (wood planks)
	draw_rect(Rect2(RIVER_X - 6, y0, RIVER_W + 12, bh), Color(0.55, 0.38, 0.18))
	# Individual planks
	var plank_col := Color(0.62, 0.44, 0.22)
	var gap_col   := Color(0.40, 0.26, 0.10)
	var plank_h   := 12.0
	var gap_h     :=  4.0
	var py        := y0 + 4.0
	while py + plank_h <= y1 - 4.0:
		draw_rect(Rect2(RIVER_X - 4, py, RIVER_W + 8, plank_h), plank_col)
		draw_rect(Rect2(RIVER_X - 4, py + plank_h, RIVER_W + 8, gap_h), gap_col)
		py += plank_h + gap_h
	# Side rails
	draw_rect(Rect2(RIVER_X - 8, y0, 4, bh), Color(0.35, 0.22, 0.08))
	draw_rect(Rect2(RIVER_X + RIVER_W + 4, y0, 4, bh), Color(0.35, 0.22, 0.08))

func _draw_vignette() -> void:
	var edge := 80.0
	var col  := Color(0.0, 0.0, 0.0, 0.55)
	draw_rect(Rect2(FIELD_L, FIELD_T,          FIELD_R - FIELD_L, edge), col)
	draw_rect(Rect2(FIELD_L, FIELD_B - edge,   FIELD_R - FIELD_L, edge), col)
	draw_rect(Rect2(FIELD_L, FIELD_T,          edge, FIELD_B - FIELD_T), col)
	draw_rect(Rect2(FIELD_R - edge, FIELD_T,   edge, FIELD_B - FIELD_T), col)
