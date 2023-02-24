extends Node2D

const Player = preload("res://Player.tscn")
const Exit = preload("res://ExitDoor.tscn")
const Enemy = preload("res://object_scenes/enemy.tscn")
const Potion = preload("res://object_scenes/potion.tscn")
const Trap_Floor = preload("res://object_scenes/trap.tscn")
const ArrowSpawner = preload("res://object_scenes/ArrowSpawner.tscn")
const Treasure = preload("res://object_scenes/treasure.tscn")
const False_Floor = preload("res://object_scenes/False_Floor.tscn")
const Puzzle = preload("res://object_scenes/Simon.tscn")
const Door_and_key = preload("res://object_scenes/Door_and_Key.tscn")
const Obstacle = preload("res://object_scenes/Obstacle.tscn")
const NODE_TYPES = ["empty_room", "monster_house", "trap_room", "treasure_room", "puzzle_room"]

var n_rooms = randi() % 12 #10
var center_rooms = []
var total_area = []
onready var Map = $TileMap

func _ready():
	randomize()
	generate_rooms()
	room_features()

func generate_rooms():
	var number_generated_rooms = 0
	#var counter = 0 Usar se apenas se começar a demorar muito tempo
	
	while number_generated_rooms <= n_rooms:
		var center_room = Vector2(randi() % 40, randi() % 40)
		var width = randi() % 7 + 4
		var height = randi() % 7 + 4 
		var used_cells = Map.get_used_cells()
		var temp_room_area = [] # Area da divisão 
		var not_in_used_cells = true
		
		for x in range(center_room.x - (width / 2), center_room.x + (width / 2)):
			for y in range(center_room.y - (height / 2), center_room.y + (height / 2)):
				temp_room_area.append(Vector2(x, y))
		#ORDEM DOS VETORES
		for x in temp_room_area:
			if x in used_cells:
				not_in_used_cells = false
		
		if not_in_used_cells:
			for cell in temp_room_area:
				Map.set_cellv(cell, 0)
				Map.update_bitmask_area(cell)
			total_area.append(temp_room_area)
			center_rooms.append(center_room)
			number_generated_rooms += 1

	
	print("Centro dos rooms: " + str(center_rooms))
	for i in range(0, center_rooms.size() - 1):
		carve_path(center_rooms[i], center_rooms[i + 1])
	#print("Total area: " + str(total_area))

func manhattan_distance_list(start_point, index_room):
	var used_points = Map.get_used_cells()
	var temp_total_area = total_area
	var lowest_distance = 1000
	var my_point
	
	for i in temp_total_area[index_room]:
		used_points.erase(i)
	
	for i in used_points:
		var distance = abs(i.x - start_point.x) + abs(i.y - start_point.y)
		if distance <= lowest_distance:
			lowest_distance = distance
			my_point = i
	print("My point: " + str(my_point))
	return my_point

func carve_path(pos1, pos2):
	#Carve a path between 2 points
	#print("Pos2: " + str(pos2))
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	if x_diff == 0:
		x_diff = pow(-1.0, randi() % 2)
	if y_diff == 0:
		y_diff = pow(-1.0, randi() % 2)
	#Choose either x/y or y/x
	var x_y = pos1
	var y_x = pos2
	if (randi() % 2) > 0:
		x_y = pos2
		y_x = pos1
	for x in range(pos1.x, pos2.x, x_diff):
		Map.set_cellv(Vector2(x, x_y.y), 0)
		Map.update_bitmask_area(Vector2(x, x_y.y))
		#Map.set_cellv(Vector2(x, x_y.y + y_diff), 0)
		#Map.update_bitmask_area(Vector2(x, x_y.y + y_diff))
	for y in range(pos1.y, pos2.y, y_diff):
		Map.set_cellv(Vector2(y_x.x, y), 0)
		Map.update_bitmask_area(Vector2(y_x.x, y))
		#Map.set_cellv(Vector2(y_x.x + x_diff, y), 0)
		#Map.update_bitmask_area(Vector2(y_x.x + x_diff, y))

