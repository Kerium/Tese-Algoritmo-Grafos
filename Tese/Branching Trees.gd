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
var temp_room_area = [] # Area da divisão 
onready var astar = AStar2D.new()
var path

 
func _ready():
	randomize()
	generate_rooms()
	#yield(get_tree().create_timer(2.0), "timeout")
	#pathfinder()
	room_features()


func generate_rooms():
	var number_generated_rooms = 0
	var temp_center_rooms = []
	#var counter = 0 Usar se apenas se começar a demorar muito tempo
	
	while number_generated_rooms <= n_rooms:
		var center_room = Vector2(randi() % 38+4, randi() % 38+4)
		var width = randi() % 6 + 5
		var height = randi() % 6 + 5 
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
			temp_center_rooms.append(center_room)
			number_generated_rooms += 1
	#print("nº de total area: " + str(len(total_area)))
	#print("total_area: " + str(total_area))
	
	path = find_mst(temp_center_rooms)
	#print("ultimate path: " + str(path))
	var corridors = []
	print("Center rooms: " + str(center_rooms))
	var counter = 0
	for room in center_rooms:
		#var p = path.get_closest_point(Vector2(room.x, room.y))
		var p = counter
		for conn in path.get_point_connections(p):
			if not conn in corridors: #Map.map_to_world
				var start = (Vector2(path.get_point_position(p).x, path.get_point_position(p).y))
				var end = (Vector2(path.get_point_position(conn).x, path.get_point_position(conn).y))
				#print("start: " + str(start))
				#print("end: " + str(end))
				carve_path(start, end)
		counter += 1
		corridors.append(p)
	#print("Centro dos rooms: " + str(center_rooms))
	#for i in range(0, center_rooms.size() - 1):
		#carve_path(center_rooms[i], center_rooms[i + 1])
	#print("Total area: " + str(total_area))
