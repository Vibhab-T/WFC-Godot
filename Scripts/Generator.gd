extends Node3D

const CELL = preload("res://Scenes/cell.tscn")

const TILE_SCENES = [
	{
		"scene": preload("res://Scenes/road_straight.tscn"),
		"rotation": 0,
		"edges": { "north": 0, "east": 1, "south": 0, "west": 1 }
	},
	{
		"scene": preload("res://Scenes/road_straight.tscn"),
		"rotation": 90,
		"edges": { "north": 1, "east": 0, "south": 1, "west": 0 }
	},
	{
		"scene": preload("res://Scenes/road_curved.tscn"),
		"rotation": 0,
		"edges": { "north": 0, "east": 1, "south": 1, "west": 0 }
	},
	{
		"scene": preload("res://Scenes/road_curved.tscn"),
		"rotation": 90,
		"edges": { "north": 1, "east": 1, "south": 0, "west": 0 }
	},
	{
		"scene": preload("res://Scenes/road_curved.tscn"),
		"rotation": 180,
		"edges": { "north": 1, "east": 0, "south": 0, "west": 1 }
	},
	{
		"scene": preload("res://Scenes/road_curved.tscn"),
		"rotation": 270,
		"edges": { "north": 0, "east": 0, "south": 1, "west": 1 }
	},
	{
		"scene": preload("res://Scenes/building.tscn"),
		"rotation": 0,
		"edges": { "north": 0, "east": 0, "south": 0, "west": 0 } # building = grass on all sides
	}
]

@export var dimension: int = 20

func _ready() -> void:
	GenerateGrid()

func GenerateGrid():
	for y in range(dimension):
		for x in range(dimension):
			var cell_instance = CELL.instantiate()
			
			cell_instance.position = Vector3(x , 0, y)
			cell_instance.grid_x = x
			cell_instance.grid_y = y
			
			cell_instance.options = TILE_SCENES.duplicate()
			
			add_child(cell_instance)
	StartWaveFunctionCollapse()

func StartWaveFunctionCollapse():
	var cell = GetCellAt(0,0)
	
	CollapseCell(cell)
	PropagateConstraints(cell)
	
	while true:
		var next_cell = FindLowestEntropyCell()
		if not next_cell:
			break
		CollapseCell(next_cell)
		PropagateConstraints(next_cell)



func CollapseCell(cell: Cell):
	var chosen = cell.options.pick_random()
	cell.options = [chosen]
	cell.collapsed = true
	
	var tile_instance = chosen["scene"].instantiate();
	tile_instance.position = cell.position
	tile_instance.rotation_degrees.y = chosen["rotation"]
	add_child(tile_instance)
	
	print("Placed tile at ", 
	cell.grid_x, ",", cell.grid_y, " rotation: ", chosen["rotation"])

	
	var cell_holder = cell.get_node_or_null("CellHolder")
	if cell_holder:
		cell_holder.queue_free()
	
func GetCellAt(x: int, y: int):
	for c in get_children():
		if c is Cell and c.grid_x == x and c.grid_y == y:
			return c
	return null

func FindLowestEntropyCell():
	var min_options = 9999
	var candidates = []
	for c in get_children():
		if c is Cell and not c.collapsed:
			var opt_size = c.options.size()
			if opt_size < min_options:
				min_options = opt_size
				candidates=[c]
			elif opt_size == min_options:
				candidates.append(c)
	if candidates.is_empty():
		return null
	return candidates.pick_random()

