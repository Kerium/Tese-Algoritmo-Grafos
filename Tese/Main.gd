extends Node2D

const Level = preload("res://EmptyRoom.tscn")
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
#const Astar = preload("res://AstarTileMap.gd")


var player = Player.instance()

var nodes_list = [["entry"], [], ["end"], []]
const NODE_TYPES = ["empty_room", "monster_house", "trap_room", "treasure_room", "puzzle_room"]
var width = 56 # exportar | Vetores
var height = 42 # exportar
var v_divisions = 4 #exportar
var h_divisions = 3 #exportar
var x_steps = [] #função grid 
var y_steps = []
var x_position
var y_position
var rooms_positions = [] #vect2 com áreas das salas
var room_area = [] #Lista que guarda area da divisão e gera itens/inimigos /level generator
var grid = [] #Utilizado na função level generator
var node_list_duplicate = [] #Level generator e new_nodes()
var vetor #Level Generator
onready var tileMap = $TileMap
#onready var astar = AStar2D.new()
#onready var astar2 = Astar.new()
var locked_door = true
var point_end #Ponto a usar em Pathfinding e Goal para porta
var index_array_in_array = [] #saber indices para usar do pathfinder
var key_position = Vector2.ZERO

#SCRIPT DO ASTAR
const DIRECTIONS = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]

var obstacles = []
var units = []


"""
class MyAStar:
	extends AStar2D
	
	func _compute_cost(u, v):
		#abs(neighbor.position[0] - start_node.position[0]) + abs(neighbor.position[1] - start_node.position[1])
		return abs(v - u) 
		#return abs(u - v)
	func _estimate_cost(u, v):
		return abs(v - u) 
		#return min(0, abs(u - v) - 1)
"""
func _ready():
	randomize()
	grid()
	new_nodes()
	tileMap.update() #Script do Astar
	pathfinder()


func grid():
	var steps_width = width / v_divisions
	var steps_height = height / h_divisions
	
	for i in range(0, width + steps_width, steps_width):
		x_steps.append(i)
	for i in range(0, height + steps_height, steps_height):
		y_steps.append(i)
	
	print("x_steps: " + str(x_steps))
	print("y_steps: " + str(y_steps))


func new_nodes():
	var rand_number = randi() % 5
	var list_choice = numb_list_gen() #Aleatoriedade de qual lista ele poe o node
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
	
	print("length de nodes: " + str(len(nodes_list))) #talvez apagar
	# Gerar sempre 3 rooms no minimo
	nodes_list[list_choice].append(NODE_TYPES[randi() % len(NODE_TYPES)])
	nodes_list[list_choice].append(NODE_TYPES[randi() % len(NODE_TYPES)]) 
	nodes_list[list_choice].append(NODE_TYPES[randi() % len(NODE_TYPES)]) 

	while rand_number < 3:
		var list_in_list = randi() % 6 #probabilidade de adicionar uma lista dentro da lista
		list_choice = numb_list_gen()
		if list_in_list == 0:
			nodes_list[list_choice].append([])
			var list_index = nodes_list[list_choice].find([])
			nodes_list[list_choice][list_index].append(NODE_TYPES[randi() % len(NODE_TYPES)])
			nodes_list[list_choice].append(NODE_TYPES[randi() % len(NODE_TYPES)])
			rand_number = randi() % 5 
		else:
			nodes_list[list_choice].append(NODE_TYPES[randi() % len(NODE_TYPES)])
			rand_number = randi() % 5
	
	print(nodes_list)
	
	for i in nodes_list:
		if i is Array:
			for j in i:
				node_list_duplicate.append(j)
				#index_array_in_array.append(j) está mal, fazer count no for, e adicionar no fim
		else:
			node_list_duplicate.append(i)
	
	#print("index array " + str(index_array_in_array))
	
		#Se existe porta
	if randi() % 4 >= 2:
		locked_door = true
	
	for i in node_list_duplicate:
		#Comentar o if (não o else)
		if i is Array:
			for j in range (len(i)):
				level_generator()
				print(room_area == rooms_positions[len(grid) - 1])
				for g in rooms_positions[len(grid) - 1]: # Remover perimetro do room area
					room_area.erase(j)
				room_functions[i[j]].call_func() #[len(grid) - 1]
				for g in room_area:
					var obstacle = Obstacle.instance()
					obstacle.position = tileMap.map_to_world(g)
					add_child(obstacle)
				key_position = room_area[randi() % len(room_area)]
				room_area.clear()
		else:
			level_generator()
			for j in rooms_positions[len(grid) - 1]: # Remover perimetro
				room_area.erase(j)
			room_functions[node_list_duplicate[len(grid) - 1]].call_func()
			for g in room_area:
					var obstacle = Obstacle.instance()
					obstacle.position = tileMap.map_to_world(g)
					add_child(obstacle)
			if locked_door and key_position == Vector2.ZERO:
					key_position = room_area[randi() % len(room_area)]
			if key_position != Vector2.ZERO and (randi() % 4) <= 1:
				key_position = room_area[randi() % len(room_area)]
			room_area.clear()
	
	

