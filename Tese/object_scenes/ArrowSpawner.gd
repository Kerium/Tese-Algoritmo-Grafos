extends Node2D

const Arrow = preload("res://object_scenes/seta.tscn")
var direction

func _ready():
	pass # Replace with function body.


func _on_Timer_timeout():
	var arrow = Arrow.instance()
	if direction == "right":
		arrow.direction = "right"
		add_child(arrow)
	else:
		arrow.direction = "down"
		add_child(arrow)
