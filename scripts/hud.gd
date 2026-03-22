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
var _p1_next_name: Label
var _p2_next_name: Label
var _p1_next_cost: Label
var _p2_next_cost: Label
var _timer_lbl:    Label
var _elapsed:      float = 0.0

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

	for i in range(4):
		var cx := hand_x + i * (CARD_W + CARD_PAD)
		var cy := PANEL_Y + 8.0

		var cbg := ColorRect.new()
		cbg.color    = Color(0.18, 0.18, 0.18)
		cbg.position = Vector2(cx, cy)
		cbg.size     = Vector2(CARD_W, CARD_H)
		add_child(cbg)

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

	if is_p1:
		_p1_card_name = card_names;  _p1_card_cost = card_costs
	else:
		_p2_card_name = card_names;  _p2_card_cost = card_costs

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
		_p1_card_name[i].text = p1_deck.hand[i].display_name
		_p1_card_cost[i].text = str(p1_deck.hand[i].cost)
		_p2_card_name[i].text = p2_deck.hand[i].display_name
		_p2_card_cost[i].text = str(p2_deck.hand[i].cost)
	_p1_next_name.text = p1_deck.next_card.display_name
	_p1_next_cost.text = str(p1_deck.next_card.cost)
	_p2_next_name.text = p2_deck.next_card.display_name
	_p2_next_cost.text = str(p2_deck.next_card.cost)

func _refresh_elixir(segs: Array, lbl: Label, value: float) -> void:
	lbl.text = str(int(value))
	var filled := int(value)
	for i in range(10):
		segs[i].color = ELIX_COL if i < filled else Color(0.18, 0.06, 0.28)

# ── Timer ─────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	_elapsed += delta
	var remaining := maxf(0.0, 180.0 - _elapsed)
	var mins := int(remaining) / 60
	var secs := int(remaining) % 60
	_timer_lbl.text = "%d:%02d" % [mins, secs]
