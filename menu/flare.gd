extends RigidBody2D

var run = 0

func _ready():
	$AnimatedSprite.hide()
	pass

func _on_Timer_timeout():
	if run < 1:
		$AnimatedSprite.show()
		$Timer.wait_time = 1.5
	if run > 1:
		call_deferred("queue_free")
	run += 1
