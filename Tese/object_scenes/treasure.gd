extends Area2D

const POTION = preload("res://object_scenes/potion.tscn")

var opened = false

func _ready():
	pass

func _on_Treasure_body_entered(body):
	if body.is_in_group("Player"):
		if opened == false:
			var potion = POTION.instance()
			get_parent().add_child(potion)
			potion.position = $Position2D.global_position
			print("Truesure funcionou")
		opened = true
