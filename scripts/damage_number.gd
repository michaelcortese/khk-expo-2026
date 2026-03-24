# Floating damage number that rises and fades in world space.
# Call setup(amount, world_pos) immediately after add_child().
extends Node2D

var _text:      String = ""
var _font_size: int    = 16
var _color:     Color  = Color(1.0, 0.92, 0.12)

func setup(amount: int, world_pos: Vector2) -> void:
	_text    = str(amount)
	position = world_pos
	queue_redraw()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", world_pos.y - 38.0, 0.55)
	tw.tween_property(self, "modulate:a", 0.0,                0.55)
	tw.set_parallel(false)
	tw.tween_callback(queue_free)

func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(0, 0), _text,
			HORIZONTAL_ALIGNMENT_CENTER, -1, _font_size, _color)
