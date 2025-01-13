class_name GameRoom
extends Node


signal user_joined(id: int)
signal user_left(id: int)


enum States {
	NONE,
	LOBBY,
	GAME,
}


@export var lobby_scene: PackedScene
@export var game_scene: PackedScene


var local_user_preferences: Dictionary


var _current_state: States = States.NONE:
	set = set_current_state
var current_state_node: Node = null
var _room_info: Dictionary


func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_client_connected)
		multiplayer.peer_disconnected.connect(_client_disconnected)
		_room_info_first_synch({
			&"state": States.LOBBY,
			&"users": {},
		})


# This function only gets called on the server
func _client_connected(id: int) -> void:
	_room_info_first_synch.rpc_id(id, _room_info)


@rpc("authority", "call_local", "reliable")
func _room_info_first_synch(room_info: Dictionary) -> void:
	_room_info = room_info
	_current_state = _room_info.state
	_join_request.rpc_id(1, local_user_preferences)


@rpc("any_peer", "call_local", "reliable")
func _join_request(user_preferences: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var caller_id: int = multiplayer.get_remote_sender_id()
	if _room_info.users.has(caller_id):
		return
	if not DictTypes.is_dict_of_type(user_preferences, &"UserProperties"):
		multiplayer.multiplayer_peer.disconnect_peer(caller_id)
		return
	if not Utils.is_user_preferences_valid(user_preferences):
		multiplayer.multiplayer_peer.disconnect_peer(caller_id)
		return
	var new_user_team: int
	if _room_info.users.size() == 0:
		new_user_team = 0
	elif _room_info.users.size() == 1:
		new_user_team = 1
	else:
		new_user_team = -1
	_user_join.rpc(
			caller_id,
			{
				&"team": new_user_team,
				&"preferences": user_preferences,
			},
	)


@rpc("authority", "call_local", "reliable")
func _user_join(id: int, user: Dictionary) -> void:
	_room_info.users[id] = user
	user_joined.emit(id)


# This fucntion only gets called on the server
func _client_disconnected(id: int) -> void:
	_user_leave.rpc(id)


@rpc("authority", "call_local", "reliable")
func _user_leave(id: int) -> void:
	_room_info.users.erase(id)
	user_left.emit(id)


func set_current_state(value: States) -> void:
	if _current_state == value:
		return
	_current_state = value
	match _current_state:
		States.NONE:
			assert(false, "NONE state is only for starting out the room.")
		States.LOBBY:
			if current_state_node != null:
				current_state_node.queue_free()
			var lobby: Lobby = lobby_scene.instantiate()
			lobby.room_info = _room_info
			user_joined.connect(lobby.on_user_joined)
			user_left.connect(lobby.on_user_left)
			add_child(lobby)
			current_state_node = lobby
		States.GAME:
			if current_state_node != null:
				current_state_node.queue_free()
			var game: Node = game_scene.instantiate()
			add_child(game)
			current_state_node = game
