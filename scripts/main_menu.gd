extends Node

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)

	var title := Label.new()
	title.text = "KHK ROYALE"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-200, 120)
	title.size = Vector2(400, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	cl.add_child(title)

	var sub := Label.new()
	sub.text = "2-Player Arcade"
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.position = Vector2(-150, 220)
	sub.size = Vector2(300, 50)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	cl.add_child(sub)

	var prompt := Label.new()
	prompt.text = "PRESS ANY BUTTON TO START"
	prompt.set_anchors_preset(Control.PRESET_CENTER_TOP)
	prompt.position = Vector2(-200, 360)
	prompt.size = Vector2(400, 50)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 26)
	prompt.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	cl.add_child(prompt)

	# Pulse the prompt label
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(prompt, "modulate:a", 0.15, 0.7)
	tween.tween_property(prompt, "modulate:a", 1.0,  0.7)

	var p1 := Label.new()
	p1.text = "P1: Blue\nWASD + Z X C V"
	p1.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p1.position = Vector2(-340, 450)
	p1.size = Vector2(260, 80)
	p1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p1.add_theme_font_size_override("font_size", 18)
	p1.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	cl.add_child(p1)

	var p2 := Label.new()
	p2.text = "P2: Red\nArrows + I J K L"
	p2.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p2.position = Vector2(80, 450)
	p2.size = Vector2(260, 80)
	p2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p2.add_theme_font_size_override("font_size", 18)
	p2.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	cl.add_child(p2)

func _input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventKey:
		pressed = (event as InputEventKey).pressed and not (event as InputEventKey).echo
	elif event is InputEventJoypadButton:
		pressed = (event as InputEventJoypadButton).pressed
	if pressed:
		get_tree().change_scene_to_file("res://game.tscn")
