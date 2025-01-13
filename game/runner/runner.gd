class_name Runner
extends Node

enum Directions {
	RIGHT,
	DOWN_RIGHT,
	DOWN_LEFT,
	LEFT,
	UP_LEFT,
	UP_RIGHT,
	COUNT,
}

enum TileTypes {
	AIR,
	GROUND,
	DAMAGED,
	ANCHOR,
}

var grid_size: int = 7
var anchor_locations: Array[Vector2i] = [
	Vector2i(0, 0),
]

var _tiles: Dictionary = {}
var _players: Dictionary = {}
var _last_id: int = -1


func _ready() -> void:
	_create_board()
	_create_players()


func get_tile(position: Vector2i) -> TileTypes:
	if not _tiles.has(position):
		return TileTypes.AIR
	return _tiles[position]


static func get_neigbour(position: Vector2i, direction: Directions) -> Vector2i:
	match direction:
		Directions.RIGHT:
			return position + Vector2i(1, 0)
		Directions.DOWN_RIGHT:
			return position + Vector2i(0, 1)
		Directions.DOWN_LEFT:
			return position + Vector2i(-1, 1)
		Directions.LEFT:
			return position + Vector2i(-1, 0)
		Directions.UP_LEFT:
			return position + Vector2i(0, -1)
		Directions.UP_RIGHT:
			return position + Vector2i(1, -1)
	assert(false, "Invalid direction.")
	return position # Unreacheable.


func get_all_non_air_tiles() -> Array[Vector2i]:
	var output: Array[Vector2i]
	output.assign(_tiles.keys())
	return output


func get_player(id: int) -> Dictionary:
	return _players[id]


func get_players_in_tile(position: Vector2i) -> Array[int]:
	var output: Array[int] = []
	for id: int in _players:
		if _players[id].position == position:
			output.append(id)
	return output


func get_player_in_tile(position: Vector2i) -> int:
	for id: int in _players:
		if _players[id].position == position:
			return id
	return -1


func submit(turn: Dictionary) -> void:
	pass


func _recieve_submission(turn: Dictionary) -> void:
	pass


func _set_tile(position: Vector2i, type: TileTypes) -> void:
	if type == TileTypes.AIR:
		_tiles.erase(position)
		return
	_tiles[position] = type


func get_all_player_ids() -> Array:
	return _players.keys()

func _create_board_base() -> void:
	for y in range(-(grid_size - 1) / 2, (grid_size + 1) / 2):
		_set_tile(Vector2i(0, y), TileTypes.GROUND)
	for i in range((grid_size - 1) / 2):
		for y in range(-(grid_size - 1) / 2, i + 1):
			var x: int = (grid_size - 1) / 2 - i
			_set_tile(Vector2i(x, y), TileTypes.GROUND)
			_set_tile(-Vector2i(x, y), TileTypes.GROUND)


func _place_anchors() -> void:
	for anchor_location in anchor_locations:
		_set_tile(anchor_location, TileTypes.ANCHOR)


func _create_board() -> void:
	_create_board_base()
	_place_anchors()


func _create_players() -> void:
	for i in range((grid_size + 1) / 2):
		var x: int = -(grid_size - 1) / 2
		var y: int = i
		_add_player({
			&"position": Vector2i(x, y),
			&"team": 0,
		})
		_add_player({
			&"position": -Vector2i(x, y),
			&"team": 1,
		})


func _add_player(player: Dictionary) -> int:
	var player_id: int = _get_new_id()
	_players[player_id] = player
	return player_id


func _get_new_id() -> int:
	_last_id += 1
	return _last_id
