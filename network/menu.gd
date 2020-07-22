extends Control

var _player_name = ""
var ip = '127.0.0.1'

func _on_name_text_changed(new_text):
	_player_name = new_text

func _on_join_pressed():
	ip = $hostname.text
	if _player_name == "":
		return
	Network.connect_to_server(_player_name)
	_load_game()

func _on_create_pressed():
	if _player_name == "":
		return
	Network.create_server(_player_name)
	_load_game()

func _load_game():
	get_tree().change_scene("res://network/Game.tscn")
