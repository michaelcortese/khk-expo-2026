class_name HUD
extends CanvasLayer

# ── Layout (1280 × 1024 screen) ───────────────────────────────────────────────
const SCREEN_W  := 1280.0
const SCREEN_H  := 1024.0
const PANEL_H   := 290.0
const PANEL_Y   := SCREEN_H - PANEL_H          # 734

const CENTER_W  := 64.0
const SIDE_W    := (SCREEN_W - CENTER_W) * 0.5  # 608

const CARD_W    := 108.0   # 3× knight card width  (36 px native)
const CARD_H    := 132.0   # 3× knight card height (44 px native) — 9:11 ratio
const CARD_PAD  := 5.0
const NEXT_W    := 108.0   # same size as hand cards
const NEXT_H    := 132.0

const ELIX_H    := 32.0
const ELIX_Y    := PANEL_Y + PANEL_H - ELIX_H - 10.0

const ELIX_COL  := Color(0.58, 0.08, 0.88)
const P1_COL    := Color(0.15, 0.65, 1.00)
const P2_COL    := Color(1.00, 0.18, 0.18)
const CARD_BG   := Color(0.13, 0.13, 0.17)
const PANEL_BG  := Color(0.07, 0.07, 0.09, 0.97)

# ── Refs ──────────────────────────────────────────────────────────────────────
var _p1_segs:       Array = []
var _p2_segs:       Array = []
var _p1_elix_rects: Array = []
var _p2_elix_rects: Array = []
var _p1_elix_lbl:   Label
var _p2_elix_lbl:   Label
var _elix_prev_tex: Texture2D = null
var _elix_curr_tex: Texture2D = null
var _elix_base_tex: Texture2D = null
var _seg_w_stored:  float = 0.0
var _seg_h_stored:  float = 0.0
var _p1_recharge_rect: ColorRect = null
var _p2_recharge_rect: ColorRect = null

var _p1_card_name:  Array = []
var _p2_card_name:  Array = []
var _p1_card_cost:  Array = []
var _p2_card_cost:  Array = []
var _p1_card_bg:    Array = []
var _p2_card_bg:    Array = []
var _p1_card_cnt:   Array = []
var _p2_card_cnt:   Array = []
var _p1_card_flash: Array = []   # white overlay — fades out on play
var _p2_card_flash: Array = []
var _p1_card_root:  Array = []   # Control root per card for scale bounce
var _p2_card_root:  Array = []
var _p1_card_icon:  Array = []   # TextureRect — card art (null texture = hidden)
var _p2_card_icon:  Array = []

var _p1_next_name:  Label
var _p2_next_name:  Label
var _p1_next_cost:  Label
var _p2_next_cost:  Label
var _p1_next_root:  Control
var _p2_next_root:  Control
var _p1_next_icon:  TextureRect
var _p2_next_icon:  TextureRect

var _timer_lbl:          Label
var _timer_bg:           ColorRect
var _p1_crown_lbl:       Label
var _p2_crown_lbl:       Label
var _double_elixir_bg:   ColorRect  # kept for null-safety; no longer created
var _double_elixir_lbl:  Label      # kept for null-safety; no longer created
var _de_tween:           Tween
var _center_elix_icon:   TextureRect
var _elix1_tex:          Texture2D
var _elix2_tex:          Texture2D

# ── Animation state ───────────────────────────────────────────────────────────
var _p1_last_ids:  Array[String] = ["","","",""]
var _p2_last_ids:  Array[String] = ["","","",""]
var _p1_next_last_id: String = ""
var _p2_next_last_id: String = ""
var _p1_last_aff:  Array[bool]   = [false,false,false,false]
var _p2_last_aff:  Array[bool]   = [false,false,false,false]
var _p1_elix_int:  int = 0
var _p2_elix_int:  int = 0

var _elix_num_textures: Dictionary = {}   # int (1-10) → Texture2D
var _p1_elix_icon: TextureRect = null
var _p2_elix_icon: TextureRect = null
var _p1_max_tween: Tween = null
var _p2_max_tween: Tween = null