func room_features():
	var nodes = ["entry", "end"]
	var chance = randi() % 6
	var node_index = randi() % len(NODE_TYPES)
	
	while nodes.size() < (total_area.size() - 1) and nodes.size() < n_rooms:
		if chance < 5:
			nodes.append(NODE_TYPES[node_index])
		else:
			break
		chance = randi() % 6
		node_index = randi() % len(NODE_TYPES)
	
	var spawn = funcref(self, "spawn")
	var goal = funcref(self, "goal")
	var empty_room = funcref(self, "empty_room")
	var monster_house = funcref(self, "monster_house")
	var trap_room = funcref(self, "trap_room")
	var treasure_room = funcref(self, "treasure_room")
	var puzzle_room = funcref(self, "puzzle_room")
	
	var room_functions = {
		"entry": spawn,
		"end": goal,
		"empty_room": empty_room,
		"monster_house": monster_house,
		"trap_room" : trap_room,
		"treasure_room": treasure_room,
		"puzzle_room": puzzle_room,
	}
	
	for i in nodes:
		room_functions[i].call_func()
	print("Rooms nodes: " + str(nodes))


func spawn():
	var player = Player.instance()
	add_child(player)
	var index = randi() % len(center_rooms)
	var area_spawn = center_rooms[index]
	player.position = Map.map_to_world(area_spawn)
	total_area.remove(index)

func goal():
	var exit = Exit.instance()
	add_child(exit)
	var index = randi() % len(center_rooms)
	var exit_position = center_rooms[index]
	exit.position = Map.map_to_world(exit_position)
	lock_and_key(exit_position)
	total_area.remove(index)


func lock_and_key(point):
	var index = randi() % len(total_area)
	var door_and_key = Door_and_key.instance()
	add_child(door_and_key)
	door_and_key.get_node("Door").position = Map.map_to_world(point)
	door_and_key.get_node("Key").position = Map.map_to_world(total_area[index][randi() % len(total_area[index])]) #rooms_positions[key_index][randi() % len(rooms_positions[key_index])]
	#print("Key vect: " + str(door_and_key.get_node("Key").position))

func empty_room():
	var enemy = Enemy.instance()
	var num = randi() % 3
	var potion = Potion.instance()
	var room_index = randi() % len(total_area)
	#print("Empty Room number: " + str(num))
	
	if num == 2:
		add_child(enemy)
		enemy.position = Map.map_to_world(total_area[room_index][randi() % len(total_area[room_index])])
		add_child(potion)
		potion.position = Map.map_to_world(total_area[room_index][randi() % len(total_area[room_index])])
	elif num == 0:
		add_child(potion)
		potion.position = Map.map_to_world(total_area[room_index][randi() % len(total_area[room_index])])
	elif num == 1:
		add_child(enemy)
		enemy.position = Map.map_to_world(total_area[room_index][randi() % len(total_area[room_index])])

func monster_house():
	var num = (randi() % 3) + 3
	#print("Monster House enemies: " + str(num))
	var room_index = randi() % len(total_area)
	for i in range(0, num):
		var enemy = Enemy.instance()
		enemy.group = true
		add_child(enemy)
	#print(get_tree().get_nodes_in_group("enemies"))
	# Iterar a lista com nodes de inimigos e remove a posição desses para não sobrepor
	for i in get_tree().get_nodes_in_group("enemies"):
		var pos = total_area[room_index][randi() % len(total_area[room_index])]
		i.position = Map.map_to_world(pos) 	
		i.remove_group()
		total_area[room_index].erase(pos)
	total_area.remove(room_index)

