class_name Utils
extends Object


static func change_scene_to_node(tree: SceneTree, node: Node) -> void:
	tree.current_scene.queue_free()
	tree.root.add_child(node)
	tree.current_scene = node


static func is_user_preferences_valid(user_config: Dictionary) -> bool:
	if user_config.username.is_empty():
		return false
	if user_config.username.length() > 20:
		return false
	return true
