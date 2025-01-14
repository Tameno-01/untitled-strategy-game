class_name Lobby
extends Control

@export var user_entry_container: VBoxContainer
@export var join_button: Button
@export var spectate_button: Button
@export var start_button: Button
@export var info_label: Label
@export var user_entry_scene: PackedScene

var game_room: GameRoom

var _player_entries: Dictionary = {}


func _ready() -> void:
	for id: int in game_room.room_info.users:
		_add_user_to_list(id)
	game_room.user_joined.connect(_on_user_joined)
	game_room.user_left.connect(_on_user_left)


func _on_user_joined(id: int) -> void:
	_add_user_to_list(id)
	_update_available_options()


func _on_user_left(id: int) -> void:
	_remove_user_from_list(id)
	_update_available_options()


func _leave() -> void:
	game_room.leave()


func _update_available_options() -> void:
	join_button.hide()
	spectate_button.hide()
	start_button.hide()
	info_label.hide()
	var local_id: int = multiplayer.get_unique_id()
	var local_user: Dictionary = game_room.room_info.users[local_id]
	var start_probalem: String = game_room.get_game_start_problem()
	if local_user.team == -1:
		if game_room.can_user_join_as_non_spectator():
			join_button.show()
	else: # Local user is not a spactator
		spectate_button.show()
	if start_probalem.is_empty():
		if local_id == game_room.room_info.host:
			start_button.show()
		else: # Local user is not the host
			info_label.show()
			info_label.text = "Waiting for host to start."
	else: # There's a start problem. 
		info_label.show()
		info_label.text = start_probalem


func _add_user_to_list(id: int) -> void:
	var new_entry: LobbyUserEntry = user_entry_scene.instantiate()
	new_entry.set_user(game_room.room_info.users[id], id == game_room.room_info.host)
	user_entry_container.add_child(new_entry)
	_player_entries[id] = new_entry


func _remove_user_from_list(id: int) -> void:
	_player_entries[id].queue_free()
	_player_entries.erase(id)
