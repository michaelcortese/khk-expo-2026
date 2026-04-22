# Gold star that pops up and floats away when a tower is destroyed.
# Call start(world_pos) immediately after add_child().
extends Node2D

func start(world_pos: Vector2) -> void:
	position = world_pos
	queue_redraw()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(3.2, 3.2), 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", world_pos.y - 72.0, 0.65)
	tw.tween_property(self, "modulate:a", 0.0, 0.65).set_delay(0.20)
	tw.set_parallel(false)
	tw.tween_callback(queue_free)

func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(-10, 10), "★",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1.0, 0.85, 0.0))
