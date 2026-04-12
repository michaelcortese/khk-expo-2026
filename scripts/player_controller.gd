class_name PlayerController
extends Node

## Emitted when a card button is pressed. slot_index = 0-3.
signal card_played(slot_index: int, world_position: Vector2)

var player_index: int    = 0
var joy_device: int      = 0
var cursor_speed: float  = 350.0
var zone_min: Vector2    = Vector2(60,  0)
var zone_max: Vector2    = Vector2(490, 480)
var cursor_color: Color  = Color(0.0, 0.5, 1.0, 0.9)

var cursor_position: Vector2
var _extra_zones: Array[Rect2] = []

var _cross_h: Line2D
var _cross_v: Line2D

# Keyboard fallback
var _kb_left:    Key
var _kb_right:   Key
var _kb_up:      Key
var _kb_down:    Key
var _kb_buttons: Array[Key] = []

func _ready() -> void:
	cursor_position = (zone_min + zone_max) * 0.5
	_register_joy_actions()
	_setup_keyboard()
	_build_cursor()

func _register_joy_actions() -> void:
	for i in range(4):
		var action := "p%d_card%d" % [player_index + 1, i + 1]
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.0)
		InputMap.action_erase_events(action)
		var ev := InputEventJoypadButton.new()
		ev.device       = joy_device
		ev.button_index = i   # 0=South 1=East 2=West 3=North
		InputMap.action_add_event(action, ev)

func _setup_keyboard() -> void:
	if player_index == 0:
		_kb_left  = KEY_A;     _kb_right = KEY_D
		_kb_up    = KEY_W;     _kb_down  = KEY_S
		_kb_buttons = [KEY_Z, KEY_X, KEY_C, KEY_V]
	else:
		_kb_left  = KEY_LEFT;  _kb_right = KEY_RIGHT
		_kb_up    = KEY_UP;    _kb_down  = KEY_DOWN
		_kb_buttons = [KEY_I, KEY_J, KEY_K, KEY_L]

func _build_cursor() -> void:
	var arm := 14.0
	var w   := 2.5

	_cross_h = Line2D.new()
	_cross_h.width         = w
	_cross_h.default_color = cursor_color
	_cross_h.add_point(Vector2(-arm, 0.0))
	_cross_h.add_point(Vector2( arm, 0.0))
	get_parent().add_child(_cross_h)

	_cross_v = Line2D.new()
	_cross_v.width         = w
	_cross_v.default_color = cursor_color
	_cross_v.add_point(Vector2(0.0, -arm))
	_cross_v.add_point(Vector2(0.0,  arm))
	get_parent().add_child(_cross_v)

	_cross_h.position = cursor_position
	_cross_v.position = cursor_position

	# Draw the main deploy zone outline
	_make_zone_outline(Rect2(zone_min, zone_max - zone_min))

func _process(delta: float) -> void:
	_move_cursor(delta)

func _input(event: InputEvent) -> void:
	# Joystick buttons
	for i in range(4):
		var action := "p%d_card%d" % [player_index + 1, i + 1]
		if event.is_action_pressed(action):
			card_played.emit(i, cursor_position)
			return

	# Keyboard fallback
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			for i in range(_kb_buttons.size()):
				if ke.keycode == _kb_buttons[i]:
					card_played.emit(i, cursor_position)
					return

## Unlock a new rectangle the cursor can enter (called when an enemy tower dies).
func add_zone(rect: Rect2) -> void:
	_extra_zones.append(rect)
	_make_zone_outline(rect)

func _make_zone_outline(rect: Rect2) -> void:
	var ol := Line2D.new()
	ol.width         = 1.5
	ol.default_color = Color(cursor_color.r, cursor_color.g, cursor_color.b, 0.25)
	ol.add_point(rect.position)
	ol.add_point(Vector2(rect.end.x, rect.position.y))
	ol.add_point(rect.end)
	ol.add_point(Vector2(rect.position.x, rect.end.y))
	ol.add_point(rect.position)
	get_parent().add_child(ol)

func _in_any_zone(pos: Vector2) -> bool:
	if pos.x >= zone_min.x and pos.x <= zone_max.x \
			and pos.y >= zone_min.y and pos.y <= zone_max.y:
		return true
	for z in _extra_zones:
		if z.has_point(pos):
			return true
	return false

func _clamp_to_zones(pos: Vector2) -> Vector2:
	if _in_any_zone(pos):
		return pos
	# Snap to nearest valid point across all zones
	var best := Vector2(clampf(pos.x, zone_min.x, zone_max.x),
						clampf(pos.y, zone_min.y, zone_max.y))
	for z in _extra_zones:
		var candidate := Vector2(clampf(pos.x, z.position.x, z.end.x),
								 clampf(pos.y, z.position.y, z.end.y))
		if pos.distance_to(candidate) < pos.distance_to(best):
			best = candidate
	return best

func _move_cursor(delta: float) -> void:
	var ax := Input.get_joy_axis(joy_device, JOY_AXIS_LEFT_X)
	var ay := Input.get_joy_axis(joy_device, JOY_AXIS_LEFT_Y)

	if abs(ax) < 0.18: ax = 0.0
	if abs(ay) < 0.18: ay = 0.0
	ax = -ax   # invert joystick X so left = left
	ay = -ay   # invert joystick Y so up = up

	if Input.is_key_pressed(_kb_left):  ax -= 1.0
	if Input.is_key_pressed(_kb_right): ax += 1.0
	if Input.is_key_pressed(_kb_up):    ay -= 1.0
	if Input.is_key_pressed(_kb_down):  ay += 1.0

	var desired := cursor_position + Vector2(ax, ay) * cursor_speed * delta
	cursor_position = _clamp_to_zones(desired)

	if _cross_h: _cross_h.position = cursor_position
	if _cross_v: _cross_v.position = cursor_position
