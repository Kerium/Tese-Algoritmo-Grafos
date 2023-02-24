extends Area2D

var velocity = Vector2(0, 0)

func _ready():
	pass

func _process(delta):
	self.position = self.position + velocity.normalized() * 1.8
	

#Quando bate na parede
func _on_Sword_body_entered(body):
	if body.is_in_group("Enemies"):
		body._on_hit()
	queue_free()
