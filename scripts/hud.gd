class_name HUD
extends CanvasLayer

# ── Layout (1280 × 1024 screen) ───────────────────────────────────────────────
const SCREEN_W  := 1280.0
const SCREEN_H  := 1024.0
const PANEL_H   := 290.0
const PANEL_Y   := SCREEN_H - PANEL_H          # 734

const CENTER_W  := 64.0
const SIDE_W    := (SCREEN_W - CENTER_W) * 0.5  # 608

const CARD_W    := 110.0
const CARD_H    := 196.0
const CARD_PAD  := 5.0
const NEXT_W    := 76.0
const NEXT_H    := 180.0

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
var _p1_elix_lbl:   Label
var _p2_elix_lbl:   Label

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

var _p1_next_name:  Label
var _p2_next_name:  Label
var _p1_next_cost:  Label
var _p2_next_cost:  Label
var _p1_next_root:  Control
var _p2_next_root:  Control

var _timer_lbl:          Label
var _timer_bg:           ColorRect
var _p1_crown_lbl:       Label
var _p2_crown_lbl:       Label
var _double_elixir_bg:   ColorRect
var _double_elixir_lbl:  Label
var _de_tween:           Tween

# ── Animation state ───────────────────────────────────────────────────────────
var _p1_last_ids:  Array[String] = ["","","",""]
var _p2_last_ids:  Array[String] = ["","","",""]
var _p1_last_aff:  Array[bool]   = [false,false,false,false]
var _p2_last_aff:  Array[bool]   = [false,false,false,false]
var _p1_elix_int:  int = 0
var _p2_elix_int:  int = 0

