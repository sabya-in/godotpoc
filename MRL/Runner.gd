extends RigidBody2D

export var rotation_step = 0.01

var health = 100
var health_refil = 5
var damage_randomness = 5
var total_score = 0
var players_alive

slave var slave_launcher_angle
slave var slave_linear_velocity
slave var slave_position

func _ready():
	if not is_network_master():
		$camo.hide()
		$flare.hide()
		$repair.hide()
		$weapon.hide()
	randomize()
	update_health()

func update_health():
	var healthbar = $Control/healthbar
	if health < 80:
		healthbar.tint_progress = Color( 0.18, 0.55, 0.34, 1 )
	if health < 60:
		healthbar.tint_progress = Color( 0.5, 0.5, 0, 1 )
	if health < 40:
		healthbar.tint_progress = Color( 1, 0.27, 0, 1 )
	if health < 20:
		healthbar.tint_progress = Color( 0.5, 0, 0, 1 )
	healthbar.value = health

func init(nickname, start_position, is_slave):
	var l = get_node("/root/Network")
	$name.text = nickname
	global_position = start_position
	#if is_slave:
		#sprite for other players
		#$Sprite.texture = load("res://MRL/Runner.tscn")

func _process(_delta):
	#print(Network.grass_loc)
	if Input:
		if is_network_master():
			$Camera2D.current = true
			if Input.is_action_pressed("ui_up"):
				if($Launcher.rotation_degrees >= (-85+114.60*rotation_step)):
					$Launcher.rotate(-rotation_step)
					$colliderlauncher.rotate(-rotation_step)
			if Input.is_action_pressed("ui_down"):
				if($Launcher.rotation_degrees <= (-12-114.60*rotation_step)):
					$Launcher.rotate(rotation_step)
					$colliderlauncher.rotate(-rotation_step)
			if Input.is_action_just_released("ui_accept"):
				rpc('fire',($Launcher/blastpoint.global_position - $Launcher.global_position),$Launcher/blastpoint.global_position,$Launcher.global_rotation_degrees,rand_range(-damage_randomness,damage_randomness),name)
			rset_unreliable("slave_launcher_angle",$Launcher.global_rotation)
		else:
			$Launcher.global_rotation = slave_launcher_angle
			$colliderlauncher.global_rotation = slave_launcher_angle
	$Control/score.text = str(total_score)

func _integrate_forces(state):
	if Input:
		if is_network_master():
			sleeping = false
			if (state.get_contact_count() && Input.is_action_pressed("ui_right")):
					set_friction(0.2)
					linear_velocity = Vector2(80,20)
			if (state.get_contact_count() && Input.is_action_pressed("ui_left")):
					set_friction(0.2)
					linear_velocity = Vector2(-80,20)
			if ((not state.get_contact_count()) && Input.is_action_pressed("ui_right")):
					set_friction(0.2)
					linear_velocity = Vector2(80,40)
			if ((not state.get_contact_count()) && Input.is_action_pressed("ui_left")):
					set_friction(0.2)
					linear_velocity = Vector2(-80,40)
			rset_unreliable("slave_linear_velocity",linear_velocity)
			rset_unreliable("slave_position",global_position)
		else:
			sleeping = false
			set_friction(0.2)
			linear_velocity = slave_linear_velocity
		if get_tree().is_network_server():
			Network.update_position(int(name), position)

sync func fire(launch_vector,launch_position,launcher_angle,damage_randomness,player_name):
	var ammo = preload("res://ammo/ammo.tscn").instance()
	ammo.rotateby = -(2*launcher_angle) if (launcher_angle>-90) else 2*(abs(launcher_angle)-180)
	get_parent().add_child(ammo)
	ammo.position = launch_position
	ammo.global_rotation_degrees = launcher_angle
	ammo.damage += damage_randomness
	ammo.linear_velocity = launch_vector*(ammo.speed)
	ammo.player_name = player_name
	ammo.name = 'ammo'+str(name)

func damage(damage):
	health = health - damage
	if health < 0:
		rpc('take_down')
	update_health()

sync func take_down():
	var players = get_tree().get_nodes_in_group('player')
	print(get_node("name").text + " Lost!!")
	if(len(players) <= 2):
		for aplayer in players:
			if not (aplayer.name == name):
				get_parent().check_winner(aplayer.get_node("name").text,aplayer.total_score,get_node("name").text,total_score)
				print(aplayer.get_node("name").text + " Won!!")
	else:
		for aplayer in players:
			if (aplayer.name == name):
				print(aplayer.name + " Lost!!")
	call_deferred('queue_free')

func _on_camo_button_down():
	if is_network_master():
		randomize()
		var grasscamo = preload("res://menu/grasscamo.tscn").instance()
		#grasscamo.release = false
		grasscamo.name = "grass" + str(randf())
		grasscamo.global_position = Vector2(global_position.x,global_position.y - 100)
		Network.grass_loc_x.append(global_position.x)
		Network.grass_loc_y.append(global_position.y)
		get_parent().add_child(grasscamo)
		rpc("camo_sync",global_position)
		$camo.release_focus()

func _on_flare_button_down():
	if is_network_master():
		rpc('flare_button_down_sync',global_position,global_rotation_degrees)
		var flare
		for i in range(1,18,1):
			flare = preload("res://menu/flare.tscn").instance()
			flare.global_position = global_position
			flare.linear_velocity = Vector2(100,0).rotated(deg2rad(-i*10+global_rotation_degrees))
			flare.name = "flare" + str(i)
			get_parent().add_child(flare)
			$flare.release_focus()

func _on_repair_button_down():
	if is_network_master():
		print("hit")
		if health < 80 and health_refil > 0:
			health = health*1.2
			health_refil -= 1
			rset("health",health)
			rset("health_refil",health_refil)
	update_health()
	$repair.release_focus()
	pass

sync func flare_button_down_sync(flare_pos,flare_angle):
	if not is_network_master():
		var flare
		for i in range(1,18,1):
			flare = preload("res://menu/flare.tscn").instance()
			flare.global_position = flare_pos
			flare.linear_velocity = Vector2(100,0).rotated(deg2rad(-i*10+flare_angle))
			flare.name = "flare" + str(i)
			get_parent().add_child(flare)

sync func camo_sync(loc):
	if not is_network_master():
		var grasscamo = preload("res://menu/grasscamo.tscn").instance()
		grasscamo.global_position = Vector2(loc.x,loc.y - 100)
		grasscamo.name = "grass" + str(randf())
		get_parent().add_child(grasscamo)
