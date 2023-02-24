extends Area2D



func _ready():
	pass # Replace with function body.


func _on_Area2D_body_entered(body):
	if $AnimatedSprite.frame == 1:
		if body.is_in_group("Player"):
			body._on_hit() 
