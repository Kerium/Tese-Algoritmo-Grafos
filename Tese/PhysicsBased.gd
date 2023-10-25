extends Node2D

const Room = preload("res://Room.tscn")
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

var tile_size = 16
var num_rooms = 50
var min_size = 4
var max_size = 10
#how much we want the room layout to be bias to be horizontal
var horizontal_spread = 100 # AKA torna a geração horizontal
var cull = 0.5

var path # Astar pathfinding object
var room_areas = []
onready var Map = $TileMap

func _ready():
	randomize()
	make_rooms()
	yield(get_tree().create_timer(2.0), "timeout")
	make_map()
	node_level_generator()

func make_rooms():
	room_areas.clear()
	for i in range(num_rooms):
		var pos = Vector2(rand_range(-horizontal_spread, horizontal_spread), 0)
		var r = Room.instance()
		var width = min_size + randi() % (max_size - min_size)
		var height = min_size + randi() % (max_size - min_size)
		r.make_room(pos, Vector2(width, height) * tile_size)
		$Rooms.add_child(r)
	# wait for the movement to stop
	yield(get_tree().create_timer(1.1), "timeout")
	#cull the rooms
	var room_positions = []
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else: 
			room.mode = RigidBody2D.MODE_STATIC
			room.disable()
			room_positions.append(Vector2(room.position.x, room.position.y))
	yield(get_tree(), "idle_frame")
	# generate a minimun spanning tree connecting the rooms
	path = find_mst(room_positions)
	


# Comentar aqui
func _draw():
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size * 2), Color(32, 228, 0), false)
	
	if path:
		for p in path.get_points():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				draw_line(Vector2(pp.x, pp.y), Vector2(cp.x, cp.y), Color(1, 1, 0), 15, true)

func _process(delta):
	update()

func _input(event):
	if event.is_action_pressed("ui_select"):
		for n in $Rooms.get_children():
			n.queue_free()
		#path = null
		make_rooms()
	if event.is_action_pressed("ui_focus_next"):
		make_map()

func find_mst(nodes):
	# Prim's algorithm
	var path = AStar2D.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# repeat until no more nodes remain
	while nodes:
		var min_dist = INF # Minimum distance so far
		var min_p = null
		var p = null
		# Loop through all points in path
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			# Loop through the remaining nodes
			for p2 in nodes:
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		nodes.erase(min_p)
	return path

func make_map():
	#Create a tilemap from the generated rooms and path
	Map.clear()
	"""
	#Fill TileMap with walls, then carve empty rooms
	var full_rect = Rect2()
	for room in $Rooms.get_children():
		var r = Rect2(room.position - room.size, room.get_node("CollisionShape2D").shape.extents * 2)
	var topleft = Map.world_to_map(full_rect.position)
	var bottomright = Map.world_to_map(full_rect.end)
	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y, bottomright.y):
			Map.set_cell(x, y, 1)
	"""
	#Carve the rooms
	var corridors = [] # One corridor per connection
	var counter = 0
	for room in $Rooms.get_children():
		var s = (room.size / tile_size).floor()
		var pos = Map.world_to_map(room.position)
		var ul = (room.position / tile_size).floor() - s
		room_areas.append([])
		for x in range(2, s.x * 2 - 1):
			for y in range(2, s.y * 2 - 1):
				Map.set_cellv(Vector2(ul.x + x, ul.y + y), 0)
				Map.update_bitmask_area(Vector2(ul.x + x, ul.y + y))
				room_areas[counter].append(Vector2(ul.x + x, ul.y + y))
		counter += 1
				
			# Carve connecting corridor
		var p = path.get_closest_point(Vector2(room.position.x, room.position.y))
		for conn in path.get_point_connections(p):
			if not conn in corridors:
				var start = Map.world_to_map(Vector2(path.get_point_position(p).x, path.get_point_position(p).y))
				var end = Map.world_to_map(Vector2(path.get_point_position(conn).x, path.get_point_position(conn).y))
				carve_path(start, end)
		corridors.append(p)
	#print(room_areas)

func carve_path(pos1, pos2):
	#Carve a path between 2 points
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
		Map.set_cellv(Vector2(x, x_y.y + y_diff), 0)
		Map.update_bitmask_area(Vector2(x, x_y.y + y_diff))
	for y in range(pos1.y, pos2.y, y_diff):
		Map.set_cellv(Vector2(y_x.x, y), 0)
		Map.update_bitmask_area(Vector2(y_x.x, y))
		Map.set_cellv(Vector2(y_x.x + x_diff, y), 0)
		Map.update_bitmask_area(Vector2(y_x.x + x_diff, y))

