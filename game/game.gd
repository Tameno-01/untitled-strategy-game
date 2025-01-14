class_name Game
extends Node

@export var visualizer: Visualizer


func set_local_team(team: int) -> void:
	visualizer.local_team = team
