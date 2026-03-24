class_name HUD
extends CanvasLayer

# ── Layout (1280 × 1024 screen) ───────────────────────────────────────────────
const SCREEN_W  := 1280.0
const SCREEN_H  := 1024.0
const PANEL_H   := 290.0
const PANEL_Y   := SCREEN_H - PANEL_H   # 734

const CENTER_W  := 64.0
const SIDE_W    := (SCREEN_W - CENTER_W) * 0.5   # 608

const CARD_W    := 108.0
const CARD_H    := 190.0
const CARD_PAD  := 6.0
const NEXT_W    := 78.0
const NEXT_H    := 172.0

const ELIX_H    := 36.0
const ELIX_Y    := PANEL_Y + PANEL_H - ELIX_H - 10.0

const ELIX_COL  := Color(0.55, 0.08, 0.85)
const P1_COL    := Color(0.15, 0.65, 1.0)
const P2_COL    := Color(1.0,  0.18, 0.18)

# ── Runtime refs ──────────────────────────────────────────────────────────────
var _p1_segs:      Array = []
var _p2_segs:      Array = []
var _p1_elix_lbl:  Label
var _p2_elix_lbl:  Label
var _p1_card_name: Array = []
var _p2_card_name: Array = []
var _p1_card_cost: Array = []
var _p2_card_cost: Array = []
var _p1_card_bg:   Array = []
var _p2_card_bg:   Array = []
var _p1_card_cnt:  Array = []   # troop count badges
var _p2_card_cnt:  Array = []
var _p1_next_name: Label
var _p2_next_name: Label
var _p1_next_cost: Label
var _p2_next_cost: Label
var _timer_lbl:         Label
var _p1_crown_lbl:      Label
var _p2_crown_lbl:      Label
var _double_elixir_bg:  ColorRect
var _double_elixir_lbl: Label
var _de_tween:          Tween

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
	bg.color    = Color(0.07, 0.07, 0.07, 0.97)
	bg.position = Vector2(0.0, PANEL_Y)
	bg.size     = Vector2(SCREEN_W, PANEL_H)
	add_child(bg)

func _build_timer() -> void:
	# Timer box
	var tbg := ColorRect.new()
	tbg.color    = Color(0.0, 0.0, 0.0, 0.88)
	tbg.position = Vector2(SCREEN_W * 0.5 - 72.0, 8.0)
	tbg.size     = Vector2(144.0, 48.0)
	add_child(tbg)

	_timer_lbl = Label.new()
	_timer_lbl.text     = "3:00"
	_timer_lbl.position = Vector2(SCREEN_W * 0.5 - 68.0, 13.0)
	_timer_lbl.size     = Vector2(136.0, 38.0)
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_lbl.add_theme_font_size_override("font_size", 30)
	_timer_lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(_timer_lbl)

	# P1 crown display — left of timer
	var p1_cbg := ColorRect.new()
	p1_cbg.color    = Color(0.0, 0.0, 0.0, 0.70)
	p1_cbg.position = Vector2(SCREEN_W * 0.5 - 72.0 - 112.0, 8.0)
	p1_cbg.size     = Vector2(108.0, 48.0)
	add_child(p1_cbg)

	_p1_crown_lbl = Label.new()
	_p1_crown_lbl.text     = "★  0"
	_p1_crown_lbl.position = Vector2(SCREEN_W * 0.5 - 72.0 - 112.0, 10.0)
	_p1_crown_lbl.size     = Vector2(108.0, 44.0)
	_p1_crown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_crown_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_p1_crown_lbl.add_theme_font_size_override("font_size", 22)
	_p1_crown_lbl.add_theme_color_override("font_color", P1_COL)
	add_child(_p1_crown_lbl)

	# P2 crown display — right of timer
	var p2_cbg := ColorRect.new()
	p2_cbg.color    = Color(0.0, 0.0, 0.0, 0.70)
	p2_cbg.position = Vector2(SCREEN_W * 0.5 + 72.0 + 4.0, 8.0)
	p2_cbg.size     = Vector2(108.0, 48.0)
	add_child(p2_cbg)

	_p2_crown_lbl = Label.new()
	_p2_crown_lbl.text     = "0  ★"
	_p2_crown_lbl.position = Vector2(SCREEN_W * 0.5 + 72.0 + 4.0, 10.0)
	_p2_crown_lbl.size     = Vector2(108.0, 44.0)
	_p2_crown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p2_crown_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_p2_crown_lbl.add_theme_font_size_override("font_size", 22)
	_p2_crown_lbl.add_theme_color_override("font_color", P2_COL)
	add_child(_p2_crown_lbl)

