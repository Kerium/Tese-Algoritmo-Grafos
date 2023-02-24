extends Area2D


func _ready():
	pass


func _on_False_Floor_body_entered(body):
	$ColorRect.color = Color.black
	#$Timer.start()
	if body.is_in_group("Player"):
		$Timer.start() # Fazer sala especial
		


func _on_Timer_timeout():
	get_tree().reload_current_scene()