# define as coordenadas e desenha as salas
func level_generator():
	var loop = true

	while loop:
		var indice_x = randi() % (len(x_steps) - 1)
		x_position = round(rand_range(x_steps[indice_x], x_steps[indice_x + 1] - (round((x_steps[indice_x + 1] - x_steps[indice_x])/2))))
		var indice_y = randi() % (len(y_steps) - 1)
		y_position = round(rand_range(y_steps[indice_y], y_steps[indice_y + 1] - (round((y_steps[indice_y + 1] - y_steps[indice_y])/2))))
		var width_x = round(rand_range(x_position + randi() % 4 + 3, x_steps[indice_x + 1]))
		var height_y = round(rand_range(y_position + randi() % 4 + 3, y_steps[indice_y + 1]))
		vetor = Vector2(indice_x, indice_y)
		if !grid.has(vetor):
			grid.append(vetor)
			rooms_positions.append([])
			for i in range (x_position, width_x + 1):
				rooms_positions[len(grid)-1].append(Vector2(i, y_position))
				rooms_positions[len(grid)-1].append(Vector2(i, height_y))
			for i in range (y_position, height_y + 1):
				rooms_positions[len(grid)-1].append(Vector2(x_position, i))
				rooms_positions[len(grid)-1].append(Vector2(width_x, i))
			
			for x in range (x_position, width_x + 1):
				for y in range(y_position, height_y + 1):
					var vect = Vector2(x, y)
					tileMap.set_cellv(vect, 0) #Aplica os tiles
					tileMap.update_bitmask_area(vect)
					room_area.append(vect)
					
			loop = false


"""
func level_generator():
	var length = get_length_list(nodes_list) #quantidade de nodes
	print("length: " + str(length))
	var grid = []
	var vetor
	var node_list_duplicate = []
	for i in nodes_list:
		node_list_duplicate.append_array(i)
	
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
	
	while len(grid) != length:
		var indice_x = randi() % (len(x_steps) - 1)
		x_position = round(rand_range(x_steps[indice_x], x_steps[indice_x + 1] - (round((x_steps[indice_x + 1] - x_steps[indice_x])/2))))
		var indice_y = randi() % (len(y_steps) - 1)
		y_position = round(rand_range(y_steps[indice_y], y_steps[indice_y + 1] - (round((y_steps[indice_y + 1] - y_steps[indice_y])/2))))
		var width_x = round(rand_range(x_position + randi() % 4 + 3, x_steps[indice_x + 1]))
		var height_y = round(rand_range(y_position + randi() % 4 + 3, y_steps[indice_y + 1]))
		vetor = Vector2(indice_x, indice_y)
		if !grid.has(vetor):
			grid.append(vetor)
			rooms_positions.append([])
			for i in range (x_position, width_x + 1):
				rooms_positions[len(grid)-1].append(Vector2(i, y_position))
				rooms_positions[len(grid)-1].append(Vector2(i, height_y))
			for i in range (y_position, height_y + 1):
				rooms_positions[len(grid)-1].append(Vector2(x_position, i))
				rooms_positions[len(grid)-1].append(Vector2(width_x, i))
			
			for x in range (x_position, width_x + 1):
				for y in range(y_position, height_y + 1):
					var vect = Vector2(x, y)
					tileMap.set_cellv(vect, 0) #Aplica os tiles
					tileMap.update_bitmask_area(vect)
					room_area.append(vect)
			
			#print("X_position: " + str(x_position) + " Y_position: " + str(y_position))
			#print("Width: " + str(width_x) + " Height: " + str(height_y))
			#print("room area before: " + str(room_area))
					
			for i in rooms_positions[len(grid) - 1]: # Remover perimetro
				room_area.erase(i)
				
			#print("room area: " + str(room_area))
			room_functions[node_list_duplicate[len(grid) - 1]].call_func()
			room_area.clear()
	"""

