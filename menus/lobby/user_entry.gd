class_name LobbyUserEntry
extends PanelContainer

@export var username_label: Label
@export var team_texture_rect: TextureRect
@export var spectator_texture_rect: TextureRect
@export var host_texture_rect: TextureRect


func set_user(user: Dictionary, is_host: bool) -> void:
	username_label.text = user.preferences.username
	var team: int = user.team
	if team == -1:
		team_texture_rect.hide()
		spectator_texture_rect.show()
	else:
		spectator_texture_rect.hide()
		team_texture_rect.show()
		team_texture_rect.self_modulate = GlobalConstants.TEAM_COLORS[team]
	host_texture_rect.visible = is_host
