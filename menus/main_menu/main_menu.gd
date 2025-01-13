extends Control


const connection_menu_scene: PackedScene = preload("res://menus/connection_menu/connection_menu.tscn")


func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(connection_menu_scene)
