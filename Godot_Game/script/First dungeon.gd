extends Node2D

var Room = preload("res://scene/room.tscn")
var Player = preload("res://scene/player.tscn")
@onready var Map = $TileMap

var tile_size = 32 #size of the tile square
var num_rooms = 30 #number of rooms to generate
var min_size = 10 #minimum width/height
var max_size = 30 #maximum width/height

var hspread = 200 # biased to generate horizontally
var cull = 0.5 

var path # AStar pathfinding object
var first = true
var start_room = null
var end_room = null 
var player = null


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	make_rooms()
	await(get_tree().create_timer(2.1).timeout)
	#await(make_rooms())
	queue_redraw()
	#await(queue_redraw())
	#better way to do this
	make_map()
	await(get_tree().create_timer(1.1).timeout)
	queue_redraw()
	await(get_tree().create_timer(1.1).timeout)
	player = Player.instantiate()
	add_child(player)
	player.position = start_room.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func make_rooms():
	for i in range(num_rooms):
		# var pos = Vector2(0,0)
		var pos = Vector2(randi_range(-hspread, hspread),0) #because of colisions it will spread
		var r = Room.instantiate()
		var w = min_size + randi() % (max_size - min_size)
		var h = min_size + randi() % (max_size - min_size)
		r.make_room(pos, Vector2(w,h) * tile_size)
		$Rooms.add_child(r)
	# wait for the rectangles to spread before cull
	await(get_tree().create_timer(1.1).timeout)
	#cull rooms
	var room_positions = []
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.freeze = true
			room.get_node('CollisionShape2D').disabled = true
			room_positions.append(room.position)
			
	await(get_tree().process_frame)
	# generate a minimum spanning tree connecting the rooms
	path = find_mst(room_positions)

func _draw():
	if first:
		for room in $Rooms.get_children():
			draw_rect(Rect2(room.position- (room.size / 2), room.size), Color(32,228,0), false)
		if path:
			for p in path.get_point_ids():
				for c in path.get_point_connections(p):
					var pp = path.get_point_position(p)
					var cp = path.get_point_position(c)
					draw_line(pp,cp, Color(1,1,0), 15, true)
		first = false
	else:
		return
		
func _process(delta):
	queue_redraw()
	
func delete_rooms():
	for r in $Rooms.get_children():
		r.queue_free()
	path = null
		
func find_mst(nodes):
	# Prim's algorithm
	var path = AStar2D.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	#repeat until no more nodes remain
	while nodes:
		var min_dist = INF #minimum distance so far
		var min_p = null # position of the node
		var p = null #current poisiton we are looking at
		# Loop through point in path
		for p1 in path.get_point_ids():
			var p_temp = path.get_point_position(p1)
			# loop through the remaining nodes
			for p2 in nodes:
				if p_temp.distance_to(p2) < min_dist:
					min_dist = p_temp.distance_to(p2)
					min_p = p2
					p = p_temp
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		nodes.erase(min_p)
	return path
				
