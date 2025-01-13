class_name VisualTile
extends Node2D


@export var center: Node2D
@export var ground_texture: Texture2D
@export var damaged_texture: Texture2D
@export var anchor_texture: Texture2D
@export var sprite: Sprite2D


var type: Runner.TileTypes = Runner.TileTypes.AIR:
		set = set_type


func set_type(value: Runner.TileTypes) -> void:
	type = value
	match type:
		Runner.TileTypes.GROUND:
			sprite.texture = ground_texture
		Runner.TileTypes.DAMAGED:
			sprite.texture = damaged_texture
		Runner.TileTypes.ANCHOR:
			sprite.texture = anchor_texture
