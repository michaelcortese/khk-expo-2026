extends Control
class_name ElixirBarWidget

@export var max_elixir: int = 10

@onready var segments:    HBoxContainer = $Segments
@onready var pip:         TextureRect   = $PipIcon
@onready var value_label: Label         = $PipIcon/ValueLabel

var current: float      = 0.0
var _double_elixir: bool = false

# Colours
const COLOR_NORMAL := Color(0.75, 0.20, 1.00, 1.0)   # purple
const COLOR_DOUBLE := Color(1.00, 0.75, 0.10, 1.0)   # gold

func _ready() -> void:
	_ensure_segments()
	set_elixir(current)

func set_elixir(v: float) -> void:
	current = clamp(v, 0.0, float(max_elixir))
	_update_segments()
	_update_pip()
	_update_label()

## Call when double-elixir mode starts — turns segments gold.
func set_double_elixir_mode(active: bool) -> void:
	_double_elixir = active
	_update_segments()   # recolour immediately

func _ensure_segments() -> void:
	if segments.get_child_count() == max_elixir:
		return
	for c in segments.get_children():
		c.queue_free()
	for _i in range(max_elixir):
		var r := ColorRect.new()
		r.custom_minimum_size    = Vector2(0, 28)
		r.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
		r.size_flags_vertical    = Control.SIZE_FILL
		r.color                  = COLOR_NORMAL
		segments.add_child(r)

func _update_segments() -> void:
	var col    := COLOR_DOUBLE if _double_elixir else COLOR_NORMAL
	var filled := int(floor(current))
	for i in range(segments.get_child_count()):
		var seg := segments.get_child(i) as ColorRect
		if seg == null:
			continue
		seg.color   = col
		seg.color.a = 1.0 if i < filled else 0.18

func _update_pip() -> void:
	if pip == null or not pip.visible:
		return
	if segments.size.x <= 0.0:
		call_deferred("_update_pip")
		return
	var t := current / float(max_elixir)
	var w := segments.size.x
	var x := t * w - pip.size.x * 0.5
	pip.position.x = clamp(x, 0.0, w - pip.size.x)
	pip.position.y = -pip.size.y + 2

func _update_label() -> void:
	if value_label:
		value_label.text = str(int(floor(current)))