func node_level_generator():
	var node_index = randi() % len(NODE_TYPES)
	var chance = randi() % 6
	var nodes = []
	
	while nodes.size() < (room_areas.size() - 1):
		if chance != 5:
			nodes.append(NODE_TYPES[node_index])
		else:
			break
		chance = randi() % 5
		node_index = randi() % len(NODE_TYPES)
	
	#CHAMAR AS FUNÇÕES
	#var spawn = funcref(self, "spawn")
	#var goal = funcref(self, "goal")
	var empty_room = funcref(self, "empty_room")
	var monster_house = funcref(self, "monster_house")
	var treasure_room = funcref(self, "treasure_room")
	var puzzle_room = funcref(self, "puzzle_room")
	
	var room_functions = {
		#"entry": spawn,
		#"end": goal,
		"empty_room": empty_room,
		"monster_house": monster_house,
		"treasure_room": treasure_room,
		"puzzle_room": puzzle_room,
	}
	
	for i in nodes:
		room_functions[i].call_func()
	print("Rooms nodes: " + str(nodes))
	lock_and_key()
	
#FUNÇÕES DE GERAÇÃO DAS FUCIONALIDADES DAS DIVISÕES
func lock_and_key():
	var door_and_key = Door_and_key.instance()
	var exit = Exit.instance()
	var index = randi() % len(room_areas)
	var index_door = randi() % len(room_areas)
	add_child(exit)
	add_child(door_and_key)
	exit.position = room_areas[index_door][randi() % len(room_areas[index_door])] * 16
	door_and_key.get_node("Door").position = exit.position
	door_and_key.get_node("Key").position = Map.map_to_world(room_areas[index][randi() % len(room_areas[index])])
	room_areas.remove(index_door)
	

func empty_room():
	var enemy = Enemy.instance()
	var num = randi() % 3
	var potion = Potion.instance()
	var index = randi() % len(room_areas)
	var area_list = room_areas[index]
	print("Empty Room number: " + str(num))
	
	if num == 2:
		add_child(enemy)
		enemy.position = Map.map_to_world(area_list[randi() % len(area_list)]) 
		add_child(potion)
		potion.position = Map.map_to_world(area_list[randi() % len(area_list)]) 
	elif num == 0:
		add_child(potion)
		potion.position = Map.map_to_world(area_list[randi() % len(area_list)]) 
	elif num == 1:
		add_child(enemy)
		enemy.position = Map.map_to_world(area_list[randi() % len(area_list)]) 
	room_areas.remove(index)

func monster_house():
	var num = (randi() % 3) + 3
	var index = randi() % len(room_areas)
	var area_list = room_areas[index]
	#print("Monster House enemies: " + str(num))
	for i in range(0, num):
		var enemy = Enemy.instance()
		enemy.group = true
		add_child(enemy)
	#print(get_tree().get_nodes_in_group("enemies"))
	# Iterar a lista com nodes de inimigos e remove a posição desses para não sobrepor
	for i in get_tree().get_nodes_in_group("enemies"):
		i.position = Map.map_to_world(area_list[randi() % len(area_list)]) 
		i.remove_group()
	room_areas.remove(index)

func treasure_room():
	var num_tresures = randi() % 4
	var num_false_floors = randi() % 6
	var index = randi() % len(room_areas)
	var area_list = room_areas[index]
	#Gera Tesouros
	for i in num_tresures:
		var treasure = Treasure.instance()
		add_child(treasure)
		treasure.position = Map.map_to_world(area_list[randi() % len(area_list)]) 
		
	#Gera Alçapões
	for i in num_false_floors:
		var false_floor = False_Floor.instance()
		add_child(false_floor)
		false_floor.position = Map.map_to_world(area_list[randi() % len(area_list)]) 
	room_areas.remove(index)

func puzzle_room():
	var puzzle = Puzzle.instance()
	var index = randi() % len(room_areas)
	var area_list = room_areas[index]
	puzzle.position = Map.map_to_world(area_list[randi() % len(area_list)]) 
	add_child(puzzle)
	room_areas.remove(index)
