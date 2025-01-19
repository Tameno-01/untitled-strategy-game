class_name Game
extends Node

@export var runner: Runner
@export var visualizer: Visualizer


func set_game_room(game_room: GameRoom) -> void:
	runner.game_room = game_room
	visualizer.game_room = game_room
