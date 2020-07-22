extends Node

var players

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('server_disconnected', self, '_on_server_disconnected')
	get_tree().connect("connection_failed", self, "_connected_fail")
	
	var l = get_node("/root/Network")
	var new_terrain = preload("res://Terrain/Terrain.tscn").instance()
	new_terrain.add_hills(l.start_y,l.height,l.screensize)
	add_child(new_terrain)
	var new_player = preload("res://MRL/Runner.tscn").instance()
	new_player.name = str(get_tree().get_network_unique_id())
	new_player.set_network_master(get_tree().get_network_unique_id())
	add_child(new_player)
	var info = Network.self_data
	print("Server",info.position)
	new_player.init(info.name, info.position, false)

func _on_player_disconnected(id):
	get_node(str(id)).queue_free()

func _on_server_disconnected():
	get_tree().change_scene("res://network/menu.tscn")

func _on_connected_fail():
	get_tree().change_scene("res://network/menu.tscn")

func check_winner(winner,score_w,challenger,score_c):
	$AcceptDialog/container/winner.text = str(winner) + " Won!! scoring " + str(score_w)
	$AcceptDialog/container/challenger.text = str(challenger) + " Lost!! scoring " + str(score_c)
	$AcceptDialog.show()

func _on_AcceptDialog_confirmed():
	get_tree().change_scene("res://network/menu.tscn")
