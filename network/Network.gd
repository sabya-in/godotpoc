extends Node

const DEFAULT_IP = '127.0.0.1'
const DEFAULT_PORT = 1995
const MAX_PLAYERS = 4

var players = { }
var self_data = { name = '', position = Vector2(240, 80) }
sync var grass_loc_x = Array()
sync var grass_loc_y = Array()

signal player_disconnected
signal server_disconnected
signal game_over

var hill_range = 100
var screensize
var start_y
var height

func _ready():
	randomize()
	start_y = randi()
	height = randi()
	rset_config("start_y",MultiplayerAPI.RPC_MODE_REMOTE)
	rset_config("height",MultiplayerAPI.RPC_MODE_REMOTE)
	rset_config("screensize",MultiplayerAPI.RPC_MODE_REMOTE)
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('network_peer_connected', self, '_on_player_connected')

func create_server(player_nickname):
	screensize = Vector2(4094,640)
	start_y = get_viewport().get_visible_rect().size.y * 3/4 + (-hill_range + start_y % hill_range*2)
	height = height % hill_range
	self_data.name = player_nickname
	players[1] = self_data
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)

func connect_to_server(player_nickname):
	self_data.name = player_nickname
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(DEFAULT_IP, DEFAULT_PORT)
	get_tree().set_network_peer(peer)
	get_tree().connect('connected_to_server', self, '_connected_to_server')

func _connected_to_server():
	var local_player_id = get_tree().get_network_unique_id() 
	players[local_player_id] = self_data
	rpc('_send_player_info', local_player_id, self_data)

func _on_player_disconnected(id):
	players.erase(id)

func _on_player_connected(connected_player_id):
	print("connected player - ",connected_player_id)
	var local_player_id = get_tree().get_network_unique_id()
	print("connected to - ",local_player_id)
	if not(get_tree().is_network_server()):
		rpc_id(1, '_request_player_info', local_player_id, connected_player_id)
		if (connected_player_id == 1):
			rpc_id(1, 'terrain_seed_set')

remote func _request_player_info(request_from_id, player_id):
	if get_tree().is_network_server():
		rpc_id(request_from_id, '_send_player_info', player_id, players[player_id])

remote func _send_player_info(id, info):
	players[id] = info
	var new_player = load('res://MRL/Runner.tscn').instance()
	new_player.name = str(id)
	new_player.set_network_master(id)
	$'/root/Game/'.add_child(new_player)
	new_player.init(info.name, info.position, true)

func update_position(id, position):
	players[id].position = position

remote func terrain_seed_set():
	if is_network_master():
		rset("start_y",start_y)
		rset("height",height)
		rset("screensize",screensize)
		rset("grass_loc_x",grass_loc_x)
		rset("grass_loc_y",grass_loc_y)
		rpc("_load_game")

remote func _load_game():
	var new_terrain = preload('res://Terrain/Terrain.tscn').instance()
	new_terrain.add_hills(start_y,height,screensize)
	add_child(new_terrain)
	print(len(grass_loc_x))
	for agrass in len(grass_loc_x):
		randomize()
		var grasscamo = preload("res://menu/grasscamo.tscn").instance()
		grasscamo.global_position.x = grass_loc_x[agrass]
		grasscamo.global_position.y = grass_loc_y[agrass]
		grasscamo.name = "grass" + str(randf())
		add_child(grasscamo)

