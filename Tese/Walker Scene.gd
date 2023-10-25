extends Node2D

const Player = preload("res://Player.tscn")
const Exit = preload("res://ExitDoor.tscn")
const Enemy = preload("res://object_scenes/enemy.tscn")
const Potion = preload("res://object_scenes/potion.tscn")
const Treasure = preload("res://object_scenes/treasure.tscn")
const False_Floor = preload("res://object_scenes/False_Floor.tscn")
const Puzzle = preload("res://object_scenes/Simon.tscn")
const Door_and_key = preload("res://object_scenes/Door_and_Key.tscn")
const Obstacle = preload("res://object_scenes/Obstacle.tscn")
const NODE_TYPES = ["empty_room", "monster_house", "treasure_room", "puzzle_room"]

onready var tileMap = $TileMap

var borders = Rect2(0, 0, 60, 34)
var rooms = []
var rooms_nodes = []

func _ready():
	randomize()
	generate_level()
	node_level_generator()
	print(get_tree())

func generate_level():
	var walker = Walker.new(Vector2(15, 9), borders) # Metade do Rect2
	var map = walker.walk(200) #200
	
	var player = Player.instance()
	add_child(player)
	player.position = map.front() * 16
	
	var exit = Exit.instance()
	add_child(exit)
	exit.position = walker.get_end_room().position * 16
	exit.connect("leaving_level", self, "reload_level")
	
	rooms = walker.get_rooms()
	lock_and_key(exit.position)
	
	walker.queue_free()
	#print(rooms)
	for location in map:
		tileMap.set_cellv(location, 0)
	tileMap.update_bitmask_region(borders.position, borders.end)

func reload_level():
	get_tree().reload_current_scene()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		reload_level()

func node_level_generator():
	var node_index = randi() % len(NODE_TYPES)
	var chance = randi() % 6
	
	while rooms_nodes.size() < (rooms.size() - 1):
		if chance < 3:
			rooms_nodes.append(NODE_TYPES[node_index])
		elif chance >= 4:
			break
		chance = randi() % 5
		node_index = randi() % len(NODE_TYPES)
	
	#CHAMAR AS FUNÇÕES
	var spawn = funcref(self, "spawn")
	var goal = funcref(self, "goal")
	var empty_room = funcref(self, "empty_room")
	var monster_house = funcref(self, "monster_house")
	var treasure_room = funcref(self, "treasure_room")
	var puzzle_room = funcref(self, "puzzle_room")
	
	var room_functions = {
		"entry": spawn,
		"end": goal,
		"empty_room": empty_room,
		"monster_house": monster_house,
		"treasure_room": treasure_room,
		"puzzle_room": puzzle_room,
	}
	
	for i in rooms_nodes:
		room_functions[i].call_func()
	print("Rooms nodes: " + str(rooms_nodes))
	
#FUNÇÕES DE GERAÇÃO DAS FUCIONALIDADES DAS DIVISÕES

func lock_and_key(door_position):
	var door_and_key = Door_and_key.instance()
	add_child(door_and_key)
	door_and_key.get_node("Door").position = door_position
	door_and_key.get_node("Key").position = rooms[randi() % len(rooms)].position * 16
	


func empty_room():
	var enemy = Enemy.instance()
	var num = randi() % 3
	var potion = Potion.instance()
	var area_list = coordenates()
	print("Empty Room number: " + str(num))
	
	if num == 2:
		add_child(enemy)
		enemy.position = tileMap.map_to_world(pick_vect(area_list)) 
		add_child(potion)
		potion.position = tileMap.map_to_world(pick_vect(area_list)) 
	elif num == 0:
		add_child(potion)
		potion.position = tileMap.map_to_world(pick_vect(area_list)) 
	elif num == 1:
		add_child(enemy)
		enemy.position = tileMap.map_to_world(pick_vect(area_list)) 

func monster_house():
	var num = (randi() % 3) + 3
	var area_list = coordenates()
	#print("Monster House enemies: " + str(num))
	for i in range(0, num):
		var enemy = Enemy.instance()
		enemy.group = true
		add_child(enemy)
	#print(get_tree().get_nodes_in_group("enemies"))
	# Iterar a lista com nodes de inimigos e remove a posição desses para não sobrepor
	for i in get_tree().get_nodes_in_group("enemies"):
		#i.position = tileMap.map_to_world(pick_vect(area_list))
		i.remove_group()
		

func treasure_room():
	var num_tresures = randi() % 4
	var num_false_floors = randi() % 6
	var area_list = coordenates() 
	#Gera Tesouros
	for i in num_tresures:
		var treasure = Treasure.instance()
		add_child(treasure)
		treasure.position = tileMap.map_to_world(pick_vect(area_list)) 
		
	#Gera Alçapões
	for i in num_false_floors:
		var false_floor = False_Floor.instance()
		add_child(false_floor)
		false_floor.position = tileMap.map_to_world(pick_vect(area_list)) 

func puzzle_room():
	var puzzle = Puzzle.instance()
	var area_list = coordenates() 
	puzzle.position = tileMap.map_to_world(pick_vect(area_list)) 
	add_child(puzzle)

func coordenates():
	var index_list = randi() % len(rooms)
	var size_x = rooms[index_list].size.x
	print(size_x)
	var size_y = rooms[index_list].size.y
	var center = rooms[index_list].position
	#var width = size_x * 2
	#var height = size_y * 2
	var list_result = [] #Vai dar return da area da divisão
	
	for i in range(-size_x, size_x):
		for j in range(-size_y, size_y):
			list_result.append(Vector2(center.x + i, center.y + j))
			#list_result.append(Vector2(center.x - i, center.y -j))
	rooms.remove(index_list)
	return list_result

func pick_vect(area_list):
	var index = randi() % len(area_list)
	var point_vect = area_list[index]
	area_list.remove(index)
	
	return point_vect



