class_name VisualPlayer
extends Node2D

@export var center: Node2D
@export var base_sprite: Sprite2D

var color: Color:
		set = set_color


func set_color(value: Color) -> void:
	color = value
	base_sprite.self_modulate = color