# ── Build ──────────────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 8
	_elix_prev_tex = load("res://assets/elixer_bar_assets/elixer_bar_prev_chunck.png") as Texture2D
	_elix_curr_tex = load("res://assets/elixer_bar_assets/elixer_bar_curr_chunk.png")  as Texture2D
	_elix_base_tex = load("res://assets/elixer_bar_assets/base_elixer.png")            as Texture2D
	# Number icon textures 1-9
	for n in range(1, 11):
		_elix_num_textures[n] = load("res://assets/elixer_bar_assets/elixer_%d.png" % n) as Texture2D
	_build_bg()
	_build_timer()
	_build_side(0)
	_build_side(1)
	_build_center_gem()

func _build_bg() -> void:
	var bg := ColorRect.new()
	bg.color    = PANEL_BG
	bg.position = Vector2(0.0, PANEL_Y)
	bg.size     = Vector2(SCREEN_W, PANEL_H)
	add_child(bg)

	# Thin bright separator line at top of panel
	var sep := ColorRect.new()
	sep.color    = Color(1.0, 1.0, 1.0, 0.10)
	sep.position = Vector2(0.0, PANEL_Y)
	sep.size     = Vector2(SCREEN_W, 1.0)
	add_child(sep)

func _build_timer() -> void:
	_timer_bg = ColorRect.new()
	_timer_bg.color    = Color(0.0, 0.0, 0.0, 0.70)
	_timer_bg.position = Vector2(SCREEN_W * 0.5 - 72.0, 6.0)
	_timer_bg.size     = Vector2(144.0, 52.0)
	add_child(_timer_bg)

	_timer_lbl = Label.new()
	_timer_lbl.text     = "3:00"
	_timer_lbl.position = Vector2(SCREEN_W * 0.5 - 68.0, 11.0)
	_timer_lbl.size     = Vector2(136.0, 42.0)
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_lbl.add_theme_font_size_override("font_size", 32)
	_timer_lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(_timer_lbl)

	# P1 crown — left of timer
	_p1_crown_lbl = _make_crown_lbl(
		Vector2(SCREEN_W * 0.5 - 72.0 - 116.0, 6.0), P1_COL, "★  0")
	# P2 crown — right of timer
	_p2_crown_lbl = _make_crown_lbl(
		Vector2(SCREEN_W * 0.5 + 72.0 + 4.0, 6.0), P2_COL, "0  ★")