func PropagateConstraints(start_cell: Cell):
	var queue: Array = [start_cell]
	
	while not queue.is_empty():
		var cell = queue.pop_front()
		
		#if cell is not collapsed, standard propagation
		if cell.collapsed:
			var collapsed_tile = cell.options[0]
			var north = collapsed_tile["edges"]["north"]
			var east = collapsed_tile["edges"]["east"]
			var south = collapsed_tile["edges"]["south"]
			var west = collapsed_tile["edges"]["west"]
			
			#reduce north neighbour
			var north_neighbour = GetCellAt(cell.grid_x, cell.grid_y+1)
			if north_neighbour and not north_neighbour.collapsed:
				var old_size = north_neighbour.options.size()
				if north == 1:
					north_neighbour.options = FilterTiles("south", 1, north_neighbour.options)
				else:
					north_neighbour.options = FilterTiles("south", 0, north_neighbour.options)
				if north_neighbour.options.size() < old_size:
					queue.append(north_neighbour)
			
			#reduce east neighour
			var east_neighbour = GetCellAt(cell.grid_x+1, cell.grid_y)
			if east_neighbour and not east_neighbour.collapsed:
				var old_size = east_neighbour.options.size()
				if east == 1:
					east_neighbour.options = FilterTiles("west", 1, east_neighbour.options)
				else:
					east_neighbour.options = FilterTiles("west", 0, east_neighbour.options)
				if east_neighbour.options.size() < old_size:
					queue.append(east_neighbour)
			
			#reduce south neighbour
			var south_neighbour = GetCellAt(cell.grid_x, cell.grid_y-1)
			if south_neighbour and not south_neighbour.collapsed:
				var old_size = south_neighbour.options.size()
				if south == 1:
					south_neighbour.options = FilterTiles("north", 1, south_neighbour.options)
				else:
					south_neighbour.options = FilterTiles("north", 0, south_neighbour.options)
				if south_neighbour.options.size() < old_size:
					queue.append(south_neighbour)
			
			#reduce west neighbour
			var west_neighbour = GetCellAt(cell.grid_x-1, cell.grid_y)
			if west_neighbour and not west_neighbour.collapsed:
				var old_size = west_neighbour.options.size()
				if west == 1:
					west_neighbour.options = FilterTiles("east", 1, west_neighbour.options)
				else:
					west_neighbour.options = FilterTiles("east", 0, west_neighbour.options)
				if west_neighbour.options.size() < old_size:
					queue.append(west_neighbour)
		else:
			var edge_union = {"north": [], "east": [], "south": [], "west": []}
			for opt in cell.options:
				for dir in edge_union:
					if not edge_union[dir].has(opt["edges"][dir]):
						edge_union[dir].append(opt["edges"][dir])
			
			#reuce NORTH neighbour
			var north_neighbour = GetCellAt(cell.grid_x, cell.grid_y +1)
			if north_neighbour and not north_neighbour.collapsed:
				var old_size = north_neighbour.options.size()
				var combined = []
				for val in edge_union["north"]:
					combined += FilterTiles("south", val, north_neighbour.options)
				north_neighbour.options = combined
				if north_neighbour.options.size() < old_size:
					queue.append(north_neighbour)
			
			#reduce EAST neighbour
			var east_neighbour = GetCellAt(cell.grid_x+1, cell.grid_y)
			if east_neighbour and not east_neighbour.collapsed:
				var old_size = east_neighbour.options.size()
				var combined = []
				for val in edge_union["east"]:
					combined += FilterTiles("west", val, east_neighbour.options)
				east_neighbour.options = combined
				if east_neighbour.options.size() < old_size:
					queue.append(east_neighbour)
			
			#reduce SOUTH neighbour
			var south_neighbour = GetCellAt(cell.grid_x, cell.grid_y - 1)
			if south_neighbour and not south_neighbour.collapsed:
				var old_size = south_neighbour.options.size()
				var combined = []
				for val in edge_union["south"]:
					combined += FilterTiles("north", val, south_neighbour.options)
				south_neighbour.options = combined
				if south_neighbour.options.size() < old_size:
					queue.append(south_neighbour)
			
			#reduce WEST neighbour
			var west_neighbour = GetCellAt(cell.grid_x-1, cell.grid_y)
			if west_neighbour and not west_neighbour.collapsed:
				var old_size = west_neighbour.options.size()
				var combined = []
				for val in edge_union["west"]:
					combined += FilterTiles("east", val, west_neighbour.options)
				west_neighbour.options = combined
				if west_neighbour.options.size() < old_size:
					queue.append(west_neighbour)



func FilterTiles(direction: String, value: int, options := TILE_SCENES):
	var result = []
	for tile in options:
		if tile["edges"].has(direction) and tile["edges"][direction] == value:
			result.append(tile)
	return result
