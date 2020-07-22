extends RigidBody2D

#var release = false
#
#
#func _ready():
#	mode = RigidBody2D.MODE_STATIC
#
#func _process(delta):
#	if not release:
#		global_position = Vector2(get_viewport().get_mouse_position().x,80)
#
#func _input(event):
#	if (event is InputEventMouseButton) and (event.is_pressed()):
#		mode = RigidBody2D.MODE_RIGID
#		global_position = Vector2(get_viewport().get_mouse_position().x,80)
#		release = true
