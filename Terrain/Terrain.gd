extends Node

export var slice = 40
export var num_hills = 3
export var hill_range = 80
#export (PackedScene) var player

var height
var start_y
var _player
var terrain = Array()
var texture = preload("res://grass.png")
var screensize
var player_scores 

func _ready():
	$Panel.hide()

func add_hills(start_y,height,screensize):
	randomize()
	terrain = Array()
	terrain.append(Vector2(0, start_y))
	var hill_width = screensize.x / num_hills
	var hill_slices = hill_width / slice
	var start = terrain[-1]
	var poly = PoolVector2Array()
	for i in range(num_hills):
		start.y -= height
		for j in range(0, hill_slices):
			var hill_point = Vector2()
			hill_point.x = start.x + j * slice + hill_width * i
			hill_point.y = start.y + height * cos(2 * PI / hill_slices * j)
			terrain.append(hill_point)
			poly.append(hill_point)
		start.y += height
	var shape = CollisionPolygon2D.new()
	var ground = Polygon2D.new()
	$StaticBody2D.add_child(shape)
	poly.append(Vector2(terrain[-1].x, screensize.y))
	poly.append(Vector2(start.x, screensize.y))
	var poly_colliding = poly
	poly_colliding[0] = Vector2(0,100)
	poly_colliding[-3] = Vector2(poly[-3].x,100)
	shape.polygon = poly_colliding
	ground.polygon = poly_colliding
	ground.texture = texture
	add_child(ground)
