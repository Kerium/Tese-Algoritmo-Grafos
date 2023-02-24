extends Area2D

const Key = preload("res://object_scenes/key.tscn")
const Potion = preload("res://object_scenes/potion.tscn")
const color_list = ["yellow", "red", "green", "blue"]

var colors = {
	0: Color.yellow, #yellow
	1: Color.red, #red
	2: Color.green, #green
	3: Color.blue, #blue
}
var rect_order = []
var index_square = 0
var player_order = []

func _ready():
	randomize()


func _on_Simon_body_entered(body):
	if body.is_in_group("Player"):
		rect_order.clear()
		index_square = 0
		for i in range (randi() % 3 + 3):
			var number = randi() % 4
			rect_order.append(number)
			
		for i in rect_order:
			get_node("Square" + str(i) + "/ColorRect").color = colors.get(i)
			print(colors.get(i))
			yield(get_tree().create_timer(1.5), "timeout")
			get_node("Square" + str(i) + "/ColorRect").color = Color.white
			yield(get_tree().create_timer(1.2), "timeout")

func _on_Simon_body_exited(body):
	$Square0/ColorRect.color = Color.white
	$Square1/ColorRect.color = Color.white
	$Square2/ColorRect.color = Color.white
	$Square3/ColorRect.color = Color.white
	
	if player_order == rect_order:
		var potion = Potion.instance()
		potion.position = Vector2(24, 24)
		add_child(potion)


func _on_Square0_body_entered(body):
	if body.is_in_group("Player"):
		player_order.append(0)
		print("Player entered")


func _on_Square1_body_entered(body):
	if body.is_in_group("Player"):
		player_order.append(1)
		print("Player entered")


func _on_Square2_body_entered(body):
	if body.is_in_group("Player"):
		player_order.append(2)
		print("Player entered")


func _on_Square3_body_entered(body):
	if body.is_in_group("Player"):
		player_order.append(3)
		print("Player entered")