func make_map():
	# create a tilemap from the generated rooms and path
	Map.clear()
	find_start_room()
	find_end_room()
	
	# fill tilemap with wall, then carve empty rooms
	var full_rect = Rect2()
	for room in $Rooms.get_children():
		var r = Rect2(room.position- (room.size/2), room.get_node('CollisionShape2D').shape.extents*2 + (Vector2(tile_size,tile_size) * 4))
		full_rect = full_rect.merge(r)
	var topleft = Map.local_to_map(full_rect.position)
	var bottomright = Map.local_to_map(full_rect.end)
	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y, bottomright.y):
			Map.set_cell(1, Vector2i(x, y), 1, Vector2i(4, 0), 0) #grey wall
	
	#carve rooms
	var corridors = [] # One corridor per connection
	
	# add room walls first
	for room in $Rooms.get_children():
		var s_wall = ((room.size / tile_size) / 2).floor()
		var pos_wall = Map.local_to_map(room.position)
		var upperleft_wall = (room.position / tile_size).floor() - s_wall #upperleft to start the walls
		#Upper wall + lower wall
		for x in range(2, s_wall.x * 2 - 1): 
			Map.set_cell(1, Vector2i(upperleft_wall.x + x, upperleft_wall.y), 2, Vector2i(1, 0), 0) #upper_wall_top 
			Map.set_cell(1, Vector2i(upperleft_wall.x + x, upperleft_wall.y + 1), 2, Vector2i(6, 0), 0) #upper_wall_bottom 
			Map.set_cell(1, Vector2i(upperleft_wall.x + x, upperleft_wall.y + s_wall.y * 2 - 1), 2, Vector2i(9, 0), 0) #lower_wall
		#left wall + right wall
		for y in range(2, s_wall.y * 2 - 1): 
			Map.set_cell(1, Vector2i(upperleft_wall.x + 1, upperleft_wall.y + y), 2, Vector2i(3, 0), 0) 
			Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x * 2 - 1, upperleft_wall.y + y), 2, Vector2i(5, 0), 0) 
		#corners
		#left_top
		Map.set_cell(1, Vector2i(upperleft_wall.x + 1, upperleft_wall.y), 2, Vector2i(0, 0), 0) 
		Map.set_cell(1, Vector2i(upperleft_wall.x + 1, upperleft_wall.y + 1), 2, Vector2i(3, 0), 0) 
		#right_top
		Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x * 2 -1, upperleft_wall.y), 2, Vector2i(2, 0), 0) 
		Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x * 2 - 1, upperleft_wall.y + 1), 2, Vector2i(5, 0), 0) 
		#left_bottom
		Map.set_cell(1, Vector2i(upperleft_wall.x + 1, upperleft_wall.y + s_wall.y * 2 - 1), 2, Vector2i(8, 0), 0)
		#right_bottom
		Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x * 2 -1, upperleft_wall.y + s_wall.y * 2 - 1), 2, Vector2i(10, 0), 0)
		
	for room in $Rooms.get_children():
		# carve connecting corridor first
		var p = path.get_closest_point(room.position)
		for conn in path.get_point_connections(p):
			if not conn in corridors:
				var start = Map.local_to_map(path.get_point_position(p))
				var end = Map.local_to_map(path.get_point_position(conn))
				carve_path(start, end)
		corridors.append(p)
		#then add the rooms
		var s = ((room.size / tile_size) / 2).floor()
		var pos = Map.local_to_map(room.position)
		var upperleft = (room.position / tile_size).floor() - s
		for x in range(2, s.x * 2 -1):
			for y in range(2, s.y * 2 -1):
				Map.set_cell(1, Vector2i(upperleft.x + x, upperleft.y + y), 2, Vector2i(7, 0), 0) #floor
		
		
