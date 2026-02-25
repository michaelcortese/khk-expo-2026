extends Control
class_name ElixirBarWidget

@export var max_elixir: int = 10

@onready var segments: HBoxContainer = $Segments
@onready var pip: TextureRect = $PipIcon
@onready var value_label: Label = $ValueLabel

var current: float = 0.0

func _ready() -> void:
	# Ensure we have exactly max_elixir segments (in case you change it in the inspector).
	_ensure_segments()
	set_elixir(current)

func set_elixir(v: float) -> void:
	current = clamp(v, 0.0, float(max_elixir))
	_update_segments()
	_update_pip()
	_update_label()

func _ensure_segments() -> void:
	# If the scene already has the right number, do nothing.
	if segments.get_child_count() == max_elixir:
		return

	# Otherwise rebuild children.
	for c in segments.get_children():
		c.queue_free()

	for i in range(max_elixir):
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(0, 28)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.size_flags_vertical = Control.SIZE_FILL
		# Default visuals (you can replace with textures later)
		r.color = Color(0.75, 0.2, 1.0, 1.0)  # "filled" color; alpha will be adjusted
		segments.add_child(r)

func _update_segments() -> void:
	var filled := int(floor(current))
	for i in range(max_elixir):
		var seg := segments.get_child(i) as ColorRect
		seg.color.a = 1.0 if i < filled else 0.18

func _update_pip() -> void:
	# Pip shows exact amount (including fractions) by sliding along the segment row.
	# If you want integer-only, you can hide pip in the inspector.
	if pip == null or pip.visible == false:
		return

	# Defer until layout is valid
	if segments.size.x <= 0.0:
		call_deferred("_update_pip")
		return

	var t := current / float(max_elixir)  # 0..1
	var w := segments.size.x
	var x := t * w - pip.size.x * 0.5
	pip.position.x = clamp(x, 0.0, w - pip.size.x)
	# Place pip slightly above the segment row
	pip.position.y = -pip.size.y + 2

func _update_label() -> void:
	if value_label:
		value_label.text = str(int(floor(current)))
