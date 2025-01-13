class_name LobbyUserEntry
extends HBoxContainer

const TEAM_NAMES: Array = [
	"red",
	"blue",
]

@export var username_label: Label
@export var team_label: Label
@export var host_label: Label


func set_user(user: Dictionary, is_host: bool):
	username_label.text = user.preferences.username
	var team: int = user.team
	if team == -1:
		team_label.text = "Spectating."
	else:
		team_label.text = "Playing as %s." % TEAM_NAMES[user.team]
	host_label.visible = is_host