func carve_path(pos1,pos2):
	# var to widen corridor
	var extra_widen = 1
	# carve a path between two points
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	
	# if they are aligned pick a random sign either -1 or 1
	if x_diff == 0: x_diff = pow(-1.0, randi() % 2) 
	if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
	
	#choose either do  x/y or y/x
	var x_y = pos1
	var y_x = pos2
	var do_x = true
	if (randi() % 2) > 0:
		x_y = pos2
		y_x = pos1
		do_x = false
		
	# add walls first
	for x in range(pos1.x, pos2.x, x_diff):
		if do_x:
			Map.set_cell(1, Vector2i(x + x_diff * extra_widen, x_y.y - 1 * extra_widen - 2), 2, Vector2i(1, 0), 0) #add walls
			Map.set_cell(1, Vector2i(x + x_diff * extra_widen, x_y.y - 1 * extra_widen - 1), 2, Vector2i(6, 0), 0) #add walls
			Map.set_cell(1, Vector2i(x + x_diff * extra_widen, x_y.y + 1 * extra_widen + 1), 2, Vector2i(9, 0), 0) #add walls
		else:
			Map.set_cell(1, Vector2i(x - x_diff * extra_widen, x_y.y - 1 * extra_widen - 2), 2, Vector2i(1, 0), 0) #add walls
			Map.set_cell(1, Vector2i(x - x_diff * extra_widen, x_y.y - 1 * extra_widen - 1), 2, Vector2i(6, 0), 0) #add walls
			Map.set_cell(1, Vector2i(x - x_diff * extra_widen, x_y.y + 1 * extra_widen + 1), 2, Vector2i(9, 0), 0) #add walls
	for y in range(pos1.y, pos2.y, y_diff):
		if do_x:#extend at the beggining
			Map.set_cell(1, Vector2i(y_x.x - 1 * extra_widen - 1, y - y_diff * extra_widen), 2, Vector2i(3, 0), 0) #add walls
			Map.set_cell(1, Vector2i(y_x.x + 1 * extra_widen + 1, y - y_diff * extra_widen), 2, Vector2i(5, 0), 0) #add walls
		else:#extend at the end
			Map.set_cell(1, Vector2i(y_x.x - 1 * extra_widen - 1, y + y_diff * extra_widen), 2, Vector2i(3, 0), 0) #add walls
			Map.set_cell(1, Vector2i(y_x.x + 1 * extra_widen + 1, y + y_diff * extra_widen), 2, Vector2i(5, 0), 0) #add walls
			
		
	for x in range(pos1.x, pos2.x, x_diff):
		if do_x:#extend at the end
			Map.set_cell(1, Vector2i(x + x_diff * extra_widen, x_y.y), 2, Vector2i(7, 0), 0) #floor
		else:#extend at the beggining
			Map.set_cell(1, Vector2i(x - x_diff * extra_widen, x_y.y), 2, Vector2i(7, 0), 0) #floor
		for widen in range(1, extra_widen + 1):
			if do_x: #extend at the end
				Map.set_cell(1, Vector2i(x + x_diff * extra_widen, x_y.y + y_diff * widen), 2, Vector2i(7, 0), 0) #widen the floor
				Map.set_cell(1, Vector2i(x + x_diff * extra_widen, x_y.y - y_diff * widen), 2, Vector2i(7, 0), 0) #widen the floor
			else:
				Map.set_cell(1, Vector2i(x - x_diff * extra_widen, x_y.y + y_diff * widen), 2, Vector2i(7, 0), 0) #widen the floor
				Map.set_cell(1, Vector2i(x - x_diff * extra_widen, x_y.y - y_diff * widen), 2, Vector2i(7, 0), 0) #widen the floor
#		if y_diff < 0: #pos 2 lower
#			Map.set_cell(1, Vector2i(x, x_y.y + 2 * y_diff), 2, Vector2i(9, 0), 0) #top x wall
#			Map.set_cell(1, Vector2i(x, x_y.y - y_diff), 2, Vector2i(1, 0), 0) #lower x wall
#		else:
#			Map.set_cell(1, Vector2i(x, x_y.y - y_diff), 2, Vector2i(1, 0), 0) #top x wall
#			Map.set_cell(1, Vector2i(x, x_y.y + 2 * y_diff), 2, Vector2i(9, 0), 0) #lower x wall
	for y in range(pos1.y, pos2.y, y_diff):
		if do_x:#extend at the beggining
			Map.set_cell(1, Vector2i(y_x.x, y - y_diff * extra_widen), 2, Vector2i(7, 0), 0) #floor #floor
		else:#extend at the end
			Map.set_cell(1, Vector2i(y_x.x, y + y_diff * extra_widen), 2, Vector2i(7, 0), 0) #floor #floor
		for widen in range(1, extra_widen + 1):
			if do_x: #extend at the end
				Map.set_cell(1, Vector2i(y_x.x + x_diff * widen, y - y_diff * extra_widen), 2, Vector2i(7, 0), 0) #widen the floor
				Map.set_cell(1, Vector2i(y_x.x - x_diff * widen, y - y_diff * extra_widen), 2, Vector2i(7, 0), 0) #widen the floor
			else:
				Map.set_cell(1, Vector2i(y_x.x + x_diff * widen, y + y_diff * extra_widen), 2, Vector2i(7, 0), 0) #widen the floor
				Map.set_cell(1, Vector2i(y_x.x - x_diff * widen, y + y_diff * extra_widen), 2, Vector2i(7, 0), 0) #widen the floor
		
func find_start_room():
	var min_x = INF
	for room in $Rooms.get_children():
		if room.position.x < min_x:
			start_room = room
			min_x = room.position.x

func find_end_room():
	var max_x = -INF
	for room in $Rooms.get_children():
		if room.position.x > max_x:
			end_room = room
			max_x = room.position.x
			
		
