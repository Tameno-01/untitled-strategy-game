class_name DictTypes
extends Object

const TYPES: Dictionary = {
	&"PlayerMovement": {
		&"direction": TYPE_INT,
		&"distance": TYPE_INT
	},
	&"Turn": {
		&"team": TYPE_INT,
		&"movements": [TYPE_INT, &"PlayerMovement"],
	},
	&"UserProperties": {
		&"username": TYPE_STRING,
	},
}


static func is_dict_of_type(dict: Dictionary, type: StringName) -> bool:
	assert(TYPES.has(type), "Dict type \"" + type + "\" doesn't exist")
	var type_dict: Dictionary = TYPES[type]
	if dict.size() != type_dict.size():
		return false
	for key: Variant in type_dict:
		if not dict.has(key):
			return false
		if not _is_value_of_type(dict[key], type_dict[key]):
			return false
	return true


static func _is_value_of_type(value: Variant, type: Variant) -> bool:
	if type is int:
		if type != TYPE_NIL:
			if typeof(value) != type:
				return false
	elif type is StringName:
		if not value is Dictionary:
			return false
		if not is_dict_of_type(value, type):
			return false
	elif type is Array:
		match type.size():
			1: # Array.
				if not value is Array:
					return false
				for element: Variant in value:
					if not _is_value_of_type(element, type[0]):
						return false
			2: # Dict.
				if not value is Dictionary:
					return false
				for key: Variant in value:
					if not _is_value_of_type(key, type[0]):
						return false
					if not _is_value_of_type(value[key], type[1]):
						return false
			var invalid:
				assert(false, "Invalid type:" + invalid)
	else:
		assert(false, "Invalid type:" + type)
	return true
