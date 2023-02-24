extends Area2D

signal leaving_level

func _on_ExitDoor_body_entered(body):
	if body.is_in_group("Player"):
		get_tree().reload_current_scene()
