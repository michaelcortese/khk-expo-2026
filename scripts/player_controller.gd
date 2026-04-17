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

var _cursor_sprite:      Sprite2D = null
var _cursor_frames:      Array    = []
var _cursor_cur_frame:   int      = 0
var _cursor_frame_timer: float    = 0.0
const CURSOR_FRAME_INTERVAL := 0.28

# Per-slot debounce: prevents double-fire when a physical button is slow to rise
const CARD_DEBOUNCE_SEC := 0.35
var _card_cooldown: Array[float] = [0.0, 0.0, 0.0, 0.0]

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
	# Primary face buttons identical for both controllers: physical 1-4 → 3,1,0,2
	var primary_btns := [3, 1, 0, 2]

	# Secondary (physical 5-8) differs per controller:
	# P1 device 0: btn9, axis4, btn10, axis5
	# P2 device 1: btn9, btn10, axis4, axis5
	var secondary_btns: Array
	var secondary_axes: Array
	if joy_device == 0:
		secondary_btns = [9,  -1,  10,  -1]
		secondary_axes = [-1,  4,  -1,   5]
	else:
		secondary_btns = [9,  10,  -1,  -1]
		secondary_axes = [-1, -1,   4,   5]

	for i in range(4):
		var action := "p%d_card%d" % [player_index + 1, i + 1]
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.0)
		InputMap.action_erase_events(action)

		# Primary face button
		var ev := InputEventJoypadButton.new()
		ev.device       = joy_device
		ev.button_index = primary_btns[i]
		InputMap.action_add_event(action, ev)

		# Secondary: digital button or analog trigger
		if secondary_btns[i] >= 0:
			var ev2 := InputEventJoypadButton.new()
			ev2.device       = joy_device
			ev2.button_index = secondary_btns[i]
			InputMap.action_add_event(action, ev2)
		else:
			var ev2 := InputEventJoypadMotion.new()
			ev2.device     = joy_device
			ev2.axis       = secondary_axes[i]
			ev2.axis_value = 0.5
			InputMap.action_add_event(action, ev2)

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
	var prefix := "blue" if player_index == 0 else "red"
	_cursor_frames = [
		load("res://assets/hitpoints_assets/%s_cursor_frame1.png" % prefix) as Texture2D,
		load("res://assets/hitpoints_assets/%s_cursor_frame2.png" % prefix) as Texture2D,
	]
	_cursor_sprite                = Sprite2D.new()
	_cursor_sprite.texture        = _cursor_frames[0]
	_cursor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_cursor_sprite.scale          = Vector2(2.0, 2.0)
	_cursor_sprite.position       = cursor_position
	get_parent().add_child(_cursor_sprite)

	# Deploy zone outline — extend to the outer screen edge for each side
	var outline_min := zone_min
	var outline_max := zone_max
	if player_index == 0:
		outline_min.x = -200.0   # extend to left screen edge
	else:
		outline_max.x = 1200.0   # extend to right screen edge
	_make_zone_outline(Rect2(outline_min, outline_max - outline_min))

func _process(delta: float) -> void:
	for i in range(4):
		if _card_cooldown[i] > 0.0:
			_card_cooldown[i] -= delta
	_move_cursor(delta)
	# Animate cursor frames
	if _cursor_sprite != null and _cursor_frames.size() == 2:
		_cursor_frame_timer += delta
		if _cursor_frame_timer >= CURSOR_FRAME_INTERVAL:
			_cursor_frame_timer  -= CURSOR_FRAME_INTERVAL
			_cursor_cur_frame     = 1 - _cursor_cur_frame
			_cursor_sprite.texture = _cursor_frames[_cursor_cur_frame]

func _input(event: InputEvent) -> void:
	# Joystick buttons
	for i in range(4):
		var action := "p%d_card%d" % [player_index + 1, i + 1]
		if event.is_action_pressed(action):
			if _card_cooldown[i] > 0.0:
				return
			_card_cooldown[i] = CARD_DEBOUNCE_SEC
			card_played.emit(i, cursor_position)
			return

	# Keyboard fallback
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			for i in range(_kb_buttons.size()):
				if ke.keycode == _kb_buttons[i]:
					if _card_cooldown[i] > 0.0:
						return
					_card_cooldown[i] = CARD_DEBOUNCE_SEC
					card_played.emit(i, cursor_position)
					return

## Unlock a new rectangle the cursor can enter (called when an enemy tower dies).
func add_zone(rect: Rect2) -> void:
	_extra_zones.append(rect)
	_make_zone_outline(rect)

func _make_zone_outline(rect: Rect2) -> void:
	var ol := Line2D.new()
	ol.width         = 4.0
	ol.default_color = Color(cursor_color.r, cursor_color.g, cursor_color.b, 0.80)
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

	if _cursor_sprite: _cursor_sprite.position = cursor_position