func _build_center_gem() -> void:
	var gbg := ColorRect.new()
	gbg.color    = Color(0.10, 0.04, 0.18)
	gbg.position = Vector2(SIDE_W, PANEL_Y)
	gbg.size     = Vector2(CENTER_W, PANEL_H)
	add_child(gbg)

	var gem := Label.new()
	gem.text     = "✦"
	gem.position = Vector2(SIDE_W + CENTER_W * 0.5 - 18.0, PANEL_Y + PANEL_H * 0.5 - 22.0)
	gem.size     = Vector2(36.0, 44.0)
	gem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gem.add_theme_font_size_override("font_size", 32)
	gem.add_theme_color_override("font_color", ELIX_COL)
	add_child(gem)

	# 2× elixir indicator — centered below the gem, hidden until active
	_double_elixir_bg = ColorRect.new()
	_double_elixir_bg.color    = Color(0.22, 0.05, 0.38)
	_double_elixir_bg.position = Vector2(SIDE_W - 2.0, PANEL_Y + PANEL_H * 0.5 + 30.0)
	_double_elixir_bg.size     = Vector2(CENTER_W + 4.0, 44.0)
	_double_elixir_bg.visible  = false
	add_child(_double_elixir_bg)

	_double_elixir_lbl = Label.new()
	_double_elixir_lbl.text     = "2×"
	_double_elixir_lbl.position = Vector2(SIDE_W - 2.0, PANEL_Y + PANEL_H * 0.5 + 30.0)
	_double_elixir_lbl.size     = Vector2(CENTER_W + 4.0, 44.0)
	_double_elixir_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_double_elixir_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_double_elixir_lbl.add_theme_font_size_override("font_size", 26)
	_double_elixir_lbl.add_theme_color_override("font_color", Color(0.90, 0.25, 1.0))
	_double_elixir_lbl.visible = false
	add_child(_double_elixir_lbl)

