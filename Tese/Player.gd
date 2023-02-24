extends KinematicBody2D

const SWORD = preload("res://object_scenes/sword.tscn")

var speed = 150
var health = 4
var tile_size = 16
var inputs = {
	"right": Vector2.RIGHT,
	"left": Vector2.LEFT,
	"up": Vector2.UP,
	"down": Vector2.DOWN
}

func _ready():
	if get_node("ArrowSpawner"):
		get_node("seta").connect("hit", self, "_on_hit")

func _process(delta):
	#NÃO HÁ MOVE AND SLIDE NO AREA2D
	var x_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var y_input = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if Input.is_action_pressed("ui_left"):
		$AnimatedSprite.flip_h = true
		
	elif Input.is_action_pressed("ui_right"):
		$AnimatedSprite.flip_h = false
		
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down"):
		$AnimatedSprite.play()
	else:
		$AnimatedSprite.playing = false
	
	move_and_slide(Vector2(x_input, y_input) * 100)
	
	#Disparar
	$Node2D.look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("mouse_left"):
		shoot()
		

	"""
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	
	position += velocity * delta
	"""

func shoot():
	var sword = SWORD.instance()
	get_parent().add_child(sword)
	sword.rotate($Node2D.rotation) 
	sword.position = $Node2D/Position2D.global_position
	sword.velocity = get_global_mouse_position() - sword.position

func health_bar():
	$Camera2D/TextureRect.rect_size.x = health * 16 #Comprimento de cada coração
	

func _on_hit():
	health -= 1
	if health <= 0:
		get_tree().reload_current_scene()
	health_bar()

func _gain_health():
	health += 2
	health_bar()


