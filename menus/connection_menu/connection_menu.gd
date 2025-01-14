extends Control

@export var username_line_edit: LineEdit
@export var ip_line_edit: LineEdit
@export var port_line_edit: LineEdit
@export var connecting_screen: Control
@export var connection_failed_screen: Control


func _on_create_pressed() -> void:
	# TODO: Give user feedback for errors an invalid configurations
	var user_preferences: Dictionary = _get_user_preferences()
	if not Utils.is_user_preferences_valid(user_preferences):
		return
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	# TODO: Store max clients in a const somehwere.
	var err: Error = peer.create_server(port_line_edit.text.to_int(), 8)
	if err != OK:
		return
	multiplayer.multiplayer_peer = peer
	go_to_game_room(user_preferences)


func _on_join_pressed() -> void:
	# TODO: Give user feedback for errors an invalid configurations
	var user_preferences: Dictionary = _get_user_preferences()
	if not Utils.is_user_preferences_valid(user_preferences):
		return
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(ip_line_edit.text, port_line_edit.text.to_int())
	if err != OK:
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	connecting_screen.show()


func _on_connected_to_server() -> void:
	go_to_game_room(_get_user_preferences())


func on_cancel_connection_button_pressed() -> void:
	connecting_screen.hide()
	multiplayer.multiplayer_peer = null


func _on_connection_failed() -> void:
	connecting_screen.hide()
	connection_failed_screen.show()


func go_to_game_room(user_preferences: Dictionary) -> void:
	var game_room_scene: PackedScene = load("res://game/game_room.tscn")
	var game_room: Node = game_room_scene.instantiate()
	game_room.local_user_preferences = user_preferences
	Utils.change_scene_to_node(get_tree(), game_room)


func _get_user_preferences() -> Dictionary:
	return {
		&"username": username_line_edit.text
	}


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/main_menu/main_menu.tscn")