func _build_side(p: int) -> void:
	var is_p1 := p == 0
	var tc     := P1_COL if is_p1 else P2_COL
	var sec_x  := 0.0 if is_p1 else SIDE_W + CENTER_W

	# Top accent line
	var line := ColorRect.new()
	line.color    = tc
	line.position = Vector2(sec_x, PANEL_Y)
	line.size     = Vector2(SIDE_W, 4.0)
	add_child(line)

	# Subtle tint
	var tint := ColorRect.new()
	tint.color    = Color(tc.r, tc.g, tc.b, 0.07)
	tint.position = Vector2(sec_x, PANEL_Y + 4.0)
	tint.size     = Vector2(SIDE_W, PANEL_H - 4.0)
	add_child(tint)

	# P1 / P2 player label — anchored to outer edge of panel
	var player_lbl := Label.new()
	player_lbl.text = "P1" if is_p1 else "P2"
	player_lbl.position = Vector2(
			sec_x + (6.0 if is_p1 else SIDE_W - 46.0),
			PANEL_Y + 8.0)
	player_lbl.size     = Vector2(40.0, 32.0)
	player_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_lbl.add_theme_font_size_override("font_size", 24)
	player_lbl.add_theme_color_override("font_color", tc)
	add_child(player_lbl)

	# ── Next card ────────────────────────────────────────────────────────────
	var next_x: float
	var hand_x: float
	var PAD := 8.0

	if is_p1:
		next_x = sec_x + PAD
		hand_x = next_x + NEXT_W + PAD
	else:
		next_x = sec_x + SIDE_W - PAD - NEXT_W
		hand_x = sec_x + PAD

	var nl := Label.new()
	nl.text = "Up Next:"
	nl.position = Vector2(next_x, PANEL_Y + 8.0)
	nl.size     = Vector2(NEXT_W, 18.0)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.add_theme_font_size_override("font_size", 13)
	nl.add_theme_color_override("font_color", tc)
	add_child(nl)

	var nbg := ColorRect.new()
	nbg.color    = Color(0.16, 0.16, 0.16)
	nbg.position = Vector2(next_x, PANEL_Y + 28.0)
	nbg.size     = Vector2(NEXT_W, NEXT_H)
	add_child(nbg)

	var nborder := ColorRect.new()
	nborder.color    = Color(tc.r, tc.g, tc.b, 0.5)
	nborder.position = Vector2(next_x, PANEL_Y + 28.0)
	nborder.size     = Vector2(NEXT_W, 3.0)
	add_child(nborder)

	var nn := Label.new()
	nn.position      = Vector2(next_x + 2.0, PANEL_Y + 50.0)
	nn.size          = Vector2(NEXT_W - 4.0, NEXT_H - 40.0)
	nn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nn.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	nn.add_theme_font_size_override("font_size", 12)
	nn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	nn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(nn)

	var nc := Label.new()
	nc.position = Vector2(next_x + 2.0, PANEL_Y + 28.0 + NEXT_H - 22.0)
	nc.size     = Vector2(NEXT_W - 4.0, 22.0)
	nc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nc.add_theme_font_size_override("font_size", 15)
	nc.add_theme_color_override("font_color", ELIX_COL)
	add_child(nc)

	if is_p1:
		_p1_next_name = nn;  _p1_next_cost = nc
	else:
		_p2_next_name = nn;  _p2_next_cost = nc

	# ── 4 hand cards ─────────────────────────────────────────────────────────
	var keys_p1 := ["Z", "X", "C", "V"]
	var keys_p2 := ["I", "J", "K", "L"]
	var card_names: Array = []
	var card_costs: Array = []
	var card_bgs:   Array = []
	var card_cnts:  Array = []

	for i in range(4):
		var cx := hand_x + i * (CARD_W + CARD_PAD)
		var cy := PANEL_Y + 8.0

		var cbg := ColorRect.new()
		cbg.color    = Color(0.18, 0.18, 0.18)
		cbg.position = Vector2(cx, cy)
		cbg.size     = Vector2(CARD_W, CARD_H)
		add_child(cbg)
		card_bgs.append(cbg)

		var ctop := ColorRect.new()
		ctop.color    = Color(tc.r, tc.g, tc.b, 0.4)
		ctop.position = Vector2(cx, cy)
		ctop.size     = Vector2(CARD_W, 3.0)
		add_child(ctop)

		var kl := Label.new()
		kl.text = keys_p1[i] if is_p1 else keys_p2[i]
		kl.position = Vector2(cx + 4.0, cy + 4.0)
		kl.size     = Vector2(CARD_W - 8.0, 18.0)
		kl.add_theme_font_size_override("font_size", 13)
		kl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
		add_child(kl)

		var name_lbl := Label.new()
		name_lbl.position      = Vector2(cx + 4.0, cy + 26.0)
		name_lbl.size          = Vector2(CARD_W - 8.0, CARD_H - 46.0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(name_lbl)
		card_names.append(name_lbl)

		var cost_lbl := Label.new()
		cost_lbl.position = Vector2(cx + 4.0, cy + CARD_H - 22.0)
		cost_lbl.size     = Vector2(CARD_W - 8.0, 22.0)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 17)
		cost_lbl.add_theme_color_override("font_color", ELIX_COL)
		add_child(cost_lbl)
		card_costs.append(cost_lbl)

		# Troop count badge — bottom-right corner, only shown when count > 1
		var cnt_lbl := Label.new()
		cnt_lbl.position = Vector2(cx + CARD_W - 30.0, cy + CARD_H - 40.0)
		cnt_lbl.size     = Vector2(28.0, 20.0)
		cnt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt_lbl.add_theme_font_size_override("font_size", 12)
		cnt_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		add_child(cnt_lbl)
		card_cnts.append(cnt_lbl)

	if is_p1:
		_p1_card_name = card_names;  _p1_card_cost = card_costs
		_p1_card_bg   = card_bgs;    _p1_card_cnt  = card_cnts
	else:
		_p2_card_name = card_names;  _p2_card_cost = card_costs
		_p2_card_bg   = card_bgs;    _p2_card_cnt  = card_cnts

	# ── Elixir bar ───────────────────────────────────────────────────────────
	var num := Label.new()
	num.size = Vector2(38.0, 36.0)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	num.add_theme_font_size_override("font_size", 24)
	num.add_theme_color_override("font_color", ELIX_COL)

	var SEG_COUNT   := 10
	var num_w       := 44.0
	var bar_gap     := 4.0
	var bar_total   := SIDE_W - num_w - bar_gap - 8.0
	var seg_gap     := 2.0
	var seg_w       := (bar_total - seg_gap * (SEG_COUNT - 1)) / SEG_COUNT
	var bar_start_x: float
	var segments: Array = []

	if is_p1:
		num.position = Vector2(sec_x + 4.0, ELIX_Y)
		bar_start_x  = sec_x + num_w + bar_gap
	else:
		num.position = Vector2(sec_x + SIDE_W - num_w - 4.0, ELIX_Y)
		bar_start_x  = sec_x + 4.0
	add_child(num)

	var bar_bg := ColorRect.new()
	bar_bg.color    = Color(0.10, 0.03, 0.18)
	bar_bg.position = Vector2(bar_start_x, ELIX_Y + 2.0)
	bar_bg.size     = Vector2(bar_total, ELIX_H - 4.0)
	add_child(bar_bg)

	for s in range(SEG_COUNT):
		var seg := ColorRect.new()
		seg.color    = Color(0.18, 0.06, 0.28)
		seg.position = Vector2(bar_start_x + s * (seg_w + seg_gap), ELIX_Y + 5.0)
		seg.size     = Vector2(seg_w, ELIX_H - 10.0)
		add_child(seg)
		segments.append(seg)

	if is_p1:
		_p1_segs = segments;  _p1_elix_lbl = num
	else:
		_p2_segs = segments;  _p2_elix_lbl = num

