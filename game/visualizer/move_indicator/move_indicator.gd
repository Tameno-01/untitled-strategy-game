class_name MoveIndicator
extends Node2D

enum Types {
	START,
	MIDDLE,
	END,
}

@export var center: Node2D
@export var start_texture: Texture2D
@export var middle_texture: Texture2D
@export var end_texture: Texture2D
@export var sprite: Sprite2D


var type: Types = Types.MIDDLE:
		set = set_type
var team: int:
		set = set_team
var direction: Runner.Directions:
		set = set_direction


func set_type(value: Types) -> void:
	type = value
	match type:
		Types.START:
			sprite.texture = start_texture
		Types.MIDDLE:
			sprite.texture = middle_texture
		Types.END:
			sprite.texture = end_texture


func set_team(value: int) -> void:
	team = value
	sprite.modulate = Color(GlobalConstants.TEAM_COLORS[team], 0.5)


func set_direction(value: Runner.Directions) -> void:
	direction = value
	var rot: float = float(direction as int)
	rot *= TAU / Runner.Directions.COUNT
	sprite.rotation = rot
