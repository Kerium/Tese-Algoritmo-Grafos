extends Area2D

var direction

func _ready():
	sprite_change()
	

func _process(delta):
	if direction == "right":
		self.position = self.position + Vector2.RIGHT 
	else:
		self.position = self.position + Vector2.DOWN
	

func sprite_change():
	if direction == "right":
		self.rotation_degrees = 90
		$CollisionShape2D.rotation_degrees = 90
	else:
		$Sprite.flip_v = true
		

#Quando bate na parede
func _on_KinematicBody2D_body_entered(body):
	if body.is_in_group("Player"):
		body._on_hit()
	queue_free()