func trap_room():
	var num = 2#randi() % 3
	var lower_right_corner = Vector2.ZERO
	var room_index = randi() % len(total_area)
	var vect_x = total_area[room_index][0].x 
	var vect_y = total_area[room_index][0].y
	
	for i in total_area[room_index]: # MUDAR PARA ROOM_AREA[-1]
		if i.x > lower_right_corner.x:
			lower_right_corner.x = i.x
		if i.y > lower_right_corner.y:
			lower_right_corner.y = i.y
			
	#print("Lower Right Corner: " + str(lower_right_corner))
	#print("Room Area: " + str(room_area))
	
	if num == 0 or num == 1:
		if (lower_right_corner.x - vect_x) >= (lower_right_corner.y - vect_y):
			if (int(lower_right_corner.x - vect_x) % 2) == 0:
				for i in range (vect_x, lower_right_corner.x + 1, 2):
					for j in range (vect_y, lower_right_corner.y + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = Map.map_to_world(Vector2(i, j))
			else:
				for i in range (vect_x + 1, lower_right_corner.x + 1, 2):
					for j in range (vect_y, lower_right_corner.y + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = Map.map_to_world(Vector2(i, j))
		else:
			#Se o comprimento for par
			if (int(lower_right_corner.y - vect_y) % 2) == 0:
				for i in range (vect_y, lower_right_corner.y + 1, 2):
					for j in range (vect_x, lower_right_corner.x + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = Map.map_to_world(Vector2(j, i))
			#Se comprimento for impar
			else:
				for i in range (vect_y + 1, lower_right_corner.y + 1, 2):
					for j in range (vect_x, lower_right_corner.x + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = Map.map_to_world(Vector2(j, i))
	elif num == 2:
		#Retangulo na Horizontal
		if (lower_right_corner.x - vect_x) >= (lower_right_corner.y - vect_y):
			#Se o comprimento for par
			if (int(lower_right_corner.x - vect_x) % 2) == 0:
				#Trap floor
				for i in range (vect_x, lower_right_corner.x + 1, 2):
					for j in range (vect_y, lower_right_corner.y + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = Map.map_to_world(Vector2(i, j))
				#Setas
				for i in range (vect_x + 1, lower_right_corner.x + 1, 2):
					var arrow_spawner = ArrowSpawner.instance()
					arrow_spawner.direction = "down"
					arrow_spawner.position = Map.map_to_world(Vector2(i, vect_y))
					add_child(arrow_spawner)
					
			#Se comprimento for impar
			else:
				# Trap floor
				for i in range (vect_x + 1, lower_right_corner.x + 1, 2):
					for j in range (vect_y, lower_right_corner.y + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = Map.map_to_world(Vector2(i, j))
				#Setas
				for i in range (vect_x, lower_right_corner.x + 1, 2):
					var arrow_spawner = ArrowSpawner.instance()
					arrow_spawner.direction = "down"
					arrow_spawner.position = Map.map_to_world(Vector2(i, vect_y))
					add_child(arrow_spawner)
				
		#Retangulo Vertical
		else:
			#Se o comprimento for par
			if (int(lower_right_corner.y - vect_y) % 2) == 0:
				#Trap Floor
				for i in range (vect_y, lower_right_corner.y + 1, 2):
					for j in range (vect_x, lower_right_corner.x + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = Map.map_to_world(Vector2(j, i))
				#Setas
				for i in range (vect_y + 1, lower_right_corner.y + 1, 2):
					var arrow_spawner = ArrowSpawner.instance()
					arrow_spawner.direction = "right"
					arrow_spawner.position = Map.map_to_world(Vector2(vect_x, i))
					add_child(arrow_spawner)
				
			#Se comprimento for impar
			else:
				#Trap Floor
				for i in range (vect_y + 1, lower_right_corner.y + 1, 2):
					for j in range (vect_x, lower_right_corner.x + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = Map.map_to_world(Vector2(j, i))
				#Setas
				for i in range (vect_y, lower_right_corner.y + 1, 2):
					var arrow_spawner = ArrowSpawner.instance()
					arrow_spawner.direction = "right"
					arrow_spawner.position = Map.map_to_world(Vector2(vect_x, i))
					add_child(arrow_spawner)

func treasure_room():
	var num_tresures = randi() % 4
	var num_false_floors = randi() % 6
	var room_index = randi() % len(total_area)
	#Gera Tesouros
	for i in num_tresures:
		var treasure = Treasure.instance()
		var pos = total_area[room_index][randi() % len(total_area[room_index])]
		add_child(treasure)
		treasure.position = Map.map_to_world(pos)
		total_area[room_index].erase(pos)
		
	#Gera Alçapões
	for i in num_false_floors:
		var false_floor = False_Floor.instance()
		var pos = total_area[room_index][randi() % len(total_area[room_index])]
		add_child(false_floor)
		false_floor.position = Map.map_to_world(pos)
		total_area[room_index].erase(pos)
	total_area.remove(room_index)
	
func puzzle_room():
	var room_index = randi() % len(total_area)
	var puzzle = Puzzle.instance()
	var num_min = int(ceil(len(total_area[room_index]) / 3))
	var num_max = int(num_min * 2)
	puzzle.position = Map.map_to_world(total_area[room_index][randi() % num_max + num_min])
	add_child(puzzle)