# ── Build ──────────────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 8
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

	var gem := Label.new()
	gem.text     = "✦"
	gem.position = Vector2(SIDE_W + CENTER_W * 0.5 - 18.0, PANEL_Y + PANEL_H * 0.5 - 26.0)
	gem.size     = Vector2(36.0, 48.0)
	gem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gem.add_theme_font_size_override("font_size", 34)
	gem.add_theme_color_override("font_color", ELIX_COL)
	add_child(gem)

	_double_elixir_bg = ColorRect.new()
	_double_elixir_bg.color    = Color(0.20, 0.04, 0.36)
	_double_elixir_bg.position = Vector2(SIDE_W - 2.0, PANEL_Y + PANEL_H * 0.5 + 32.0)
	_double_elixir_bg.size     = Vector2(CENTER_W + 4.0, 40.0)
	_double_elixir_bg.visible  = false
	add_child(_double_elixir_bg)

	_double_elixir_lbl = Label.new()
	_double_elixir_lbl.text     = "2×"
	_double_elixir_lbl.position = _double_elixir_bg.position
	_double_elixir_lbl.size     = _double_elixir_bg.size
	_double_elixir_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_double_elixir_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_double_elixir_lbl.add_theme_font_size_override("font_size", 26)
	_double_elixir_lbl.add_theme_color_override("font_color", Color(0.90, 0.25, 1.0))
	_double_elixir_lbl.visible = false
	add_child(_double_elixir_lbl)

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
	var is_p1 := p == 0
	var root  := Control.new()
	root.position = Vector2(nx, PANEL_Y + 8.0)
	root.size     = Vector2(NEXT_W, NEXT_H + 20.0)
	add_child(root)
	if is_p1: _p1_next_root = root
	else:     _p2_next_root = root

	var lbl := Label.new()
	lbl.text = "NEXT"
	lbl.position = Vector2(0.0, 0.0)
	lbl.size     = Vector2(NEXT_W, 16.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(tc.r, tc.g, tc.b, 0.80))
	root.add_child(lbl)

	var nbg := ColorRect.new()
	nbg.color    = CARD_BG
	nbg.position = Vector2(0.0, 18.0)
	nbg.size     = Vector2(NEXT_W, NEXT_H)
	root.add_child(nbg)

	# Left accent bar
	var bar := ColorRect.new()
	bar.color    = Color(tc.r, tc.g, tc.b, 0.60)
	bar.position = Vector2(0.0, 18.0)
	bar.size     = Vector2(3.0, NEXT_H)
	root.add_child(bar)

	var nn := Label.new()
	nn.position      = Vector2(5.0, 28.0)
	nn.size          = Vector2(NEXT_W - 8.0, NEXT_H - 40.0)
	nn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nn.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	nn.add_theme_font_size_override("font_size", 13)
	nn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	nn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(nn)

	var nc := Label.new()
	nc.position = Vector2(5.0, 18.0 + NEXT_H - 24.0)
	nc.size     = Vector2(NEXT_W - 8.0, 24.0)
	nc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nc.add_theme_font_size_override("font_size", 16)
	nc.add_theme_color_override("font_color", ELIX_COL)
	root.add_child(nc)

	if is_p1: _p1_next_name = nn; _p1_next_cost = nc
	else:     _p2_next_name = nn; _p2_next_cost = nc

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

	for i in range(4):
		var cx := hx + i * (CARD_W + CARD_PAD)
		var cy := PANEL_Y + 8.0
		var bc: Color = btn_cols[i]

		# Root Control for scale-bounce animation
		var root := Control.new()
		root.position = Vector2(cx, cy)
		root.size     = Vector2(CARD_W, CARD_H)
		root.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)
		add_child(root)
		card_roots.append(root)

		# Card background
		var cbg := ColorRect.new()
		cbg.color    = CARD_BG
		cbg.position = Vector2.ZERO
		cbg.size     = Vector2(CARD_W, CARD_H)
		root.add_child(cbg)
		card_bgs.append(cbg)

		# Top color strip
		var strip := ColorRect.new()
		strip.color    = Color(bc.r, bc.g, bc.b, 0.80)
		strip.position = Vector2.ZERO
		strip.size     = Vector2(CARD_W, 5.0)
		root.add_child(strip)

		# Left accent bar (team color)
		var lbar := ColorRect.new()
		lbar.color    = Color(tc.r, tc.g, tc.b, 0.55)
		lbar.position = Vector2.ZERO
		lbar.size     = Vector2(3.0, CARD_H)
		root.add_child(lbar)

		# Number badge (circle approximated as small square with rounding via Label bg)
		var badge_bg := ColorRect.new()
		badge_bg.color    = Color(bc.r, bc.g, bc.b, 0.90)
		badge_bg.position = Vector2(CARD_W - 26.0, 6.0)
		badge_bg.size     = Vector2(20.0, 20.0)
		root.add_child(badge_bg)

		var badge_lbl := Label.new()
		badge_lbl.text     = str(i + 1)
		badge_lbl.position = Vector2(CARD_W - 26.0, 5.0)
		badge_lbl.size     = Vector2(20.0, 20.0)
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		badge_lbl.add_theme_font_size_override("font_size", 13)
		badge_lbl.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
		root.add_child(badge_lbl)

		# Card name
		var name_lbl := Label.new()
		name_lbl.position      = Vector2(5.0, 30.0)
		name_lbl.size          = Vector2(CARD_W - 10.0, CARD_H - 58.0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(name_lbl)
		card_names.append(name_lbl)

		# Elixir cost
		var cost_lbl := Label.new()
		cost_lbl.position = Vector2(5.0, CARD_H - 28.0)
		cost_lbl.size     = Vector2(CARD_W - 10.0, 26.0)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 18)
		cost_lbl.add_theme_color_override("font_color", ELIX_COL)
		root.add_child(cost_lbl)
		card_costs.append(cost_lbl)

		# Troop count badge (bottom-right)
		var cnt_lbl := Label.new()
		cnt_lbl.position = Vector2(CARD_W - 34.0, CARD_H - 44.0)
		cnt_lbl.size     = Vector2(30.0, 18.0)
		cnt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt_lbl.add_theme_font_size_override("font_size", 12)
		cnt_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		root.add_child(cnt_lbl)
		card_cnts.append(cnt_lbl)

		# Flash overlay (white, hidden normally)
		var flash := ColorRect.new()
		flash.color     = Color(1.0, 1.0, 1.0, 0.0)
		flash.position  = Vector2.ZERO
		flash.size      = Vector2(CARD_W, CARD_H)
		root.add_child(flash)
		card_flash.append(flash)

	if is_p1:
		_p1_card_root = card_roots; _p1_card_bg = card_bgs
		_p1_card_name = card_names; _p1_card_cost = card_costs
		_p1_card_cnt  = card_cnts;  _p1_card_flash = card_flash
	else:
		_p2_card_root = card_roots; _p2_card_bg = card_bgs
		_p2_card_name = card_names; _p2_card_cost = card_costs
		_p2_card_cnt  = card_cnts;  _p2_card_flash = card_flash

