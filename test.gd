extends Node2D
func _ready() -> void:
	print("TEST SCENE WORKS")
	var f := FileAccess.open("user://debug.txt", FileAccess.WRITE)
	if f:
		f.store_string("ready fired\n")
		f.close()
