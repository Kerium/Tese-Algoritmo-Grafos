extends TileMap

var length = get_used_rect().size


#Todo ver se existe uma maneira para analisar mais formas, tipo circulos
func coordinates(): # dá só para retangulos
	var x = length.x  #ajustar o indice 8
	var y = length.y  # 6
	var coor_list = [Vector2(0, 0), Vector2(0, y - 1)]
	
	for i in range(1, x ):
		coor_list.append(Vector2(i, 0))
		coor_list.append(Vector2(i, y - 1))
	for i in range(1, y - 1):
		coor_list.append(Vector2(0, i))
		coor_list.append(Vector2(x - 1, i))
	
	print(coor_list)
	#var local_position = map_to_world(coor_list)
	#var global_position = to_global(local_position)
	print(global_position)


	return coor_list
	
	"""
	for i in range (x):
		for j in range (y):
			if get_cell(i, j):
				pass
	"""
