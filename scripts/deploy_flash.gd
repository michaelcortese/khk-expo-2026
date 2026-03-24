# Expanding ring that plays at the cursor position when a card is deployed.
# Call start(world_pos, color) immediately after add_child().
extends Node2D

var _col:    Color = Color.WHITE
var _radius: float = 5.0

func start(world_pos: Vector2, col: Color) -> void:
	_col     = col
	position = world_pos
	var tw := create_tween()
	tw.tween_method(_set_r, 5.0, 42.0, 0.30)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.30)
	tw.tween_callback(queue_free)

func _set_r(r: float) -> void:
	_radius = r
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 24, _col, 2.5)