# ── Update ────────────────────────────────────────────────────────────────────
func update_hud(p1_elixir: float, p2_elixir: float, p1_deck: Deck, p2_deck: Deck) -> void:
	_refresh_elixir(_p1_segs, _p1_elix_lbl, p1_elixir)
	_refresh_elixir(_p2_segs, _p2_elix_lbl, p2_elixir)
	for i in range(4):
		# Card names / costs
		_p1_card_name[i].text = p1_deck.hand[i].display_name
		_p1_card_cost[i].text = str(p1_deck.hand[i].cost)
		_p2_card_name[i].text = p2_deck.hand[i].display_name
		_p2_card_cost[i].text = str(p2_deck.hand[i].cost)

		# Troop count badges
		var p1_total := p1_deck.hand[i].troop_count + p1_deck.hand[i].secondary_count
		_p1_card_cnt[i].text = "×%d" % p1_total if p1_total > 1 else ""
		var p2_total := p2_deck.hand[i].troop_count + p2_deck.hand[i].secondary_count
		_p2_card_cnt[i].text = "×%d" % p2_total if p2_total > 1 else ""

		# Grey out cards the player can't afford
		var p1_afford := p1_elixir >= float(p1_deck.hand[i].cost)
		_p1_card_bg[i].color = Color(0.18, 0.18, 0.18) if p1_afford else Color(0.07, 0.07, 0.09)
		_p1_card_name[i].add_theme_color_override("font_color",
				Color.WHITE if p1_afford else Color(0.42, 0.42, 0.42))
		_p1_card_cost[i].add_theme_color_override("font_color",
				ELIX_COL if p1_afford else Color(0.32, 0.06, 0.50))

		var p2_afford := p2_elixir >= float(p2_deck.hand[i].cost)
		_p2_card_bg[i].color = Color(0.18, 0.18, 0.18) if p2_afford else Color(0.07, 0.07, 0.09)
		_p2_card_name[i].add_theme_color_override("font_color",
				Color.WHITE if p2_afford else Color(0.42, 0.42, 0.42))
		_p2_card_cost[i].add_theme_color_override("font_color",
				ELIX_COL if p2_afford else Color(0.32, 0.06, 0.50))

	_p1_next_name.text = p1_deck.next_card.display_name
	_p1_next_cost.text = str(p1_deck.next_card.cost)
	_p2_next_name.text = p2_deck.next_card.display_name
	_p2_next_cost.text = str(p2_deck.next_card.cost)

