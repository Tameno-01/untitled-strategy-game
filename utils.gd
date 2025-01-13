class_name Utils
extends Object


static func is_user_preferences_valid(user_config: Dictionary) -> bool:
	if user_config.username.is_empty():
		return false
	if user_config.username.length() > 20:
		return false
	return true