func pathfinder():
	var room_list = []
	var vect_index
	var neighbors = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)] 
	var first_point = Vector2.ZERO
	var list_for_lists = []
	#print("Rooms positions: " + str(rooms_positions))
	#print(len(rooms_positions))
	for i in range (0, len(rooms_positions)): #Não "-1" pq para no proprio numero
		if i > 0:
			#Caso node esteja dentro de array
			if node_list_duplicate[i] is Array:
				if !(i == node_list_duplicate.size() - 1): #
					if node_list_duplicate[i+1]:
						vect_index = randi() % len(rooms_positions[i])
						list_for_lists.append(rooms_positions[i][vect_index])
						vect_index = randi() % len(rooms_positions[i+1])
						list_for_lists.append(rooms_positions[i+1][vect_index])
					else:
						vect_index = randi() % len(rooms_positions[i])
						list_for_lists.append(rooms_positions[i][vect_index])
						vect_index = randi() % len(rooms_positions[i-1])
						list_for_lists.append(rooms_positions[i-1][vect_index])
				else:
					vect_index = randi() % len(rooms_positions[i])
					list_for_lists.append(rooms_positions[i][vect_index])
					vect_index = randi() % len(rooms_positions[i-1])
					list_for_lists.append(rooms_positions[i-1][vect_index])
			else:
				vect_index = randi() % len(rooms_positions[i])
				first_point = rooms_positions[i][vect_index]
				room_list.append(first_point)
				if node_list_duplicate[i] == "end": #Adaptar arrays com arrays
					lock_and_key(i, first_point)
		#Tentar garantir que não sai de lado TESTAR
		var boolean = true
		while boolean:
			vect_index = randi() % len(rooms_positions[i]) 
			for j in neighbors:
				var next_cell = rooms_positions[i][vect_index] + j
				if !((rooms_positions[i][vect_index] - first_point) in neighbors) and ((rooms_positions[i][vect_index] - first_point) != Vector2.ZERO):
					room_list.append(rooms_positions[i][vect_index])
					boolean = false
					break
		if i == len(rooms_positions) - 1:
			vect_index = randi() % len(rooms_positions[0]) 
			room_list.append(rooms_positions[0][vect_index])
			#var count = 1
			"""for g in range (0, len(nodes_list)): #Suspeito que estou a inserir o ultimo node, tenho que rescrever
				if !nodes_list[g].empty():
					if nodes_list[g].has("end"):
						count -= 1
						vect_index = int(rand_range(0, len(rooms_positions[count])))
						room_list.append(rooms_positions[count][vect_index])
					count += nodes_list[g].size()
				else:
					count += 1 #Po indice 
	for i in range (0, room_list.size() - 1):
		var used_cells = tileMap.get_used_cells()
		var temp = check_path(room_list[i], room_list[i+1], used_cells)
		print("Check Path: " + str(temp))
	print("room list: " + str(room_list)) # Coordenadas dos pontos de divisões e corredores
	print("size room list: " + str(room_list.size()))

	
	
	astar.reserve_space((width + 4) * (height + 4)) #width vs height
	#astar2.reserve_space((width + 4) * (height + 4)) #width vs height
	var count = 0
	for i in range (0, width + 4):
		for j in range (0, height + 4):
			astar.add_point(count, Vector2(i, j))  #id(Vector2(i, j))
			count +=1

	#print("astar point count: " + str(astar.get_point_count()))
	#print("astar index: " + str(astar.get_points()))
	#Une todas as células (direita, esquerda, baixo, cima
	for i in range(0, astar.get_point_count()):
		var cell = astar.get_point_position(i)
		for neighbor in neighbors:
			var next_cell = cell + neighbor
			astar.connect_points(point_id(cell), point_id(next_cell))
	
	#Vertical
	for i in range(0, (width + 2), 2):
		for j in range (0, (height + 2)):
			var cell = Vector2(i, j)
			var next_cell = cell + Vector2(0, 1)
			astar.connect_points(point_id(cell), point_id(next_cell))

	#Horizontal
	for i in range (0, (height + 2), 2):
		for j in range(0, (width + 2)):
			#Para Baixo
			var cell = Vector2(j, i)
			var next_cell = cell + Vector2(1, 0)
			astar.connect_points(point_id(cell), point_id(next_cell))
	
	for i in room_list:
		for j in neighbors:
			var next_cell = i + j
			astar.connect_points(point_id(i), point_id(next_cell))
	
	
	# Retirar divisões células já utilizadas (menos os que estão na room_list)
	var points_to_disconnect = tileMap.get_used_cells()
	for i in room_list:
		points_to_disconnect.erase(i)
	
	for i in points_to_disconnect:
		var cell = i
		for j in neighbors:
			var next_cell = cell + j
			astar.disconnect_points(point_id(i), point_id(next_cell))
		astar.remove_point(point_id(i))
	"""
	print("Room List: " + str(room_list))
	
	for i in range (0, room_list.size() - 1, 2):
		var total_path = []
		var used_cells = tileMap.get_used_cells()
		var path = tileMap.get_astar_path_avoiding_obstacles(room_list[i], room_list[i + 1]) #astar.get_point_path(point_id(room_list[i]), point_id(room_list[i + 1]))
		#print("Path: " + str(path))
		if !((room_list[i] + Vector2.RIGHT) in used_cells) or !((room_list[i] + Vector2.LEFT) in used_cells):
			var temp_point = Vector2(room_list[i+1].x, room_list[i].y)
			path = tileMap.get_astar_path_avoiding_obstacles(room_list[i], temp_point) 
			total_path.append_array(path)
			for j in range (0, path.size()):
				tileMap.set_cellv(path[j], 0)
				tileMap.update_bitmask_area(path[j])
				var obstacle = Obstacle.instance()
				obstacle.position = tileMap.map_to_world(path[j])
				tileMap.add_child(obstacle)
				
			#tileMap.obstacle_update()
			path = tileMap.get_astar_path_avoiding_obstacles(temp_point, room_list[i + 1])
			total_path.append_array(path)
			for j in range (0, path.size()):
				tileMap.set_cellv(path[j], 0)
				tileMap.update_bitmask_area(path[j])
				var obstacle = Obstacle.instance()
				obstacle.position = tileMap.map_to_world(path[j])
				tileMap.add_child(obstacle)
			print("O direita esquerda correu")
		
		elif !((room_list[i] + Vector2.UP) in used_cells) or !((room_list[i] + Vector2.DOWN) in used_cells):
			var temp_point = Vector2(room_list[i].x, room_list[i+1].y)
			path = tileMap.get_astar_path_avoiding_obstacles(room_list[i], temp_point)
			total_path.append_array(path)
			for j in range (0, path.size()):
				tileMap.set_cellv(path[j], 0)
				tileMap.update_bitmask_area(path[j])
				var obstacle = Obstacle.instance()
				obstacle.position = tileMap.map_to_world(path[j])
				tileMap.add_child(obstacle)
			
			#tileMap.obstacle_update()
			path = tileMap.get_astar_path_avoiding_obstacles(temp_point, room_list[i + 1])
			total_path.append_array(path)
			for j in range (0, path.size()):
				tileMap.set_cellv(path[j], 0)
				tileMap.update_bitmask_area(path[j])
				var obstacle = Obstacle.instance()
				obstacle.position = tileMap.map_to_world(path[j])
				tileMap.add_child(obstacle)
			print("O cima baixo correu")
		else:
			#print("path " + str(path))
			total_path.append_array(path)
			for j in range (0, path.size()):
				tileMap.set_cellv(path[j], 0)
				tileMap.update_bitmask_area(path[j])
				var obstacle = Obstacle.instance()
				obstacle.position = tileMap.map_to_world(path[j])
				tileMap.add_child(obstacle)
		#tileMap.obstacle_update()
		"""
		for j in total_path:
			for r in neighbors:
				var next_cell = j + r
				astar.disconnect_points(point_id(j), point_id(next_cell))
			#astar.remove_point(point_id(j))	
		total_path.clear()


	print("id point1: " + str(astar.get_point_position(point_id(room_list[0]))))
	print("id: " + str(point_id(room_list[0])))
	print("id point2: " + str(astar.get_point_position(point_id(room_list[1]))))
	print("id: " + str(point_id(room_list[1])))
	print("path: " + str(astar.get_point_path(point_id(room_list[0]), point_id(room_list[1]))))

	


	for i in range (0, room_list.size() - 1):
		var room0 = room_list[i]
		var room1 = room_list[i + 1]
		var diffx = room1.x - room0.x
		var diffy = room1.y - room0.y
		var cells_used = tileMap.get_used_cells() #Pontos já usados
		#Remover os pontos que vamos utilizar para os caminhos
		for j in room_list:
			cells_used.erase(j)
		
		if diffx < 0 && diffy < 0:
			while room0 != room1:
				
				#Eixo X
				var rand = round(rand_range(diffx , 0))
				diffx -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x - j, room0.y), 0)
					tileMap.update_bitmask_area(Vector2(room0.x - j, room0.y))
				room0.x += rand
				#print("roomx 0: " + str(room0))
				# Eixo Y
				rand = round(rand_range(diffy , 0))
				diffy -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x, room0.y - j), 0)
					tileMap.update_bitmask_area(Vector2(room0.x, room0.y - j))
				room0.y += rand
				#print("roomy 0: " + str(room0))
		
		elif diffx > 0 && diffy > 0:
			while room0 != room1:
				var rand = round(rand_range(0 , diffx))
				diffx -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x + j, room0.y), 0)
					tileMap.update_bitmask_area(Vector2(room0.x + j, room0.y))
				room0.x += rand
				#print("roomx 0: " + str(room0))
				# Eixo Y
				rand = round(rand_range(0 , diffy))
				diffy -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x, room0.y + j), 0)
					tileMap.update_bitmask_area(Vector2(room0.x, room0.y + j))
				room0.y += rand
				#print("roomy 0: " + str(room0))

		elif diffx < 0 && diffy > 0:
			while room0 != room1:
				var rand = round(rand_range(diffx , 0))
				diffx -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x - j, room0.y), 0)
					tileMap.update_bitmask_area(Vector2(room0.x - j, room0.y))
				room0.x += rand
				#print("roomx 0: " + str(room0))
				# Eixo Y
				rand = round(rand_range(0 , diffy))
				diffy -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x, room0.y + j), 0)
					tileMap.update_bitmask_area(Vector2(room0.x, room0.y + j))
				room0.y += rand
				#print("roomy 0: " + str(room0))

		elif diffx > 0 && diffy < 0:
			while room0 != room1:
				var rand = round(rand_range(0 , diffx))
				diffx -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x + j, room0.y), 0)
					tileMap.update_bitmask_area(Vector2(room0.x + j, room0.y))
				room0.x += rand
				#print("roomx 0: " + str(room0))
				# Eixo Y
				rand = round(rand_range(diffy , 0))
				diffy -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x, room0.y - j), 0)
					tileMap.update_bitmask_area(Vector2(room0.x, room0.y - j))
				room0.y += rand
				#print("roomy 0: " + str(room0))
				

	for i in range(1, room_list.size() - 2, 2):
		var room0 = room_list[i]
		var room1 = room_list[i + 2]
		var diffx = room1.x - room0.x
		var diffy = room1.y - room0.y
		#print(str(round(rand_range(-1, 0))))
		print("room 1: " + str(room1))
		var teste = ["teste"]
		print(teste.has([]))
		
		if diffx < 0 && diffy < 0:
			while room0 != room1:
				#Eixo X
				var rand = round(rand_range(diffx , 0))
				diffx -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x - j, room0.y), 0)
					tileMap.update_bitmask_area(Vector2(room0.x - j, room0.y))
				room0.x += rand
				#print("roomx 0: " + str(room0))
				# Eixo Y
				rand = round(rand_range(diffy , 0))
				diffy -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x, room0.y - j), 0)
					tileMap.update_bitmask_area(Vector2(room0.x, room0.y - j))
				room0.y += rand
				#print("roomy 0: " + str(room0))
		
		elif diffx > 0 && diffy > 0:
			while room0 != room1:
				var rand = round(rand_range(0 , diffx))
				diffx -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x + j, room0.y), 0)
					tileMap.update_bitmask_area(Vector2(room0.x + j, room0.y))
				room0.x += rand
				#print("roomx 0: " + str(room0))
				# Eixo Y
				rand = round(rand_range(0 , diffy))
				diffy -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x, room0.y + j), 0)
					tileMap.update_bitmask_area(Vector2(room0.x, room0.y + j))
				room0.y += rand
				#print("roomy 0: " + str(room0))

		elif diffx < 0 && diffy > 0:
			while room0 != room1:
				var rand = round(rand_range(diffx , 0))
				diffx -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x - j, room0.y), 0)
					tileMap.update_bitmask_area(Vector2(room0.x - j, room0.y))
				room0.x += rand
				#print("roomx 0: " + str(room0))
				# Eixo Y
				rand = round(rand_range(0 , diffy))
				diffy -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x, room0.y + j), 0)
					tileMap.update_bitmask_area(Vector2(room0.x, room0.y + j))
				room0.y += rand
				#print("roomy 0: " + str(room0))

		elif diffx > 0 && diffy < 0:
			while room0 != room1:
				var rand = round(rand_range(0 , diffx))
				diffx -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x + j, room0.y), 0)
					tileMap.update_bitmask_area(Vector2(room0.x + j, room0.y))
				room0.x += rand
				#print("roomx 0: " + str(room0))
				# Eixo Y
				rand = round(rand_range(diffy , 0))
				diffy -= rand
				for j in range (0, abs(rand)):
					tileMap.set_cellv(Vector2(room0.x, room0.y - j), 0)
					tileMap.update_bitmask_area(Vector2(room0.x, room0.y - j))
				room0.y += rand
				#print("roomy 0: " + str(room0))
"""
func spawn():
	add_child(player)
	player.position = tileMap.map_to_world(room_area[randi() % len(room_area)])

