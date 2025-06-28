#
#func PropagateConstraints(start_cell: Cell):
	#var queue: Array[Cell] = [start_cell]
	#var processed: Dictionary = {}
	#
	#while not queue.is_empty():
		#var cell = queue.pop_front()
		#
		#var cell_key = str(cell.grid_x) + "," + str(cell.grid_y)
		#if processed.has(cell_key):
			#continue
		#processed[cell_key] = true
		#
		#if cell.collapsed:
			#var collapsed_tile = cell.options[0]
			#CollapsedPropagation(cell, 0, 1, "north", "south", collapsed_tile["edges"]["north"], queue) #NORTH
			#CollapsedPropagation(cell, 1, 0, "east", "west", collapsed_tile["edges"]["east"], queue) #EAST
			#CollapsedPropagation(cell, 0, -1, "south", "north", collapsed_tile["edges"]["south"], queue) #SOUTH
			#CollapsedPropagation(cell, -1, 0, "west", "east", collapsed_tile["edges"]["west"], queue) #WEST
		#else:
			##not collapsed
			#UncollapsedPropagation(cell, 0, 1, "north", "south", queue) #NORTH
			#UncollapsedPropagation(cell, 1, 0, "east", "west", queue) #EAST
			#UncollapsedPropagation(cell, 0, -1, "south", "north", queue) #SOUTH
			#UncollapsedPropagation(cell, -1, 0, "west", "east", queue) #WEST
		#
		#
		###if cell is not collapsed, standard propagation
		##if cell.collapsed:
			##var collapsed_tile = cell.options[0]
			##var north = collapsed_tile["edges"]["north"]
			##var east = collapsed_tile["edges"]["east"]
			##var south = collapsed_tile["edges"]["south"]
			##var west = collapsed_tile["edges"]["west"]
			##
			###reduce north neighbour
			##var north_neighbour = GetCellAt(cell.grid_x, cell.grid_y+1)
			##if north_neighbour and not north_neighbour.collapsed:
				##var old_size = north_neighbour.options.size()
				##if north == 1:
					##north_neighbour.options = FilterTiles("south", 1, north_neighbour.options)
				##else:
					##north_neighbour.options = FilterTiles("south", 0, north_neighbour.options)
				##if north_neighbour.options.size() < old_size:
					##queue.append(north_neighbour)
			##
			###reduce east neighour
			##var east_neighbour = GetCellAt(cell.grid_x+1, cell.grid_y)
			##if east_neighbour and not east_neighbour.collapsed:
				##var old_size = east_neighbour.options.size()
				##if east == 1:
					##east_neighbour.options = FilterTiles("west", 1, east_neighbour.options)
				##else:
					##east_neighbour.options = FilterTiles("west", 0, east_neighbour.options)
				##if east_neighbour.options.size() < old_size:
					##queue.append(east_neighbour)
			##
			###reduce south neighbour
			##var south_neighbour = GetCellAt(cell.grid_x, cell.grid_y-1)
			##if south_neighbour and not south_neighbour.collapsed:
				##var old_size = south_neighbour.options.size()
				##if south == 1:
					##south_neighbour.options = FilterTiles("north", 1, south_neighbour.options)
				##else:
					##south_neighbour.options = FilterTiles("north", 0, south_neighbour.options)
				##if south_neighbour.options.size() < old_size:
					##queue.append(south_neighbour)
			##
			###reduce west neighbour
			##var west_neighbour = GetCellAt(cell.grid_x-1, cell.grid_y)
			##if west_neighbour and not west_neighbour.collapsed:
				##var old_size = west_neighbour.options.size()
				##if west == 1:
					##west_neighbour.options = FilterTiles("east", 1, west_neighbour.options)
				##else:
					##west_neighbour.options = FilterTiles("east", 0, west_neighbour.options)
				##if west_neighbour.options.size() < old_size:
					##queue.append(west_neighbour)
		##else:
			##var edge_union = {"north": [], "east": [], "south": [], "west": []}
			##for opt in cell.options:
				##for dir in edge_union:
					##if not edge_union[dir].has(opt["edges"][dir]):
						##edge_union[dir].append(opt["edges"][dir])
			##
			###reuce NORTH neighbour
			##var north_neighbour = GetCellAt(cell.grid_x, cell.grid_y +1)
			##if north_neighbour and not north_neighbour.collapsed:
				##var old_size = north_neighbour.options.size()
				##var combined = []
				##for val in edge_union["north"]:
					##combined += FilterTiles("south", val, north_neighbour.options)
				##north_neighbour.options = combined
				##if north_neighbour.options.size() < old_size:
					##queue.append(north_neighbour)
			##
			###reduce EAST neighbour
			##var east_neighbour = GetCellAt(cell.grid_x+1, cell.grid_y)
			##if east_neighbour and not east_neighbour.collapsed:
				##var old_size = east_neighbour.options.size()
				##var combined = []
				##for val in edge_union["east"]:
					##combined += FilterTiles("west", val, east_neighbour.options)
				##east_neighbour.options = combined
				##if east_neighbour.options.size() < old_size:
					##queue.append(east_neighbour)
			##
			###reduce SOUTH neighbour
			##var south_neighbour = GetCellAt(cell.grid_x, cell.grid_y - 1)
			##if south_neighbour and not south_neighbour.collapsed:
				##var old_size = south_neighbour.options.size()
				##var combined = []
				##for val in edge_union["south"]:
					##combined += FilterTiles("north", val, south_neighbour.options)
				##south_neighbour.options = combined
				##if south_neighbour.options.size() < old_size:
					##queue.append(south_neighbour)
			##
			###reduce WEST neighbour
			##var west_neighbour = GetCellAt(cell.grid_x-1, cell.grid_y)
			##if west_neighbour and not west_neighbour.collapsed:
				##var old_size = west_neighbour.options.size()
				##var combined = []
				##for val in edge_union["west"]:
					##combined += FilterTiles("east", val, west_neighbour.options)
				##west_neighbour.options = combined
				##if west_neighbour.options.size() < old_size:
					##queue.append(west_neighbour)
