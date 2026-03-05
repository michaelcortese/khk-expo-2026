class_name PlayerController
extends Node

## Emitted when player presses a card button. slot_index is 0-3.
signal card_played(slot_index: int, world_position: Vector2)

@export var player_index: int = 0      # 0 = P1, 1 = P2
@export var joy_device: int = 0        # Joystick device index
@export var cursor_speed: float = 350.0
@export var zone_min: Vector2 = Vector2(60, 30)
@export var zone_max: Vector2 = Vector2(490, 490)
@export var cursor_color: Color = Color(0.0, 1.0, 0.5, 0.85)

var cursor_position: Vector2

# Two Line2D arms forming a crosshair (Node2D-based, respects Camera2D)
var _cross_h: Line2D
var _cross_v: Line2D

# Keyboard fallback: P1 = WASD + ZXCV, P2 = Arrows + IJKL
var _kb_left: Key
var _kb_right: Key
var _kb_up: Key
var _kb_down: Key
var _kb_buttons: Array[Key] = []

func _ready() -> void:
	cursor_position = (zone_min + zone_max) * 0.5
	_register_input_actions()
	_build_cursor()
	_setup_keyboard_fallback()

func _register_input_actions() -> void:
	for i in range(4):
		var action := "p%d_card%d" % [player_index + 1, i + 1]
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.0)
		InputMap.action_erase_events(action)

		var ev := InputEventJoypadButton.new()
		ev.device = joy_device
		ev.button_index = i   # 0=South, 1=East, 2=West, 3=North
		InputMap.action_add_event(action, ev)

func _setup_keyboard_fallback() -> void:
	if player_index == 0:
		_kb_left  = KEY_A
		_kb_right = KEY_D
		_kb_up    = KEY_W
		_kb_down  = KEY_S
		_kb_buttons = [KEY_Z, KEY_X, KEY_C, KEY_V]
	else:
		_kb_left  = KEY_LEFT
		_kb_right = KEY_RIGHT
		_kb_up    = KEY_UP
		_kb_down  = KEY_DOWN
		_kb_buttons = [KEY_I, KEY_J, KEY_K, KEY_L]

func _build_cursor() -> void:
	var arm := 14.0
	var w := 3.0

	_cross_h = Line2D.new()
	_cross_h.width = w
	_cross_h.default_color = cursor_color
	_cross_h.add_point(Vector2(-arm, 0.0))
	_cross_h.add_point(Vector2(arm, 0.0))
	get_parent().add_child(_cross_h)

	_cross_v = Line2D.new()
	_cross_v.width = w
	_cross_v.default_color = cursor_color
	_cross_v.add_point(Vector2(0.0, -arm))
	_cross_v.add_point(Vector2(0.0, arm))
	get_parent().add_child(_cross_v)

	_cross_h.position = cursor_position
	_cross_v.position = cursor_position

func _process(delta: float) -> void:
	_move_cursor(delta)

func _input(event: InputEvent) -> void:
	# Joystick buttons
	for i in range(4):
		var action := "p%d_card%d" % [player_index + 1, i + 1]
		if event.is_action_pressed(action):
			card_played.emit(i, cursor_position)
			return

	# Keyboard fallback buttons
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			for i in range(_kb_buttons.size()):
				if ke.keycode == _kb_buttons[i]:
					card_played.emit(i, cursor_position)
					return

func _move_cursor(delta: float) -> void:
	var ax := Input.get_joy_axis(joy_device, JOY_AXIS_LEFT_X)
	var ay := Input.get_joy_axis(joy_device, JOY_AXIS_LEFT_Y)

	if abs(ax) < 0.18: ax = 0.0
	if abs(ay) < 0.18: ay = 0.0

	if Input.is_key_pressed(_kb_left):  ax -= 1.0
	if Input.is_key_pressed(_kb_right): ax += 1.0
	if Input.is_key_pressed(_kb_up):    ay -= 1.0
	if Input.is_key_pressed(_kb_down):  ay += 1.0

	cursor_position.x += ax * cursor_speed * delta
	cursor_position.y += ay * cursor_speed * delta
	cursor_position = cursor_position.clamp(zone_min, zone_max)

	if _cross_h: _cross_h.position = cursor_position
	if _cross_v: _cross_v.position = cursor_position
