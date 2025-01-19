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
var game_room: GameRoom

var _tiles: Dictionary = {}
var _players: Dictionary = {}
var _last_id: int = -1
var _turn_submissions: Dictionary = {}
var _lock_happened: bool
var _locked_tiles: Dictionary = {}


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
	_recieve_submission.rpc_id(1, turn)


func _get_tile_lockstate(tile: Vector2i) -> LockState:
	return _locked_tiles.get(tile, LockState.new())


func _set_tile_lockstate(tile: Vector2i, state: LockState) -> void:
	if state.type == LockState.Types.NONE:
		_locked_tiles.erase(tile)
	_locked_tiles[tile] = state


@rpc("any_peer", "call_local", "reliable")
func _recieve_submission(turn: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	if not DictTypes.is_dict_of_type(turn, &"Turn"):
		return
	var team: int = game_room.room_info.users[multiplayer.get_remote_sender_id()].team
	_turn_submissions[team] = turn
	if _turn_submissions.size() == 2:
		_do_turn()


func _do_turn() -> Array[Array]:
	var steps: Array[Array] = []
	var fallen_pieces_step: Array = []
	for player_id in _players:
		var player: Dictionary = _players[player_id]
		_set_tile(player.position, TileTypes.AIR)
		fallen_pieces_step.append({
			&"type": &"tile_fall",
			&"tile": player.position,
		})
	steps.append(fallen_pieces_step)
	while true:
		_lock_happened = true
		while _lock_happened:
			_lock_happened = false
			_update_lock_states()
			# Stopped at: 'Update the lock state of all tiles'
	return steps


func _update_lock_states() -> void:
	for player_id in _players:
		var player: Dictionary = _players[player_id]
		var next_tile: Vector2i = _determine_player_next_tile(player_id)
		var prev_lock_state: LockState = _get_tile_lockstate(next_tile)
		var lock_state: LockState = LockState.new()
		var movement: Dictionary = _turn_submissions[player.team][player_id]
		if movement.distance < 2:
			lock_state.type = LockState.Types.STOP
		else:
			lock_state.type = LockState.Types.MOVE
		lock_state.team = player.team
		var new_lock_state: LockState = prev_lock_state.combine_with(lock_state)
		if not new_lock_state.is_identical_to(prev_lock_state):
			_lock_happened = true
		_set_tile_lockstate(next_tile, new_lock_state)


func _determine_player_next_tile(player_id: int) -> Vector2i:
	var player: Dictionary = _players[player_id]
	var movement: Dictionary = _turn_submissions[player.team][player_id]
	if movement.distance == 0:
		return player.position
	var direction: Directions = movement.direction as Directions
	return get_neigbour(player.position, direction)


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
