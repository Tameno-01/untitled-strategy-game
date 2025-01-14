class_name MainMenu
extends Control

@export var version_label: Label
@export var message_screen: CanvasItem
@export var message_label: Label

var message: String = ""


func _ready() -> void:
	version_label.text = "Version " + GlobalConstants.GAME_VERSION
	if not message.is_empty():
		message_screen.show()
		message_label.text = message


func _on_play_pressed() -> void:
	var connection_menu_scene: PackedScene = load("res://menus/connection_menu/connection_menu.tscn")
	get_tree().change_scene_to_packed(connection_menu_scene)


func _on_quit_pressed() -> void:
	get_tree().quit()