func _make_crown_lbl(pos: Vector2, col: Color, txt: String) -> Label:
	var cbg := ColorRect.new()
	cbg.color    = Color(0.0, 0.0, 0.0, 0.60)
	cbg.position = pos
	cbg.size     = Vector2(112.0, 52.0)
	add_child(cbg)

	var lbl := Label.new()
	lbl.text = txt
	lbl.position = pos
	lbl.size     = Vector2(112.0, 52.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", col)
	add_child(lbl)
	return lbl

func _build_center_gem() -> void:
	var gbg := ColorRect.new()
	gbg.color    = Color(0.08, 0.03, 0.15)
	gbg.position = Vector2(SIDE_W, PANEL_Y)
	gbg.size     = Vector2(CENTER_W, PANEL_H)
	add_child(gbg)

	# Left/right divider lines
	for dx in [0.0, CENTER_W - 1.0]:
		var line := ColorRect.new()
		line.color    = Color(1.0, 1.0, 1.0, 0.06)
		line.position = Vector2(SIDE_W + dx, PANEL_Y)
		line.size     = Vector2(1.0, PANEL_H)
		add_child(line)

	# Load both elixir icon textures
	_elix1_tex = load("res://assets/elixer_bar_assets/elixer_1.png") as Texture2D
	_elix2_tex = load("res://assets/elixer_bar_assets/elixer_2.png") as Texture2D

	# Center the icon in the panel
	var icon_size := 48.0
	_center_elix_icon                    = TextureRect.new()
	_center_elix_icon.texture            = _elix1_tex
	_center_elix_icon.texture_filter     = CanvasItem.TEXTURE_FILTER_NEAREST
	_center_elix_icon.expand_mode        = TextureRect.EXPAND_IGNORE_SIZE
	_center_elix_icon.stretch_mode       = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_center_elix_icon.position           = Vector2(SIDE_W + CENTER_W * 0.5 - icon_size * 0.5,
												   PANEL_Y + PANEL_H * 0.5 - icon_size * 0.5)
	_center_elix_icon.size               = Vector2(icon_size, icon_size)
	add_child(_center_elix_icon)

# ── Card icon loader ──────────────────────────────────────────────────────────
func _load_card_icon(card_id: String) -> Texture2D:
	# Check subfolder first (e.g. assets/knight_assets/knight_card.png)
	var subfolder := "res://assets/" + card_id + "_assets/" + card_id + "_card.png"
	if ResourceLoader.exists(subfolder):
		return load(subfolder) as Texture2D
	# Some card IDs use underscores but their asset folders drop them (e.g. hog_rider → hogrider)
	var compact_id := card_id.replace("_", "")
	var compact := "res://assets/" + compact_id + "_assets/" + compact_id + "_card.png"
	if ResourceLoader.exists(compact):
		return load(compact) as Texture2D
	# Fallback: root assets folder
	var root := "res://assets/" + card_id + "_card.png"
	if ResourceLoader.exists(root):
		return load(root) as Texture2D
	return null

# ── Side panel (P1 or P2) ─────────────────────────────────────────────────────
func _build_side(p: int) -> void:
	var is_p1   := p == 0
	var tc      := P1_COL if is_p1 else P2_COL
	var sec_x   := 0.0 if is_p1 else SIDE_W + CENTER_W

	# Team accent line
	var accent := ColorRect.new()
	accent.color    = tc
	accent.position = Vector2(sec_x, PANEL_Y)
	accent.size     = Vector2(SIDE_W, 3.0)
	add_child(accent)

	# Subtle team tint
	var tint := ColorRect.new()
	tint.color    = Color(tc.r, tc.g, tc.b, 0.05)
	tint.position = Vector2(sec_x, PANEL_Y + 3.0)
	tint.size     = Vector2(SIDE_W, PANEL_H - 3.0)
	add_child(tint)

	# ── Layout: for P1 [NEXT][1][2][3][4], for P2 [1][2][3][4][NEXT]
	var PAD       := 8.0
	var hand_x:  float
	var next_x:  float
	if is_p1:
		next_x = sec_x + PAD
		hand_x = next_x + NEXT_W + PAD
	else:
		next_x = sec_x + SIDE_W - PAD - NEXT_W
		hand_x = sec_x + PAD

	_build_next_card(p, next_x, tc)
	_build_hand(p, hand_x, sec_x, tc)
	_build_elixir_bar(p, sec_x, tc)

# ── Next card preview ─────────────────────────────────────────────────────────
func _build_next_card(p: int, nx: float, tc: Color) -> void:
	const NEXT_COST_ROW := 26.0
	var is_p1 := p == 0

	# Root: "NEXT" label + image + cost below image
	var root := Control.new()
	root.position = Vector2(nx, PANEL_Y + 8.0)
	root.size     = Vector2(NEXT_W, 16.0 + NEXT_H + NEXT_COST_ROW)
	add_child(root)
	if is_p1: _p1_next_root = root
	else:     _p2_next_root = root

	# "NEXT" header label
	var lbl := Label.new()
	lbl.text = "NEXT"
	lbl.position = Vector2(0.0, 0.0)
	lbl.size     = Vector2(NEXT_W, 16.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(tc.r, tc.g, tc.b, 0.80))
	root.add_child(lbl)

	# 1. Dark background — wraps image
	var nbg := ColorRect.new()
	nbg.color    = CARD_BG
	nbg.position = Vector2(0.0, 16.0)
	nbg.size     = Vector2(NEXT_W, NEXT_H)
	root.add_child(nbg)

	# 2. Name fallback label (hidden when icon shown)
	var nn := Label.new()
	nn.position      = Vector2(5.0, 24.0)
	nn.size          = Vector2(NEXT_W - 8.0, NEXT_H - 8.0)
	nn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nn.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	nn.add_theme_font_size_override("font_size", 13)
	nn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	nn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(nn)

	# 3. Card icon — fills image area (added after bg, before frame overlay)
	var ni := TextureRect.new()
	ni.position     = Vector2(0.0, 16.0)
	ni.size         = Vector2(NEXT_W, NEXT_H)
	ni.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	ni.stretch_mode = TextureRect.STRETCH_SCALE
	ni.visible      = false
	root.add_child(ni)

	# 4. Left accent bar on top of image
	var bar := ColorRect.new()
	bar.color    = Color(tc.r, tc.g, tc.b, 0.70)
	bar.position = Vector2(0.0, 16.0)
	bar.size     = Vector2(3.0, NEXT_H)
	root.add_child(bar)

	# 5. Elixir cost — below image
	var nc := Label.new()
	nc.position = Vector2(0.0, 16.0 + NEXT_H + 2.0)
	nc.size     = Vector2(NEXT_W, NEXT_COST_ROW - 2.0)
	nc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nc.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	nc.add_theme_font_size_override("font_size", 17)
	nc.add_theme_color_override("font_color", ELIX_COL)
	root.add_child(nc)

	if is_p1: _p1_next_name = nn; _p1_next_cost = nc; _p1_next_icon = ni
	else:     _p2_next_name = nn; _p2_next_cost = nc; _p2_next_icon = ni

# ── 4-card hand ───────────────────────────────────────────────────────────────
func _build_hand(p: int, hx: float, sec_x: float, tc: Color) -> void:
	var is_p1 := p == 0
	var btn_cols := [
		Color(0.20, 0.50, 1.00),
		Color(0.10, 0.85, 0.20),
		Color(1.00, 0.85, 0.10),
		Color(1.00, 0.20, 0.20),
	] if is_p1 else [
		Color(1.00, 0.20, 0.20),
		Color(1.00, 0.85, 0.10),
		Color(0.10, 0.85, 0.20),
		Color(0.20, 0.50, 1.00),
	]

	var card_roots: Array = []
	var card_bgs:   Array = []
	var card_names: Array = []
	var card_costs: Array = []
	var card_cnts:  Array = []
	var card_flash: Array = []
	var card_icons: Array = []

	const COST_ROW := 26.0   # height of cost label row below image

	for i in range(4):
		var cx := hx + i * (CARD_W + CARD_PAD)
		var cy := PANEL_Y + 8.0
		var bc: Color = btn_cols[i]

		# Root Control — image area + cost row below
		var root := Control.new()
		root.position     = Vector2(cx, cy)
		root.size         = Vector2(CARD_W, CARD_H + COST_ROW)
		root.pivot_offset = Vector2(CARD_W * 0.5, (CARD_H + COST_ROW) * 0.5)
		add_child(root)
		card_roots.append(root)

		# 1. Dark background — wraps tightly around the image
		var cbg := ColorRect.new()
		cbg.color    = CARD_BG
		cbg.position = Vector2.ZERO
		cbg.size     = Vector2(CARD_W, CARD_H)
		root.add_child(cbg)
		card_bgs.append(cbg)

		# 2. Card name (fallback when no icon — sits over dark bg)
		var name_lbl := Label.new()
		name_lbl.position      = Vector2(5.0, 20.0)
		name_lbl.size          = Vector2(CARD_W - 10.0, CARD_H - 20.0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(name_lbl)
		card_names.append(name_lbl)

		# 3. Card icon — fills image area exactly (added after bg, before overlays)
		var icon := TextureRect.new()
		icon.position     = Vector2.ZERO
		icon.size         = Vector2(CARD_W, CARD_H)
		icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.visible      = false
		root.add_child(icon)
		card_icons.append(icon)

		# 4. Border frame overlaid on image: top strip (button color) + left bar (team color)
		var strip := ColorRect.new()
		strip.color    = Color(bc.r, bc.g, bc.b, 0.85)
		strip.position = Vector2.ZERO
		strip.size     = Vector2(CARD_W, 4.0)
		root.add_child(strip)

		var lbar := ColorRect.new()
		lbar.color    = Color(tc.r, tc.g, tc.b, 0.70)
		lbar.position = Vector2.ZERO
		lbar.size     = Vector2(3.0, CARD_H)
		root.add_child(lbar)

		# 5. Number badge — top-right corner, on top of image
		var badge_bg := ColorRect.new()
		badge_bg.color    = Color(bc.r, bc.g, bc.b, 0.92)
		badge_bg.position = Vector2(CARD_W - 22.0, 4.0)
		badge_bg.size     = Vector2(18.0, 18.0)
		root.add_child(badge_bg)

		var badge_lbl := Label.new()
		badge_lbl.text     = str(i + 1)
		badge_lbl.position = Vector2(CARD_W - 22.0, 3.0)
		badge_lbl.size     = Vector2(18.0, 18.0)
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		badge_lbl.add_theme_font_size_override("font_size", 12)
		badge_lbl.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
		root.add_child(badge_lbl)

		# 6. Elixir cost — below image, always visible
		var cost_lbl := Label.new()
		cost_lbl.position = Vector2(0.0, CARD_H + 2.0)
		cost_lbl.size     = Vector2(CARD_W, COST_ROW - 2.0)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 17)
		cost_lbl.add_theme_color_override("font_color", ELIX_COL)
		root.add_child(cost_lbl)
		card_costs.append(cost_lbl)

		# 7. Troop count badge — bottom-right of image, on top
		var cnt_lbl := Label.new()
		cnt_lbl.position = Vector2(CARD_W - 32.0, CARD_H - 20.0)
		cnt_lbl.size     = Vector2(28.0, 18.0)
		cnt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt_lbl.add_theme_font_size_override("font_size", 11)
		cnt_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		root.add_child(cnt_lbl)
		card_cnts.append(cnt_lbl)

		# 8. Flash overlay — covers image area only
		var flash := ColorRect.new()
		flash.color    = Color(1.0, 1.0, 1.0, 0.0)
		flash.position = Vector2.ZERO
		flash.size     = Vector2(CARD_W, CARD_H)
		root.add_child(flash)
		card_flash.append(flash)

	if is_p1:
		_p1_card_root = card_roots; _p1_card_bg = card_bgs
		_p1_card_name = card_names; _p1_card_cost = card_costs
		_p1_card_cnt  = card_cnts;  _p1_card_flash = card_flash
		_p1_card_icon = card_icons
	else:
		_p2_card_root = card_roots; _p2_card_bg = card_bgs
		_p2_card_name = card_names; _p2_card_cost = card_costs
		_p2_card_cnt  = card_cnts;  _p2_card_flash = card_flash
		_p2_card_icon = card_icons

# ── Elixir bar ────────────────────────────────────────────────────────────────
func _build_elixir_bar(p: int, sec_x: float, tc: Color) -> void:
	var is_p1   := p == 0
	var SEG_N   := 10
	var num_w   := 42.0
	var bar_gap := 4.0
	var bar_w   := SIDE_W - num_w - bar_gap - 10.0
	var seg_gap := 3.0
	var seg_w   := (bar_w - seg_gap * (SEG_N - 1)) / SEG_N
	var seg_h   := ELIX_H - 12.0
	_seg_w_stored = seg_w

	var num := Label.new()
	num.size = Vector2(num_w, ELIX_H)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", 24)
	num.add_theme_color_override("font_color", ELIX_COL)

	var bar_x: float
	if is_p1:
		num.position = Vector2(sec_x + 5.0, ELIX_Y)
		bar_x        = sec_x + num_w + bar_gap
	else:
		num.position = Vector2(sec_x + SIDE_W - num_w - 5.0, ELIX_Y)
		bar_x        = sec_x + 5.0
	num.visible = false   # hidden unless icon unavailable
	add_child(num)

	# Number icon — overlays same area as the label
	var icon_tr := TextureRect.new()
	icon_tr.position       = num.position
	icon_tr.size           = Vector2(num_w, ELIX_H)
	icon_tr.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	icon_tr.stretch_mode   = TextureRect.STRETCH_SCALE
	icon_tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_tr.pivot_offset   = Vector2(num_w * 0.5, ELIX_H * 0.5)
	icon_tr.visible        = false
	add_child(icon_tr)
	if is_p1: _p1_elix_icon = icon_tr
	else:     _p2_elix_icon = icon_tr

	# Bar background
	var bar_bg := ColorRect.new()
	bar_bg.color    = Color(0.18, 0.18, 0.20)
	bar_bg.position = Vector2(bar_x, ELIX_Y + 3.0)
	bar_bg.size     = Vector2(bar_w, ELIX_H - 6.0)
	add_child(bar_bg)

	_seg_h_stored = seg_h

	# Pass 1 — gray slot backgrounds (always visible)
	var slot_positions: Array = []
	for s in range(SEG_N):
		var sx := bar_x + s * (seg_w + seg_gap)
		var sy := ELIX_Y + 6.0
		slot_positions.append(Vector2(sx, sy))
		var bg := ColorRect.new()
		bg.color    = Color(0.28, 0.28, 0.30)
		bg.position = Vector2(sx, sy)
		bg.size     = Vector2(seg_w, seg_h)
		add_child(bg)

	# Recharge rect — purple bar that slides up inside the next slot to fill
	var recharge := ColorRect.new()
	recharge.color   = Color(0.55, 0.10, 0.82, 0.60)
	recharge.visible = false
	add_child(recharge)
	if is_p1: _p1_recharge_rect = recharge
	else:     _p2_recharge_rect = recharge

	# Pass 2 — chunk TextureRects (on top of gray bgs and recharge rect)
	var segs:  Array = []
	var rects: Array = []
	for s in range(SEG_N):
		var sp: Vector2 = slot_positions[s]
		var rect := TextureRect.new()
		rect.texture        = _elix_prev_tex
		rect.position       = sp
		rect.size           = Vector2(seg_w, seg_h)
		rect.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode   = TextureRect.STRETCH_SCALE
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.pivot_offset   = Vector2(seg_w * 0.5, seg_h * 0.5)
		rect.flip_h         = not is_p1
		rect.visible        = false
		add_child(rect)
		segs.append(rect)
		rects.append(rect)

	if is_p1: _p1_segs = segs; _p1_elix_lbl = num; _p1_elix_rects = rects
	else:     _p2_segs = segs; _p2_elix_lbl = num; _p2_elix_rects = rects

# ── Update (called every frame from GameManager) ──────────────────────────────
func update_hud(p1_elixir: float, p2_elixir: float,
				p1_deck: Deck, p2_deck: Deck) -> void:
	_refresh_elixir(_p1_segs, _p1_elix_rects, _p1_elix_lbl, p1_elixir, 0)
	_refresh_elixir(_p2_segs, _p2_elix_rects, _p2_elix_lbl, p2_elixir, 1)
	_refresh_hand(0, p1_deck, p1_elixir)
	_refresh_hand(1, p2_deck, p2_elixir)
	_refresh_next(0, p1_deck)
	_refresh_next(1, p2_deck)

func _refresh_hand(p: int, deck: Deck, elixir: float) -> void:
	var names  := _p1_card_name  if p == 0 else _p2_card_name
	var costs  := _p1_card_cost  if p == 0 else _p2_card_cost
	var bgs    := _p1_card_bg    if p == 0 else _p2_card_bg
	var cnts   := _p1_card_cnt   if p == 0 else _p2_card_cnt
	var roots  := _p1_card_root  if p == 0 else _p2_card_root
	var flash  := _p1_card_flash if p == 0 else _p2_card_flash
	var icons  := _p1_card_icon  if p == 0 else _p2_card_icon
	var l_ids  := _p1_last_ids   if p == 0 else _p2_last_ids
	var l_aff  := _p1_last_aff   if p == 0 else _p2_last_aff

	for i in range(4):
		var card     := deck.hand[i]
		var cur_id   := card.card_id
		var afford   := elixir >= float(card.cost)

		# ── Card changed (was played) → flash + reload icon
		var prev_id := l_ids[i]
		if prev_id != "" and prev_id != cur_id:
			_anim_card_play(flash[i], roots[i])
		l_ids[i] = cur_id

		# ── Just became affordable → green pulse
		if afford and not l_aff[i]:
			_anim_afford(roots[i])
		l_aff[i] = afford

		# Icon — load once when card_id changes or on first populate
		if prev_id != cur_id or icons[i].texture == null:
			var tex := _load_card_icon(cur_id)
			icons[i].texture = tex
			icons[i].visible = tex != null
			names[i].visible = tex == null

		# Text
		names[i].text = card.display_name
		costs[i].text = "◆ %d" % card.cost

		var total := card.troop_count + card.secondary_count
		cnts[i].text = "×%d" % total if total > 1 else ""

		# Dim if can't afford
		var dim := 0.38 if not afford else 1.0
		bgs[i].color      = Color(CARD_BG.r * dim, CARD_BG.g * dim, CARD_BG.b * dim + 0.04 * (1.0 - dim))
		names[i].add_theme_color_override("font_color",
				Color.WHITE if afford else Color(0.40, 0.40, 0.40))
		costs[i].add_theme_color_override("font_color",
				ELIX_COL if afford else Color(0.30, 0.05, 0.45))

func _refresh_next(p: int, deck: Deck) -> void:
	var nn := _p1_next_name if p == 0 else _p2_next_name
	var nc := _p1_next_cost if p == 0 else _p2_next_cost
	var ni := _p1_next_icon if p == 0 else _p2_next_icon
	var card := deck.next_card
	nn.text = card.display_name
	nc.text = "◆ %d" % card.cost
	if ni != null:
		var last_next_id := _p1_next_last_id if p == 0 else _p2_next_last_id
		if card.card_id != last_next_id:
			var tex := _load_card_icon(card.card_id)
			ni.texture = tex
			ni.visible = tex != null
			nn.visible = tex == null
			if p == 0: _p1_next_last_id = card.card_id
			else:      _p2_next_last_id = card.card_id

func _refresh_elixir(segs: Array, rects: Array, lbl: Label, value: float, p: int) -> void:
	var filled := int(value)
	var at_max := value >= 9.9
	var last   := _p1_elix_int if p == 0 else _p2_elix_int
	var icon   := _p1_elix_icon if p == 0 else _p2_elix_icon

	# Pop-in animation for newly filled segments
	if filled > last:
		for s in range(last, mini(filled, segs.size())):
			_anim_seg_pop(segs[s])
	if p == 0: _p1_elix_int = filled
	else:      _p2_elix_int = filled

	# Discrete chunks: slots 0..(filled-2) = prev, slot (filled-1) = curr, rest = gray
	for i in range(10):
		var rect: TextureRect = segs[i]
		if at_max or i < filled - 1:
			rect.texture = _elix_prev_tex
			rect.visible = true
		elif i == filled - 1:
			rect.texture = _elix_curr_tex
			rect.visible = true
		else:
			rect.visible = false

	# Recharge bar — purple fill that slides up inside the next empty slot
	var recharge: ColorRect = _p1_recharge_rect if p == 0 else _p2_recharge_rect
	var frac := fmod(value, 1.0)
	if recharge != null:
		if not at_max and filled < 10 and frac > 0.01:
			var slot: TextureRect = segs[filled]
			var fill_w := _seg_w_stored * frac
			recharge.position = Vector2(slot.position.x, slot.position.y)
			recharge.size     = Vector2(fill_w, _seg_h_stored)
			recharge.visible  = true
		else:
			recharge.visible = false

	# Counter icon: use number sprite when available, fall back to Label
	if icon != null:
		var key: int      = 10 if at_max else filled
		var tex: Texture2D = _elix_num_textures.get(key, null) as Texture2D
		if tex != null:
			icon.texture = tex
			icon.visible = true
			lbl.visible  = false
		else:
			icon.visible = false
			lbl.visible  = true
			lbl.text     = str(filled)

	# Looping pulse when bar is full; stop pulse when not full
	if at_max:
		var mx_tw := _p1_max_tween if p == 0 else _p2_max_tween
		if icon != null and (mx_tw == null or not mx_tw.is_running()):
			mx_tw = create_tween().set_loops()
			mx_tw.tween_property(icon, "scale", Vector2(1.22, 1.22), 0.35) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			mx_tw.tween_property(icon, "scale", Vector2.ONE,          0.35) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			if p == 0: _p1_max_tween = mx_tw
			else:      _p2_max_tween = mx_tw
	else:
		var mx_tw := _p1_max_tween if p == 0 else _p2_max_tween
		if mx_tw != null and mx_tw.is_running():
			mx_tw.kill()
			if icon != null:
				icon.scale = Vector2.ONE
			if p == 0: _p1_max_tween = null
			else:      _p2_max_tween = null

# ── Animations ────────────────────────────────────────────────────────────────

func _anim_card_play(flash_rect: ColorRect, root: Control) -> void:
	# 1. Quick scale-down punch
	# 2. White flash that fades out
	root.scale = Vector2(0.88, 0.88)
	flash_rect.color.a = 0.55
	var tw := create_tween().set_parallel(true)
	tw.tween_property(root,       "scale",       Vector2.ONE, 0.30) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(flash_rect, "color:a",     0.0,         0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _anim_afford(root: Control) -> void:
	# Brief green-tinted scale bounce
	var tw := create_tween()
	tw.tween_property(root, "scale", Vector2(1.08, 1.08), 0.10) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "scale", Vector2.ONE,         0.14) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _anim_seg_pop(seg: TextureRect) -> void:
	seg.scale = Vector2(1.0, 0.4)
	var tw := create_tween()
	tw.tween_property(seg, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ── Crowns ────────────────────────────────────────────────────────────────────
func set_crowns(p1: int, p2: int) -> void:
	if _p1_crown_lbl: _p1_crown_lbl.text = "★  %d" % p1
	if _p2_crown_lbl: _p2_crown_lbl.text = "%d  ★" % p2

# ── Timer ─────────────────────────────────────────────────────────────────────
func set_timer(remaining: float, phase: int) -> void:
	match phase:
		0:  # REGULAR
			_timer_lbl.add_theme_font_size_override("font_size", 32)
			var mins := int(remaining) / 60
			var secs := int(remaining) % 60
			_timer_lbl.text = "%d:%02d" % [mins, secs]
			if remaining < 30.0:
				var t := sin(Time.get_ticks_msec() * 0.010) * 0.5 + 0.5
				_timer_bg.color = Color(0.35 * t, 0.0, 0.0, 0.85)
				_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.35 + 0.3 * t, 0.1))
			elif remaining < 60.0:
				_timer_bg.color = Color(0.12, 0.04, 0.0, 0.80)
				_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
			else:
				_timer_bg.color = Color(0.0, 0.0, 0.0, 0.70)
				_timer_lbl.add_theme_color_override("font_color", Color.WHITE)
		1:  # OVERTIME
			_timer_lbl.add_theme_font_size_override("font_size", 22)
			var mins := int(remaining) / 60
			var secs := int(remaining) % 60
			_timer_lbl.text = "OT %d:%02d" % [mins, secs]
			_timer_bg.color = Color(0.14, 0.06, 0.0, 0.85)
			_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
		2:  # SUDDEN DEATH
			_timer_lbl.add_theme_font_size_override("font_size", 15)
			_timer_lbl.text = "SUDDEN\nDEATH"
			var t := sin(Time.get_ticks_msec() * 0.010) * 0.5 + 0.5
			_timer_bg.color = Color(0.30 * t, 0.0, 0.0, 0.90)
			_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))

# ── 2× Elixir ─────────────────────────────────────────────────────────────────
func set_double_elixir(active: bool) -> void:
	if _center_elix_icon == null:
		return
	_center_elix_icon.texture = _elix2_tex if active else _elix1_tex
	if active and (_de_tween == null or not _de_tween.is_running()):
		_de_tween = create_tween().set_loops()
		_de_tween.tween_property(_center_elix_icon, "modulate:a", 0.55, 0.45)
		_de_tween.tween_property(_center_elix_icon, "modulate:a", 1.0,  0.45)
	elif not active and _de_tween != null:
		_de_tween.kill()
		_center_elix_icon.modulate.a = 1.0
		_de_tween = null
