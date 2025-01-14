class_name Visualizer
extends Node2D

const HEXAGON_HEIGHT: float = 0.86602540378 
const BOARD_SCALE: Vector2 = Vector2(100.0, 75.0)

@export var runner: Runner
@export var board: Node2D
@export var ui: Ui
@export var tile_scene: PackedScene
@export var player_scene: PackedScene
@export var move_indicator_scene: PackedScene

var local_team: int

var _players: Dictionary = {}
var _selected_player: int = -1
var _current_turn: Dictionary
var _move_indicators: Dictionary = {}
var _locked: bool = false:
		set = _set_locked


func _ready() -> void:
	_board_first_draw()
	_players_first_draw()
	_reset_curent_turn()


func _unhandled_input(event: InputEvent) -> void:
	if _locked:
		return
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_select_player(event.position)
		else: # Not pressed.
			_deselect_player()
	elif event is InputEventMouseMotion:
		if _selected_player == -1:
			return
		_update_player_movement(event.position)


func _submit() -> void:
	_locked = true
	runner.submit(_current_turn)


func _select_player(mouse_pos: Vector2) -> void:
	if _selected_player != -1:
		return
	var world_mouse_pos: Vector2 = _viewport_to_world(mouse_pos)
	var mouse_tile_pos: Vector2i = _get_tile_from_visual_pos(world_mouse_pos)
	var player_id: int = runner.get_player_in_tile(mouse_tile_pos)
	if player_id == -1:
		return
	var player: Dictionary = runner.get_player(player_id)
	if player.team != local_team:
		return
	_selected_player = player_id
	_update_player_movement(mouse_pos)


func _deselect_player() -> void:
	if _selected_player == -1:
		return
	_selected_player = -1


func _reset_curent_turn() -> void:
	_current_turn = {
		&"team": local_team,
		&"movements": {},
	}


func _update_player_movement(mouse_pos: Vector2) -> void:
	mouse_pos = _viewport_to_world(mouse_pos)
	var player_pos: Vector2 = _players[_selected_player].center.global_position
	var movement_vec: Vector2 = mouse_pos - player_pos
	var direction: Runner.Directions = _get_vec_direction(movement_vec)
	var distance: int = _get_vec_distance(movement_vec)
	var has_movement: bool = distance != 0
	var prev_movement: Dictionary = _current_turn.movements.get(_selected_player, {})
	if prev_movement.is_empty() and not has_movement:
		return
	if not prev_movement.is_empty():
		if (
				prev_movement.direction == direction
				and prev_movement.distance == distance
		):
			return
	var new_movement: Dictionary = {}
	if has_movement:
		new_movement = {
			&"direction": direction,
			&"distance": distance,
		}
	if new_movement.is_empty():
		_current_turn.movements.erase(_selected_player)
	else:
		_current_turn.movements[_selected_player] = new_movement
	_update_move_indicators(_selected_player, new_movement)


func _update_move_indicators(player_id: int, movement: Dictionary) -> void:
	if _move_indicators.has(player_id):
		for move_indicator: MoveIndicator in _move_indicators[player_id]:
			move_indicator.queue_free()
	if movement.is_empty():
		_move_indicators.erase(player_id)
		return
	_move_indicators[player_id] = []
	var player: Dictionary = runner.get_player(player_id)
	var start_indicator: MoveIndicator = move_indicator_scene.instantiate()
	start_indicator.position = _get_tile_visual_pos(player.position)
	start_indicator.position -= start_indicator.center.position
	start_indicator.type = MoveIndicator.Types.START
	start_indicator.team = player.team
	start_indicator.direction = movement.direction
	board.add_child(start_indicator)
	_move_indicators[player_id].append(start_indicator)
	var indicator_pos: Vector2i = player.position
	indicator_pos = Runner.get_neigbour(indicator_pos, movement.direction)
	for i in range(movement.distance - 1):
		var middle_indicator: MoveIndicator = move_indicator_scene.instantiate()
		middle_indicator.position = _get_tile_visual_pos(indicator_pos)
		middle_indicator.position -= middle_indicator.center.position
		middle_indicator.type = MoveIndicator.Types.MIDDLE
		middle_indicator.team = player.team
		middle_indicator.direction = movement.direction
		board.add_child(middle_indicator)
		_move_indicators[player_id].append(middle_indicator)
		indicator_pos = Runner.get_neigbour(indicator_pos, movement.direction)
	var end_indicator: MoveIndicator = move_indicator_scene.instantiate()
	end_indicator.position = _get_tile_visual_pos(indicator_pos)
	end_indicator.position -= end_indicator.center.position
	end_indicator.type = MoveIndicator.Types.END
	end_indicator.team = player.team
	end_indicator.direction = movement.direction
	board.add_child(end_indicator)
	_move_indicators[player_id].append(end_indicator)


func _viewport_to_world(pos: Vector2) -> Vector2:
	return get_viewport().canvas_transform.affine_inverse() * pos


func _board_first_draw() -> void:
	for tile_pos in runner.get_all_non_air_tiles():
		var new_tile: VisualTile = tile_scene.instantiate()
		new_tile.position = _get_tile_visual_pos(tile_pos)
		new_tile.position -= new_tile.center.position
		new_tile.type = runner.get_tile(tile_pos)
		board.add_child(new_tile)


func _players_first_draw() -> void:
	for id: int in runner.get_all_player_ids():
		var player: Dictionary = runner.get_player(id)
		var visual_player: VisualPlayer = player_scene.instantiate()
		visual_player.position = _get_tile_visual_pos(player.position)
		visual_player.position -= visual_player.center.position
		visual_player.color = GlobalConstants.TEAM_COLORS[player.team]
		board.add_child(visual_player)
		_players[id] = visual_player


static func _get_tile_visual_pos(tile_pos: Vector2i) -> Vector2:
	var output: Vector2 = Vector2(tile_pos)
	output.x += output.y / 2.0
	output.y *= HEXAGON_HEIGHT
	output *= BOARD_SCALE
	return output


static func _get_tile_from_visual_pos(visual_pos: Vector2) -> Vector2i:
	visual_pos /= BOARD_SCALE
	visual_pos.y /= HEXAGON_HEIGHT
	visual_pos.x -= visual_pos.y / 2.0
	visual_pos = round(visual_pos)
	return Vector2i(visual_pos)


static func _get_vec_direction(vec: Vector2) -> Runner.Directions:
	vec /= BOARD_SCALE
	var angle: float = vec.angle()
	angle *= 6.0 / TAU
	angle = round(angle)
	var int_angle: int = int(angle)
	int_angle = posmod(int_angle, Runner.Directions.COUNT)
	return int_angle as Runner.Directions


static func _get_vec_distance(vec: Vector2) -> int:
	vec /= BOARD_SCALE
	var dist: float = vec.length()
	dist = round(dist)
	return int(dist)


func _set_locked(value: bool) -> void:
	if value == _locked:
		return
	_locked = value
	if _locked:
		ui.lock()
	else: # Not locked.
		ui.unlock()
