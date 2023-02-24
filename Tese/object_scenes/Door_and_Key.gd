extends Node2D


func _ready():
	pass


func _on_Key_body_entered(body):
	if body.is_in_group("Player"):
		print("A chave funcionou")
		queue_free()

