class_name Ui
extends Control


signal submit_pressed


func lock() -> void:
	hide()


func unlock() -> void:
	show()


func _on_submit_pressed() -> void:
	submit_pressed.emit()
