class_name Lobby
extends Control

@export var user_entry_container: VBoxContainer
@export var user_entry_scene: PackedScene

var room_info: Dictionary

var player_entries: Dictionary = {}


func _ready() -> void:
	for id: int in room_info.users:
		_add_user_to_list(id)


func on_user_joined(id: int) -> void:
	_add_user_to_list(id)


func on_user_left(id: int) -> void:
	_remove_user_from_list(id)


func _add_user_to_list(id: int) -> void:
	var new_entry: LobbyUserEntry = user_entry_scene.instantiate()
	new_entry.set_user(room_info.users[id], id == 1)
	user_entry_container.add_child(new_entry)
	player_entries[id] = user_entry_container


func _remove_user_from_list(id: int) -> void:
	player_entries[id].queue_free()
	player_entries.erase(id)