func goal():
	var exit = Exit.instance()
	add_child(exit)
	exit.position = tileMap.map_to_world(room_area[randi() % len(room_area)]) 


func lock_and_key(index, vect):
	point_end = vect
	var key_index = 0

	var door_and_key = Door_and_key.instance()
	add_child(door_and_key)
	door_and_key.get_node("Door").position = tileMap.map_to_world(point_end)
	while key_index == index or key_index == 0:
		key_index = randi() % len(rooms_positions)
	door_and_key.get_node("Key").position = tileMap.map_to_world(key_position) #rooms_positions[key_index][randi() % len(rooms_positions[key_index])]
	print("Key vect: " + str(door_and_key.get_node("Key").position))

func empty_room():
	var enemy = Enemy.instance()
	var num = randi() % 4
	var potion = Potion.instance()
	print("Empty Room number: " + str(num))
	
	if num == 2:
		add_child(enemy)
		enemy.position = tileMap.map_to_world(room_area[randi() % len(room_area)])
		add_child(potion)
		potion.position = tileMap.map_to_world(room_area[randi() % len(room_area)])
	elif num == 0:
		add_child(potion)
		potion.position = tileMap.map_to_world(room_area[randi() % len(room_area)])
	elif num == 1:
		add_child(enemy)
		enemy.position = tileMap.map_to_world(room_area[randi() % len(room_area)])

