extends Node

const P1_COL := Color(0.15, 0.65, 1.0)
const P2_COL := Color(1.0,  0.18, 0.18)
const GOLD   := Color(1.0,  0.85, 0.10)

func _ready() -> void:
	_apply_pixel_font()
	_build_ui()

func _apply_pixel_font() -> void:
	var font := load("res://assets/fonts_assets/pokemon_fire_red.ttf") as FontFile
	if font == null:
		return
	font.antialiasing          = TextServer.FONT_ANTIALIASING_NONE
	font.hinting               = TextServer.HINTING_NONE
	font.subpixel_positioning  = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps      = false
	ThemeDB.fallback_font      = font
	ThemeDB.fallback_font_size = 16

func _build_ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)

	# P1 side tint (left half)
	var p1_tint := ColorRect.new()
	p1_tint.color = Color(P1_COL.r, P1_COL.g, P1_COL.b, 0.07)
	p1_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p1_tint.size.x = 640
	cl.add_child(p1_tint)

	# P2 side tint (right half)
	var p2_tint := ColorRect.new()
	p2_tint.color = Color(P2_COL.r, P2_COL.g, P2_COL.b, 0.07)
	p2_tint.position = Vector2(640, 0)
	p2_tint.size = Vector2(640, 1024)
	cl.add_child(p2_tint)

	# Center divider
	var div := ColorRect.new()
	div.color = Color(1.0, 1.0, 1.0, 0.08)
	div.position = Vector2(638, 0)
	div.size = Vector2(4, 1024)
	cl.add_child(div)

	# Title
	var title := Label.new()
	title.text = "KHK ROYALE"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-240, 100)
	title.size = Vector2(480, 110)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", GOLD)
	cl.add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "2-Player Arcade"
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.position = Vector2(-160, 215)
	sub.size = Vector2(320, 44)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.90))
	cl.add_child(sub)

	# P1 panel
	_make_player_panel(cl, 0)
	# P2 panel
	_make_player_panel(cl, 1)

	# Press to start
	var prompt := Label.new()
	prompt.text = "PRESS ANY BUTTON TO START"
	prompt.set_anchors_preset(Control.PRESET_CENTER_TOP)
	prompt.position = Vector2(-240, 620)
	prompt.size = Vector2(480, 50)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 28)
	prompt.add_theme_color_override("font_color", Color.WHITE)
	cl.add_child(prompt)

	var tween := create_tween().set_loops()
	tween.tween_property(prompt, "modulate:a", 0.15, 0.7)
	tween.tween_property(prompt, "modulate:a", 1.0,  0.7)

func _make_player_panel(cl: CanvasLayer, p: int) -> void:
	var is_p1 := p == 0
	var col   := P1_COL if is_p1 else P2_COL
	var bx    := 60.0   if is_p1 else 660.0
	var by    := 300.0
	var bw    := 560.0
	var bh    := 280.0

	# Card
	var card := ColorRect.new()
	card.color    = Color(col.r, col.g, col.b, 0.12)
	card.position = Vector2(bx, by)
	card.size     = Vector2(bw, bh)
	cl.add_child(card)

	var border := ColorRect.new()
	border.color    = Color(col.r, col.g, col.b, 0.5)
	border.position = Vector2(bx, by)
	border.size     = Vector2(bw, 4)
	cl.add_child(border)

	var name_lbl := Label.new()
	name_lbl.text = "PLAYER 1" if is_p1 else "PLAYER 2"
	name_lbl.position = Vector2(bx, by + 12)
	name_lbl.size     = Vector2(bw, 52)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 38)
	name_lbl.add_theme_color_override("font_color", col)
	cl.add_child(name_lbl)

	var info := Label.new()
	info.text = "Joystick → Move cursor\nButtons 1-4 → Play cards\n\nKeyboard: WASD + Z X C V" if is_p1 \
			 else "Joystick → Move cursor\nButtons 1-4 → Play cards\n\nKeyboard: Arrows + I J K L"
	info.position = Vector2(bx + 20, by + 72)
	info.size     = Vector2(bw - 40, bh - 80)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cl.add_child(info)

func _input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventKey:
		pressed = (event as InputEventKey).pressed and not (event as InputEventKey).echo
	elif event is InputEventJoypadButton:
		pressed = (event as InputEventJoypadButton).pressed
	if pressed:
		get_tree().change_scene_to_file("res://game.tscn")
