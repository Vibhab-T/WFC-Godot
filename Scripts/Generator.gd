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
var cells: Array[Array] = []

func _ready() -> void:
	GenerateGrid()

func GenerateGrid():
	#2D array for easier cell access
	cells.resize(dimension)
	for x in range(dimension):
		cells[x] = []
		cells[x].resize(dimension)
	
	for y in range(dimension):
		for x in range(dimension):
			var cell_instance = CELL.instantiate()
			
			cell_instance.position = Vector3(x , 0, y)
			cell_instance.grid_x = x
			cell_instance.grid_y = y
			
			cell_instance.options = TILE_SCENES.duplicate(true)
			
			add_child(cell_instance)
			cells[x][y] = cell_instance
	StartWaveFunctionCollapse()

func StartWaveFunctionCollapse():
	var start_x = dimension/2
	var start_y = dimension/2
	
	var cell = GetCellAt(start_x, start_y)
	
	if cell:
		CollapseCell(cell)
		PropagateConstraints(cell)
	
	var iterations = 0
	var max_iters = dimension * dimension * 2 
	while iterations < max_iters:
		var next_cell = FindLowestEntropyCell()
		if not next_cell:
			print("WFC Completed")
			break
		if next_cell.options.is_empty():
			print("ERROR: Cell with no options found at ", next_cell.grid_x, ",", next_cell.grid_y)
		CollapseCell(next_cell)
		PropagateConstraints(next_cell)
		iterations += 1
	if iterations >= max_iters:
		print("Max iterations reached, might be incomplete")



func CollapseCell(cell: Cell):
	if cell.options.is_empty():
		print("ERROR: Trying to collapse cell with no options!")
		return
	
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
	if x>= 0 and x < dimension and y >= 0 and y < dimension:
		return cells[x][y]
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

func CollapsedPropagation(cell: Cell, dx: int, dy: int, my_dir: String, neighbour_dir: String, my_edge: int, queue: Array[Cell]):
	var neighbour = GetCellAt(cell.grid_x + dx, cell.grid_y + dy)
	if not neighbour or neighbour.collapsed:
		return
	
	var old_size = neighbour.options.size()
	neighbour.options = FilterTiles(neighbour_dir, my_edge, neighbour.options)
	
	if neighbour.options.size() < old_size and not queue.has(neighbour):
		queue.append(neighbour)

func UncollapsedPropagation(cell: Cell, dx: int, dy: int, my_dir: String, neighbour_dir: String, queue: Array[Cell]):
	var neighbour = GetCellAt(cell.grid_x + dx, cell.grid_y + dy)
	if not neighbour or neighbour.collapsed:
		return
	
	var old_size = neighbour.options.size()
	
	# get all possible edge values this cell could have on the connecting side
	var possible_edge_values = []
	for option in cell.options:
		var edge_val = option["edges"][my_dir]
		if not possible_edge_values.has(edge_val):
			possible_edge_values.append(edge_val)
	
	# filter neighbour's optiopn to only those compatible with our possible edges
	var new_options = []
	for neighbour_option in neighbour.options:
		var neighbour_edge = neighbour_option["edges"][neighbour_dir]
		if possible_edge_values.has(neighbour_edge):
			new_options.append(neighbour_option)
	
	neighbour.options = new_options
	if neighbour.options.size() < old_size and not queue.has(neighbour):
		queue.append(neighbour)
	

func PropagateConstraints(start_cell: Cell):
	var queue: Array[Cell] = [start_cell]
	var processed: Dictionary = {}
	
	while not queue.is_empty():
		var cell = queue.pop_front()
		
		var cell_key = str(cell.grid_x) + "," + str(cell.grid_y)
		if processed.has(cell_key):
			continue
		processed[cell_key] = true
		
		if cell.collapsed:
			var collapsed_tile = cell.options[0]
			CollapsedPropagation(cell, 0, 1, "north", "south", collapsed_tile["edges"]["north"], queue) #NORTH
			CollapsedPropagation(cell, 1, 0, "east", "west", collapsed_tile["edges"]["east"], queue) #EAST
			CollapsedPropagation(cell, 0, -1, "south", "north", collapsed_tile["edges"]["south"], queue) #SOUTH
			CollapsedPropagation(cell, -1, 0, "west", "east", collapsed_tile["edges"]["west"], queue) #WEST
		else:
			#not collapsed
			UncollapsedPropagation(cell, 0, 1, "north", "south", queue) #NORTH
			UncollapsedPropagation(cell, 1, 0, "east", "west", queue) #EAST
			UncollapsedPropagation(cell, 0, -1, "south", "north", queue) #SOUTH
			UncollapsedPropagation(cell, -1, 0, "west", "east", queue) #WEST
		
		


func FilterTiles(direction: String, value: int, options := TILE_SCENES):
	var result = []
	for tile in options:
		if tile["edges"].has(direction) and tile["edges"][direction] == value:
			result.append(tile)
	return result
