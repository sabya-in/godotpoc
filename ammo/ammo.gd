extends RigidBody2D

export var speed = 6

var damage = 15
var steps = 180
var player_name
var rotateby
var i = 0

func _ready():
	randomize()
	set_as_toplevel(true)

func _process(delta):
	if(i<180):
		$Sprite.rotate(deg2rad(rotateby/steps))
		$CollisionShape2D.rotate(deg2rad(rotateby/steps))
		i=i+1
	pass

func _on_ammo_body_entered(body):
	if body.is_in_group('player'):
		body.damage(damage)
		var shooter = get_parent().find_node(player_name,true,false)
		if (shooter.name == body.name):
			shooter.total_score -= damage
		else:
			shooter.total_score += damage
	queue_free()