func _refresh_elixir(segs: Array, lbl: Label, value: float) -> void:
	lbl.text = str(int(value))
	var filled  := int(value)
	var at_max  := value >= 9.9
	for i in range(10):
		if i < filled:
			if at_max:
				# Pulse between purple and bright magenta when full
				var t := sin(Time.get_ticks_msec() * 0.006) * 0.5 + 0.5
				segs[i].color = ELIX_COL.lerp(Color(0.90, 0.10, 1.0), t)
			else:
				segs[i].color = ELIX_COL
		else:
			segs[i].color = Color(0.18, 0.06, 0.28)

# ── Crowns ────────────────────────────────────────────────────────────────────
func set_crowns(p1: int, p2: int) -> void:
	if _p1_crown_lbl:
		_p1_crown_lbl.text = "★  %d" % p1
	if _p2_crown_lbl:
		_p2_crown_lbl.text = "%d  ★" % p2

# ── Timer ─────────────────────────────────────────────────────────────────────
# phase: 0 = REGULAR, 1 = OVERTIME, 2 = SUDDEN_DEATH
func set_timer(remaining: float, phase: int) -> void:
	match phase:
		0:  # REGULAR
			_timer_lbl.add_theme_font_size_override("font_size", 30)
			var mins := int(remaining) / 60
			var secs := int(remaining) % 60
			_timer_lbl.text = "%d:%02d" % [mins, secs]
			if remaining < 60.0:
				_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.0))
			else:
				_timer_lbl.add_theme_color_override("font_color", Color.WHITE)
		1:  # OVERTIME
			_timer_lbl.add_theme_font_size_override("font_size", 22)
			var mins := int(remaining) / 60
			var secs := int(remaining) % 60
			_timer_lbl.text = "OT %d:%02d" % [mins, secs]
			_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.0))
		2:  # SUDDEN DEATH
			_timer_lbl.add_theme_font_size_override("font_size", 15)
			_timer_lbl.text = "SUDDEN\nDEATH"
			_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))

# ── 2× Elixir indicator ───────────────────────────────────────────────────────
func set_double_elixir(active: bool) -> void:
	if _double_elixir_lbl == null:
		return
	_double_elixir_lbl.visible = active
	_double_elixir_bg.visible  = active
	if active and (_de_tween == null or not _de_tween.is_running()):
		_de_tween = create_tween().set_loops()
		_de_tween.tween_property(_double_elixir_lbl, "modulate:a", 0.35, 0.45)
		_de_tween.tween_property(_double_elixir_lbl, "modulate:a", 1.0,  0.45)
	elif not active and _de_tween != null:
		_de_tween.kill()
		_de_tween = null
