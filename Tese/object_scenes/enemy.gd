extends KinematicBody2D

const MAX_SPEED = 50
const ACCELERATION = 300
var group = false
var player
var state = "Idle"
var velocity = Vector2.ZERO
var health = 3

func _ready():
	set_group(group)

func _process(delta):
	
	match state:
		"Idle":
			velocity = Vector2.ZERO
			
		"Chase":
			var direction = (player.global_position - global_position).normalized()
			velocity = velocity.move_toward(direction * MAX_SPEED, delta * ACCELERATION)
	
	velocity = move_and_slide(velocity)
	

func set_group(group):
	if group == true:
		add_to_group("enemies")

func remove_group():
	remove_from_group("enemies")


func _on_Tracking_body_entered(body):
	if body.is_in_group("Player"):
		player = body
		state = "Chase"

func _on_Tracking_body_exited(body):
	if body.is_in_group("Player"):
		state = "Idle"
		player = null


func _on_Damage_body_entered(body):
	if body.is_in_group("Player"):
		body._on_hit()

func _on_hit():
	health -= 1
	if health <= 0:
		queue_free()
