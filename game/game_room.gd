class_name GameRoom
extends Node

signal user_joined(id: int)
signal user_left(id: int)
signal user_joined_as_non_spectator(id: int, team: int)
signal user_switched_to_spectator(id: int)

enum States {
	NONE,
	LOBBY,
	GAME,
}

const STARTING_ROOM_INFO: Dictionary = {
	&"version": GlobalConstants.GAME_VERSION,
	&"state": States.LOBBY,
	&"host": 1,
	&"users": {},
}

@export var lobby_scene: PackedScene
@export var game_scene: PackedScene

var room_info: Dictionary
var local_user_preferences: Dictionary

var _current_state: States = States.NONE:
	set = _set_current_state
var _current_state_node: Node = null


func _ready() -> void:
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_client_connected)
		multiplayer.peer_disconnected.connect(_on_client_disconnected)
		_room_info_first_synch(STARTING_ROOM_INFO.duplicate(true))


func can_user_join_as_non_spectator() -> int:
	return _get_first_available_team() != -1


func get_game_start_problem() -> String:
	var non_spectator_user_count: int = 0
	for id: int in room_info.users:
		if room_info.users[id].team != -1:
			non_spectator_user_count += 1
	if non_spectator_user_count < 2:
		return "Too few players."
	return ""


func leave(message: String = "") -> void:
	multiplayer.multiplayer_peer = null
	var main_menu_scene: PackedScene = load("res://menus/main_menu/main_menu.tscn")
	var main_menu: MainMenu = main_menu_scene.instantiate()
	main_menu.message = message
	Utils.change_scene_to_node(get_tree(), main_menu)


func join_as_non_spectator() -> void:
	_join_as_non_spectator_request.rpc_id(1)


func switch_to_spectator() -> void:
	_switch_to_spectator_request.rpc_id(1)


@rpc("any_peer", "call_local", "reliable")
func _join_as_non_spectator_request() -> void:
	if not multiplayer.is_server():
		return
	var caller_id: int = multiplayer.get_remote_sender_id()
	if room_info.users[caller_id].team != -1:
		return
	var team: int = _get_first_available_team()
	if team == -1:
		return
	_user_joined_as_non_spectator.rpc(caller_id, team)


@rpc("any_peer", "call_local", "reliable")
func _switch_to_spectator_request() -> void:
	if not multiplayer.is_server():
		return
	var caller_id: int = multiplayer.get_remote_sender_id()
	if room_info.users[caller_id].team == -1:
		return
	_user_switched_to_spectator.rpc(caller_id)


@rpc("authority", "call_local", "reliable")
func _user_joined_as_non_spectator(id: int, team: int) -> void:
	room_info.users[id].team = team
	user_joined_as_non_spectator.emit(id, team)


@rpc("authority", "call_local", "reliable")
func _user_switched_to_spectator(id: int) -> void:
	room_info.users[id].team = -1
	user_switched_to_spectator.emit(id)


# This function only gets called on the server
func _on_client_connected(id: int) -> void:
	_room_info_first_synch.rpc_id(id, room_info)
	


@rpc("authority", "call_local", "reliable")
func _room_info_first_synch(server_room_info: Dictionary) -> void:
	if server_room_info.version != GlobalConstants.GAME_VERSION:
		leave(
				"Your game version (%s) doesn't match the server's version (%s)" 
				% [GlobalConstants.GAME_VERSION, room_info.version]
		)
		return
	room_info = server_room_info
	_current_state = room_info.state
	_join_request.rpc_id(1, local_user_preferences)


@rpc("any_peer", "call_local", "reliable")
func _join_request(user_preferences: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var caller_id: int = multiplayer.get_remote_sender_id()
	if room_info.users.has(caller_id):
		return
	if not DictTypes.is_dict_of_type(user_preferences, &"UserProperties"):
		multiplayer.multiplayer_peer.disconnect_peer(caller_id)
		return
	if not Utils.is_user_preferences_valid(user_preferences):
		multiplayer.multiplayer_peer.disconnect_peer(caller_id)
		return
	var new_user_team: int = _get_first_available_team()
	_user_join.rpc(
			caller_id,
			{
				&"team": new_user_team,
				&"preferences": user_preferences,
			},
	)


@rpc("authority", "call_local", "reliable")
func _user_join(id: int, user: Dictionary) -> void:
	room_info.users[id] = user
	user_joined.emit(id)


# This fucntion only gets called on the server
func _on_client_disconnected(id: int) -> void:
	_user_leave.rpc(id)


@rpc("authority", "call_local", "reliable")
func _user_leave(id: int) -> void:
	room_info.users.erase(id)
	user_left.emit(id)


func _on_server_disconnected() -> void:
	leave("Disconnected from server.")


func _get_first_available_team() -> int:
	var available_teams: Array = range(2) # range() returns an untyped array.
	for id: int in room_info.users:
		available_teams.erase(room_info.users[id].team)
	if not available_teams.is_empty():
		return available_teams[0]
	return -1


func _set_current_state(value: States) -> void:
	if _current_state == value:
		return
	_current_state = value
	match _current_state:
		States.NONE:
			assert(false, "NONE state is only for starting out the room.")
		States.LOBBY:
			if _current_state_node != null:
				_current_state_node.queue_free()
			var lobby: Lobby = lobby_scene.instantiate()
			lobby.game_room = self
			add_child(lobby)
			_current_state_node = lobby
		States.GAME:
			if _current_state_node != null:
				_current_state_node.queue_free()
			var game: Game = game_scene.instantiate()
			game.set_local_team(room_info.users[multiplayer.get_unique_id()].team)
			add_child(game)
			_current_state_node = game