func monster_house():
	var num = (randi() % 3) + 3
	#print("Monster House enemies: " + str(num))
	for i in range(0, num):
		var enemy = Enemy.instance()
		enemy.group = true
		add_child(enemy)
	#print(get_tree().get_nodes_in_group("enemies"))
	# Iterar a lista com nodes de inimigos e remove a posição desses para não sobrepor
	for i in get_tree().get_nodes_in_group("enemies"):
		var index = room_area[randi() % len(room_area)]
		i.position = tileMap.map_to_world(index) 	
		i.remove_group()
		room_area.erase(index)

func trap_room():
	var num = randi() % 3
	var lower_right_corner = Vector2.ZERO
	var vect_x = room_area[0].x 
	var vect_y = room_area[0].y
	
	for i in room_area: # MUDAR PARA ROOM_AREA[-1]
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
						trap_floor.position = tileMap.map_to_world(Vector2(i, j))
			else:
				for i in range (vect_x + 1, lower_right_corner.x + 1, 2):
					for j in range (vect_y, lower_right_corner.y + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = tileMap.map_to_world(Vector2(i, j))
		else:
			#Se o comprimento for par
			if (int(lower_right_corner.y - vect_y) % 2) == 0:
				for i in range (vect_y, lower_right_corner.y + 1, 2):
					for j in range (vect_x, lower_right_corner.x + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = tileMap.map_to_world(Vector2(j, i))
			#Se comprimento for impar
			else:
				for i in range (vect_y + 1, lower_right_corner.y + 1, 2):
					for j in range (vect_x, lower_right_corner.x + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = tileMap.map_to_world(Vector2(j, i))
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
						trap_floor.position = tileMap.map_to_world(Vector2(i, j))
				#Setas
				for i in range (vect_x + 1, lower_right_corner.x + 1, 2):
					var arrow_spawner = ArrowSpawner.instance()
					arrow_spawner.direction = "down"
					arrow_spawner.position = tileMap.map_to_world(Vector2(i, vect_y))
					add_child(arrow_spawner)
					
			#Se comprimento for impar
			else:
				# Trap floor
				for i in range (vect_x + 1, lower_right_corner.x + 1, 2):
					for j in range (vect_y, lower_right_corner.y + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = tileMap.map_to_world(Vector2(i, j))
				#Setas
				for i in range (vect_x, lower_right_corner.x + 1, 2):
					var arrow_spawner = ArrowSpawner.instance()
					arrow_spawner.direction = "down"
					arrow_spawner.position = tileMap.map_to_world(Vector2(i, vect_y))
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
						trap_floor.position = tileMap.map_to_world(Vector2(j, i))
				#Setas
				for i in range (vect_y + 1, lower_right_corner.y + 1, 2):
					var arrow_spawner = ArrowSpawner.instance()
					arrow_spawner.direction = "right"
					arrow_spawner.position = tileMap.map_to_world(Vector2(vect_x, i))
					add_child(arrow_spawner)
				
			#Se comprimento for impar
			else:
				#Trap Floor
				for i in range (vect_y + 1, lower_right_corner.y + 1, 2):
					for j in range (vect_x, lower_right_corner.x + 2):
						var trap_floor = Trap_Floor.instance()
						add_child(trap_floor)
						trap_floor.position = tileMap.map_to_world(Vector2(j, i))
				#Setas
				for i in range (vect_y, lower_right_corner.y + 1, 2):
					var arrow_spawner = ArrowSpawner.instance()
					arrow_spawner.direction = "right"
					arrow_spawner.position = tileMap.map_to_world(Vector2(vect_x, i))
					add_child(arrow_spawner)

func treasure_room():
	var num_tresures = randi() % 4 + 1
	var num_false_floors = randi() % 5
	
	#Gera Tesouros
	for i in num_tresures:
		var treasure = Treasure.instance()
		var vect = room_area[randi() % len(room_area)]
		add_child(treasure)
		treasure.position = tileMap.map_to_world(vect)
		room_area.erase(vect)
		
	#Gera Alçapões
	for i in num_false_floors:
		var false_floor = False_Floor.instance()
		var vect = room_area[randi() % len(room_area)]
		add_child(false_floor)
		false_floor.position = tileMap.map_to_world(vect)
		room_area.erase(vect)
	
func puzzle_room():
	var puzzle = Puzzle.instance()
	var num_min = int(ceil(len(room_area) / 3))
	var num_max = int(num_min * 2)
	puzzle.position = tileMap.map_to_world(room_area[randi() % num_max + num_min])
	add_child(puzzle)

func check_path(room0, room1, used_cells):
	var cell = room0
	var temp_path = [cell]
	var diff_x = room1.x - room0.x
	var diff_y = room1.y - room0.y
	var temp_diff_x = diff_x
	var temp_diff_y = diff_y
	var temp
	var boolean = true
	
	while !(cell == room1):
		#Máxima reta de 6 unidades no else
		if abs(temp_diff_x) < 6:
			#Se diff_x for positivo
			if temp_diff_x > 0:
				for i in range(temp_diff_x):
					temp = cell + Vector2(1, 0)
					if !(temp in used_cells):
						cell.x += 1
						temp_path.append(cell)
					else: 
						while !((cell + Vector2(1, 0)) in used_cells):
							if diff_y >= 0:
								cell.y += 1
								temp_diff_y -= 1
							elif diff_y < 0:
								cell.y -= 1
								temp_diff_y += 1
							temp_path.append(cell)
						cell.x += 1
						temp_path.append(cell)
				temp_diff_x = 0
			#Se diff_x for negativo
			elif temp_diff_x < 0:
				for i in range(abs(temp_diff_x)):
					temp = cell + Vector2(-1, 0)
					if !(temp in used_cells):
						cell.x -= 1
						temp_path.append(cell)
					else: 
						while !((cell + Vector2(-1, 0)) in used_cells):
							if diff_y >= 0:
								cell.y += 1
								temp_diff_y -= 1
							elif diff_y < 0:
								cell.y -= 1
								temp_diff_y += 1
							temp_path.append(cell)
						cell.x -= 1
						temp_path.append(cell)
				temp_diff_x = 0
		#Se diff_x for maior que 6
		else: 
			#Se diff_x for positivo
			if temp_diff_x > 0:
				for i in range(6):
					temp = cell + Vector2(1, 0)
					if !(temp in used_cells):
						cell.x += 1
						temp_path.append(cell)
						temp_diff_x -= 1
					else: 
						while !((cell + Vector2(1, 0)) in used_cells):
							if diff_y >= 0:
								cell.y += 1
								temp_diff_y -= 1
							elif diff_y < 0:
								cell.y -= 1
								temp_diff_y += 1
							temp_path.append(cell)
						cell.x += 1
						temp_diff_x -= 1 
						temp_path.append(cell)
			#Se diff_x for negativo
			elif temp_diff_x < 0:
					for i in range(6):
						temp = cell + Vector2(-1, 0)
						if !(temp in used_cells):
							cell.x -= 1
							temp_path.append(cell)
							temp_diff_x += 1
						else: 
							while !((cell + Vector2(-1, 0)) in used_cells):
								if diff_y >= 0:
									cell.y += 1
									temp_diff_y -= 1
								elif diff_y < 0:
									cell.y -= 1
									temp_diff_y += 1
								temp_path.append(cell)
							cell.x -= 1
							temp_diff_x += 1 
							temp_path.append(cell)
		#Máxima reta de 6 unidades no else
		if abs(temp_diff_y) < 6:
			#Se diff_y for positivo
			if temp_diff_y > 0:
				for i in range(temp_diff_y):
					temp = cell + Vector2(0, 1)
					#Andar na vertical se possivel
					if !(temp in used_cells):
						cell.y += 1
						temp_path.append(cell)
					else: 
						#Andar na horizontal se não
						while !((cell + Vector2(0, 1)) in used_cells):
							if diff_x >= 0:
								cell.x += 1
								temp_diff_x -= 1
							elif diff_x < 0:
								cell.x -= 1
								temp_diff_x += 1
							temp_path.append(cell)
						cell.y += 1
						temp_path.append(cell)
				temp_diff_y = 0
			#Se diff_x for negativo
			elif temp_diff_y < 0:
				for i in range(abs(temp_diff_y)): #talvez abs
					temp = cell + Vector2(0, -1)
					if !(temp in used_cells):
						cell.y -= 1
						temp_path.append(cell)
					else: 
						while !((cell + Vector2(0, -1)) in used_cells):
							if diff_x >= 0:
								cell.x += 1
								temp_diff_x -= 1
							elif diff_x < 0:
								cell.x -= 1
								temp_diff_x += 1
							temp_path.append(cell)
						cell.y -= 1
						temp_path.append(cell)
				temp_diff_y = 0
		#Se diff_y for maior que 6
		else: 
			#Se diff_y for positivo
			if temp_diff_y > 0:
				for i in range(6):
					temp = cell + Vector2(0, 1)
					if !(temp in used_cells):
						cell.y += 1
						temp_path.append(cell)
						temp_diff_y -= 1
					else: 
						while !((cell + Vector2(0, 1)) in used_cells):
							if diff_x >= 0:
								cell.x += 1
								temp_diff_x -= 1
							elif diff_x < 0:
								cell.x -= 1
								temp_diff_x += 1
							temp_path.append(cell)
						cell.y += 1
						temp_diff_y -= 1
						temp_path.append(cell)
			#Se diff_y for negativo
			else:
				if temp_diff_y < 0:
					for i in range(6):
						temp = cell + Vector2(0, -1)
						if !(temp in used_cells):
							cell.y -= 1
							temp_path.append(cell)
							temp_diff_y += 1
						else: 
							while !((cell + Vector2(0, -1)) in used_cells):
								if diff_x >= 0:
									cell.x += 1
									temp_diff_x -= 1
								elif diff_x < 0:
									cell.x -= 1
									temp_diff_x += 1
								temp_path.append(cell)
							cell.y -= 1
							temp_diff_y += 1
							temp_path.append(cell)
	return temp_path


func point_id(vect):
	var a = vect.x
	var b = vect.y
	return a * (height + 4) + b

func coordinates(length, position_origin): # dá só para retangulos
	var x = position_origin.x  
	var y = position_origin.y  
	var coor_list = [Vector2(x, y), Vector2(x, y + length.y - 1)]
	
	for i in range(x, x + length.x ):
		coor_list.append(Vector2(i, y))
		coor_list.append(Vector2(i, y + length.y - 1))
	for i in range(y, y + length.y - 1):
		coor_list.append(Vector2(x, i))
		coor_list.append(Vector2(x + length.x - 1, i))
	
	return coor_list

func get_length_list(list):
	var length = 0
	for i in range(0, len(list), 1):
		length += len(list[i])
	return length

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		check_position()

func check_position():
	print(tileMap.world_to_map(player.position))

func numb_list_gen():
	randomize()
	var list_numb = int(rand_range(1, len(nodes_list)))
	while list_numb == 2:
		list_numb = int(rand_range(1, len(nodes_list)))
	return list_numb

func reload_level():
	get_tree().reload_current_scene()
	

"""
const Player = preload("res://Player.tscn")
const Exit = preload("res://ExitDoor.tscn")

onready var tileMap = $TileMap

var borders = Rect2(1, 1, 30, 17)

func _ready():
	randomize()
	generate_level()

func generate_level():
	var walker = Walker.new(Vector2(15, 9), borders) # Metade do Rect2
	var map = walker.walk(200)
	
	var player = Player.instance()
	add_child(player)
	player.position = map.front() * 32
	
	var exit = Exit.instance()
	add_child(exit)
	exit.position = walker.get_end_room().position * 32
	exit.connect("leaving_level", self, "reload_level")
	
	walker.queue_free()
	for location in map:
		tileMap.set_cellv(location, -1) #Remove os tiles
	tileMap.update_bitmask_region(borders.position, borders.end)

func reload_level():
	get_tree().reload_current_scene()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		reload_level()
"""