"""
func pathfinder():
	var room_list = []
	var vect_index
	var neighbors = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)] 
	var first_point = Vector2.ZERO
	var list_for_lists = []
	#print("Rooms positions: " + str(total_area))
	#print(len(total_area))
	for i in range (0, len(total_area)): #Não "-1" pq para no proprio numero
		#Tentar garantir que não sai de lado TESTAR
		var boolean = true
		while boolean:
			vect_index = randi() % len(total_area[i]) 
			for j in neighbors:
				var next_cell = total_area[i][vect_index] + j
				if !((total_area[i][vect_index] - first_point) in neighbors) and ((total_area[i][vect_index] - first_point) != Vector2.ZERO):
					room_list.append(total_area[i][vect_index])
					boolean = false
					break
		if i == len(total_area) - 1:
			vect_index = randi() % len(total_area[0]) 
			room_list.append(total_area[0][vect_index])
			#var count = 1
	room_list.clear()
	for i in total_area:
		print("eu corri")
		var index = randi() % len(i)
		room_list.append(i[index])
		
	print("Room List: " + str(room_list))
	
	astar.reserve_space((60 + 4) * (60 + 4)) #width vs height
	
	var count = 0
	for i in range (0, 60 + 4):
		for j in range (0, 60 + 4):
			astar.add_point(count, Vector2(i, j))  #id(Vector2(i, j))
			count +=1
	
	for i in range(0, 4096): #astar.get_point_count()
		var cell = astar.get_point_position(i)
		print(str(cell))
		for neighbor in neighbors:
			var next_cell = cell + neighbor
			astar.connect_points(point_id(cell), point_id(next_cell))
	
	#Vertical
	for i in range(0, (50 + 2), 4):
		for j in range (0, (50 + 2)):
			var cell = Vector2(i, j)
			var next_cell = cell + Vector2(0, 1)
			astar.connect_points(point_id(cell), point_id(next_cell))
			next_cell = cell + Vector2(0, -1)
			astar.connect_points(point_id(cell), point_id(next_cell))

	#Horizontal
	for i in range (0, (50 + 2)):
		for j in range(0, (50 + 2)):
			#Para Baixo
			var cell = Vector2(j, i)
			var next_cell = cell + Vector2(1, 0)
			astar.connect_points(point_id(cell), point_id(next_cell))
			next_cell = cell + Vector2(-1, 0)
			astar.connect_points(point_id(cell), point_id(next_cell))
			
	for i in room_list:
		for j in neighbors:
			var next_cell = i + j
			astar.connect_points(point_id(i), point_id(next_cell))
	
	for i in range(0, room_list.size()-1):
		var path = astar.get_point_path(point_id(room_list[i]), point_id(room_list[i + 1]))
		print("room_list 1: " + str(room_list[i]))
		print("room_list 2: " + str(room_list[i+1]))
		#print("path: " + str(path))
		for j in path:
			Map.set_cellv(j, 0)
			Map.update_bitmask_area(j)
	
	
	for i in range (0, room_list.size() - 1, 2):
		var total_path = []
		var used_cells = Map.get_used_cells()
		var path = Map.get_astar_path_avoiding_obstacles(room_list[i], room_list[i + 1]) #astar.get_point_path(point_id(room_list[i]), point_id(room_list[i + 1]))
		print("Path: " + str(path))
		if !((room_list[i] + Vector2.RIGHT) in used_cells) or !((room_list[i] + Vector2.LEFT) in used_cells):
			var temp_point = Vector2(room_list[i+1].x, room_list[i].y)
			path = Map.get_astar_path_avoiding_obstacles(room_list[i], temp_point) 
			total_path.append_array(path)
			for j in range (0, path.size()):
				Map.set_cellv(path[j], 0)
				Map.update_bitmask_area(path[j])
				var obstacle = Obstacle.instance()
				obstacle.position = Map.map_to_world(path[j])
				Map.add_child(obstacle)
				
			#tileMap.obstacle_update()
			path = Map.get_astar_path_avoiding_obstacles(temp_point, room_list[i + 1])
			total_path.append_array(path)
			for j in range (0, path.size()):
				Map.set_cellv(path[j], 0)
				Map.update_bitmask_area(path[j])
				var obstacle = Obstacle.instance()
				obstacle.position = Map.map_to_world(path[j])
				Map.add_child(obstacle)
			print("O direita esquerda correu")
		
		elif !((room_list[i] + Vector2.UP) in used_cells) or !((room_list[i] + Vector2.DOWN) in used_cells):
			var temp_point = Vector2(room_list[i].x, room_list[i+1].y)
			path = Map.get_astar_path_avoiding_obstacles(room_list[i], temp_point)
			total_path.append_array(path)
			for j in range (0, path.size()):
				Map.set_cellv(path[j], 0)
				Map.update_bitmask_area(path[j])
				var obstacle = Obstacle.instance()
				obstacle.position = Map.map_to_world(path[j])
				Map.add_child(obstacle)
			
			#tileMap.obstacle_update()
			path = Map.get_astar_path_avoiding_obstacles(temp_point, room_list[i + 1])
			total_path.append_array(path)
			for j in range (0, path.size()):
				Map.set_cellv(path[j], 0)
				Map.update_bitmask_area(path[j])
				var obstacle = Obstacle.instance()
				obstacle.position = Map.map_to_world(path[j])
				Map.add_child(obstacle)
			print("O cima baixo correu")
		else:
			print("path " + str(path))
			total_path.append_array(path)
			for j in range (0, path.size()):
				Map.set_cellv(path[j], 0)
				Map.update_bitmask_area(path[j])
				var obstacle = Obstacle.instance()
				obstacle.position = Map.map_to_world(path[j])
				Map.add_child(obstacle)
		#tileMap.obstacle_update()
"""

func find_mst(vectors):
	# Prim's algorithm
	var path = AStar2D.new()
	path.add_point(path.get_available_point_id(), vectors.pop_front())
	
	# repeat until no more nodes remain
	
	while vectors:
		var min_dist = INF # Minimum distance so far
		var min_p = null
		var p = null
		# Loop through all points in path
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			# Loop through the remaining nodes
			for p2 in vectors:
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		vectors.erase(min_p)
	return path

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
	var chance = randi() % 7
	var node_index = randi() % len(NODE_TYPES)
	
	while nodes.size() < (total_area.size() - 1) and nodes.size() < n_rooms:
		if chance < 6:
			nodes.append(NODE_TYPES[node_index])
		else:
			break
		chance = randi() % 7
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
	door_and_key.get_node("Key").position = Map.map_to_world(total_area[index][randi() % len(total_area[index])])
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

func point_id(vect):
	var a = vect.x
	var b = vect.y
	return a * (60 + 4) + b