# ── Elixir bar ────────────────────────────────────────────────────────────────
func _build_elixir_bar(p: int, sec_x: float, tc: Color) -> void:
	var is_p1    := p == 0
	var SEG_N    := 10
	var num_w    := 42.0
	var bar_gap  := 4.0
	var bar_w    := SIDE_W - num_w - bar_gap - 10.0
	var seg_gap  := 3.0
	var seg_w    := (bar_w - seg_gap * (SEG_N - 1)) / SEG_N

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
	add_child(num)

	# Bar background
	var bar_bg := ColorRect.new()
	bar_bg.color    = Color(0.08, 0.02, 0.14)
	bar_bg.position = Vector2(bar_x, ELIX_Y + 3.0)
	bar_bg.size     = Vector2(bar_w, ELIX_H - 6.0)
	add_child(bar_bg)

	var segs: Array = []
	for s in range(SEG_N):
		var seg := ColorRect.new()
		seg.color    = Color(0.16, 0.05, 0.26)
		seg.position = Vector2(bar_x + s * (seg_w + seg_gap), ELIX_Y + 6.0)
		seg.size     = Vector2(seg_w, ELIX_H - 12.0)
		add_child(seg)
		segs.append(seg)

	if is_p1: _p1_segs = segs; _p1_elix_lbl = num
	else:     _p2_segs = segs; _p2_elix_lbl = num

# ── Update (called every frame from GameManager) ──────────────────────────────
func update_hud(p1_elixir: float, p2_elixir: float,
				p1_deck: Deck, p2_deck: Deck) -> void:
	_refresh_elixir(_p1_segs, _p1_elix_lbl, p1_elixir, 0)
	_refresh_elixir(_p2_segs, _p2_elix_lbl, p2_elixir, 1)
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
	var l_ids  := _p1_last_ids   if p == 0 else _p2_last_ids
	var l_aff  := _p1_last_aff   if p == 0 else _p2_last_aff

	for i in range(4):
		var card     := deck.hand[i]
		var cur_id   := card.card_id
		var afford   := elixir >= float(card.cost)

		# ── Card changed (was played) → flash white
		if l_ids[i] != "" and l_ids[i] != cur_id:
			_anim_card_play(flash[i], roots[i])
		l_ids[i] = cur_id

		# ── Just became affordable → green pulse
		if afford and not l_aff[i]:
			_anim_afford(roots[i])
		l_aff[i] = afford

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
	var nn   := _p1_next_name if p == 0 else _p2_next_name
	var nc   := _p1_next_cost if p == 0 else _p2_next_cost
	nn.text = deck.next_card.display_name
	nc.text = "◆ %d" % deck.next_card.cost

func _refresh_elixir(segs: Array, lbl: Label, value: float, p: int) -> void:
	lbl.text    = str(int(value))
	var filled  := int(value)
	var at_max  := value >= 9.9
	var last    := _p1_elix_int if p == 0 else _p2_elix_int

	# Pop-in animation for newly filled segments
	if filled > last:
		for s in range(last, mini(filled, segs.size())):
			_anim_seg_pop(segs[s])
	if p == 0: _p1_elix_int = filled
	else:      _p2_elix_int = filled

	for i in range(10):
		if i < filled:
			if at_max:
				var t := sin(Time.get_ticks_msec() * 0.006) * 0.5 + 0.5
				segs[i].color = ELIX_COL.lerp(Color(0.90, 0.10, 1.0), t)
			else:
				segs[i].color = ELIX_COL
		else:
			segs[i].color = Color(0.16, 0.05, 0.26)

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

func _anim_seg_pop(seg: ColorRect) -> void:
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
	if _double_elixir_lbl == null:
		return
	_double_elixir_lbl.visible = active
	_double_elixir_bg.visible  = active
	if active and (_de_tween == null or not _de_tween.is_running()):
		_de_tween = create_tween().set_loops()
		_de_tween.tween_property(_double_elixir_lbl, "modulate:a", 0.30, 0.45)
		_de_tween.tween_property(_double_elixir_lbl, "modulate:a", 1.0,  0.45)
	elif not active and _de_tween != null:
		_de_tween.kill()
		_de_tween = null
