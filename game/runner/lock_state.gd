class_name LockState
extends RefCounted

enum Types {
	NONE,
	STOP,
	MOVE,
	SWAP,
	LOCK,
}

var type: Types = Types.NONE
var team: int
var swapping_teams: Array[int]


func combine_with(other: LockState) -> LockState:
	if type == Types.NONE:
		return other
	if other.type == Types.NONE:
		return self
	if type == Types.LOCK or other.type == Types.LOCK:
		return _new_lock()
	if type == Types.STOP and other.type == Types.STOP:
		return _new_lock()
	if type == Types.SWAP or other.type == Types.SWAP:
		return _new_lock()
	if team == other.team:
		return _new_lock()
	var output: LockState = LockState.new()
	output.type = Types.SWAP
	output.swapping_teams = [team, other.team]
	return output


func is_identical_to(other: LockState) -> bool:
	if swapping_teams.size() != other.swapping_teams.size():
		return false
	for swapping_team in swapping_teams:
		if not swapping_team in other.swapping_teams:
			return false
	return type == other.type and team == other.team


static func _new_lock() -> LockState:
	var output: LockState = LockState.new()
	output.type = Types.LOCK
	return output
