extends Node2D

var Room = preload("res://scene/room_dungeon_1.tscn")
var Player = preload("res://scene/player.tscn")
@onready var Map = $TileMap

var tile_size = 32 #size of the tile square
var num_rooms = 15 #number of rooms to generate from central room
var door_size = 3
var min_size = 5 #minimum width/height
var max_size = 15 #maximum width/height

var hspread = 0 # biased to generate horizontally
var cull = 0.5 

var path # AStar pathfinding object
var first = true
var start_room = null
var end_room = null 
var player = null

var type_array = ['normal_room', 'large_room', 'secret_room', 'boss_room', 'corridor']

# Called when the node enters the scene tree for the first time.
func _ready():
	Map.position = Vector2(tile_size/2, tile_size/2) # change postion of tilemap so it follow exact squares
	randomize()
	await(make_rooms())
	#await(get_tree().create_timer(2.1).timeout)
	#await(make_rooms())
	await(make_map())
	player = Player.instantiate()
	add_child(player)
	player.position = Vector2(randi_range(-hspread, hspread),0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#queue_redraw()

func make_rooms():
	var pos = Vector2(randi_range(-hspread, hspread),0) #because of colisions it will spread
	var r = Room.instantiate()
	var w = (min_size + randi() % (max_size - min_size)) * 2 + door_size # so door is centered
	var h = (min_size + randi() % (max_size - min_size)) * 2 + door_size # so door is centered
	r.make_room(pos, Vector2(w,h) * tile_size, 'normal_room', 4)
	$Rooms.add_child(r)
	for i in range(num_rooms - 1):
		queue_redraw()
		await(get_tree().create_timer(0.1).timeout)
		var no_collision = false
		while !no_collision:
			var _num_doors = 0
			var room
			while (_num_doors == 0):
				var room_id = randi() % $Rooms.get_children().size()
				room = $Rooms.get_child(room_id)
				_num_doors = room.door_without_room.size()
			w = (min_size + randi() % (max_size - min_size)) * 2 + door_size # so door is centered
			h = (min_size + randi() % (max_size - min_size)) * 2 + door_size # so door is centered
			var pos_door_new_room = room.get_next_room_position(Vector2(w,h) * tile_size)
			var pos_new_room = pos_door_new_room[0]
			var door_choosen = pos_door_new_room[1]
			r = Room.instantiate()
			r.make_room(pos_new_room, Vector2(w,h) * tile_size, 'normal_room', 4)
			var no_detect_collision = true
			for all_room in $Rooms.get_children():
				if r.colides_with_room(all_room.rect_area):
					r.queue_free()
					no_detect_collision = false 
					room.add_door_back(door_choosen)
			no_collision = no_detect_collision
			if no_collision:
				room.add_to_door_with_room(door_choosen)
				$Rooms.add_child(r)
#	for room_i in range($Rooms.get_children().size() - 1):
#		for room_j in range(room_i + 1, $Rooms.get_children().size()):
#			if $Rooms.get_child(room_i).colides_with_room($Rooms.get_child(room_j).rect_area):
#				print('overlaps')
#	print("done")
	# wait for the rectangles
	
func make_map():
	# create a tilemap from the generated rooms and path
	Map.clear()
	#find_start_room()
	#find_end_room()
	
	# fill tilemap with wall, then carve empty rooms
#	var full_rect = Rect2()
#	for room in $Rooms.get_children():
#		var r = Rect2(room.position- (room.size/2), room.get_node('CollisionShape2D').shape.extents*2 + (Vector2(tile_size,tile_size) * 4))
#		full_rect = full_rect.merge(r)
#	var topleft = Map.local_to_map(full_rect.position)
#	var bottomright = Map.local_to_map(full_rect.end)
#	for x in range(topleft.x, bottomright.x):
#		for y in range(topleft.y, bottomright.y):
#			Map.set_cell(1, Vector2i(x, y), 1, Vector2i(4, 0), 0) #grey wall
	
	#carve rooms
	var corridors = [] # One corridor per connection
	
	# add room walls first
	for room in $Rooms.get_children():
		var s_wall = (room.size / tile_size) # wall size
		var wall_to_door = (s_wall - Vector2(door_size, door_size)) / 2
		var pos_wall = Map.local_to_map(room.position)
#		var upperleft_wall = (room.position / tile_size).floor() - s_wall #upperleft to start the walls
		var upperleft_wall = (room.upper_left / tile_size).floor()
		#Upper wall + lower wall
		for x in range(0, s_wall.x): 
			Map.set_cell(1, Vector2i(upperleft_wall.x + x, upperleft_wall.y), 2, Vector2i(1, 0), 0) #upper_wall_top 
			Map.set_cell(1, Vector2i(upperleft_wall.x + x, upperleft_wall.y + 1), 2, Vector2i(6, 0), 0) #upper_wall_bottom 
			Map.set_cell(1, Vector2i(upperleft_wall.x + x, upperleft_wall.y + s_wall.y - 1), 2, Vector2i(9, 0), 0) #lower_wall
		#left wall + right wall
		for y in range(0, s_wall.y): 
			Map.set_cell(1, Vector2i(upperleft_wall.x, upperleft_wall.y + y), 2, Vector2i(3, 0), 0) 
			Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x - 1, upperleft_wall.y + y), 2, Vector2i(5, 0), 0) 
		#corners
		#left_top
		Map.set_cell(1, Vector2i(upperleft_wall.x, upperleft_wall.y), 2, Vector2i(0, 0), 0) 
		Map.set_cell(1, Vector2i(upperleft_wall.x, upperleft_wall.y + 1), 2, Vector2i(3, 0), 0) 
		#right_top
		Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x -1, upperleft_wall.y), 2, Vector2i(2, 0), 0) 
		Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x -1, upperleft_wall.y + 1), 2, Vector2i(5, 0), 0) 
		#left_bottom
		Map.set_cell(1, Vector2i(upperleft_wall.x, upperleft_wall.y + s_wall.y - 1), 2, Vector2i(8, 0), 0)
		#right_bottom
		Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x -1, upperleft_wall.y + s_wall.y - 1), 2, Vector2i(10, 0), 0)
		
		# add floors
		for x in range(1, s_wall.x -1):
			for y in range(2, s_wall.y - 1):
				Map.set_cell(1, Vector2i(upperleft_wall.x + x, upperleft_wall.y + y), 2, Vector2i(7, 0), 0) #floor
		
	for room in $Rooms.get_children():	
		var s_wall = (room.size / tile_size) # wall size
		var wall_to_door = (s_wall - Vector2(door_size, door_size)) / 2
		var pos_wall = Map.local_to_map(room.position)
#		var upperleft_wall = (room.position / tile_size).floor() - s_wall #upperleft to start the walls
		var upperleft_wall = (room.upper_left / tile_size).floor()	
		# add doors
		for door_i in room.door_with_room:
			if room.door_locations[door_i] == 'north':
				for x in range(door_size):
					Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x + x, upperleft_wall.y - 1), 2, Vector2i(7, 0), 0)
					Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x + x, upperleft_wall.y), 2, Vector2i(7, 0), 0)
					Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x + x, upperleft_wall.y + 1), 2, Vector2i(7, 0), 0)
				#wall left
				Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x -1 , upperleft_wall.y - 1), 1, Vector2i(2, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x -1, upperleft_wall.y), 1, Vector2i(8, 0), 0)
				#wall right
				Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x + door_size , upperleft_wall.y - 1), 1, Vector2i(0, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x + door_size, upperleft_wall.y), 1, Vector2i(6, 0), 0)
			if room.door_locations[door_i] == 'east':
				for y in range(door_size):
					# door floors
					Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x - 1, upperleft_wall.y + wall_to_door.y + y), 2, Vector2i(7, 0), 0)
					Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x, upperleft_wall.y + wall_to_door.y + y), 2, Vector2i(7, 0), 0)
				# door walls up
				Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x - 1, upperleft_wall.y + wall_to_door.y -2), 1, Vector2i(6, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x, upperleft_wall.y + wall_to_door.y -2), 1, Vector2i(8, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x - 1, upperleft_wall.y + wall_to_door.y -1), 1, Vector2i(9, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x, upperleft_wall.y + wall_to_door.y -1), 1, Vector2i(11, 0), 0)
				# door walls down
				Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x - 1, upperleft_wall.y + wall_to_door.y + door_size), 1, Vector2i(0, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x + s_wall.x, upperleft_wall.y + wall_to_door.y + door_size), 1, Vector2i(2, 0), 0)
			if room.door_locations[door_i] == 'west':
				for y in range(door_size):
					Map.set_cell(1, Vector2i(upperleft_wall.x - 1, upperleft_wall.y + wall_to_door.y + y), 2, Vector2i(7, 0), 0)
					Map.set_cell(1, Vector2i(upperleft_wall.x, upperleft_wall.y + wall_to_door.y + y), 2, Vector2i(7, 0), 0)
				# door walls up
				Map.set_cell(1, Vector2i(upperleft_wall.x - 1, upperleft_wall.y + wall_to_door.y -2), 1, Vector2i(6, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x, upperleft_wall.y + wall_to_door.y -2), 1, Vector2i(8, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x - 1, upperleft_wall.y + wall_to_door.y -1), 1, Vector2i(9, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x, upperleft_wall.y + wall_to_door.y -1), 1, Vector2i(11, 0), 0)
				# door walls down
				Map.set_cell(1, Vector2i(upperleft_wall.x - 1, upperleft_wall.y + wall_to_door.y + door_size), 1, Vector2i(0, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x, upperleft_wall.y + wall_to_door.y + door_size), 1, Vector2i(2, 0), 0)
			if room.door_locations[door_i] == 'south':
				for x in range(door_size):
					Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x + x, upperleft_wall.y + s_wall.y - 1), 2, Vector2i(7, 0), 0)
					Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x + x, upperleft_wall.y + s_wall.y), 2, Vector2i(7, 0), 0)
					Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x + x, upperleft_wall.y + s_wall.y + 1), 2, Vector2i(7, 0), 0)
				#wall left
				Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x -1 , upperleft_wall.y + s_wall.y - 1), 1, Vector2i(2, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x -1, upperleft_wall.y + s_wall.y), 1, Vector2i(8, 0), 0)
				#wall right
				Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x + door_size , upperleft_wall.y + s_wall.y - 1), 1, Vector2i(0, 0), 0)
				Map.set_cell(1, Vector2i(upperleft_wall.x + wall_to_door.x + door_size, upperleft_wall.y + s_wall.y), 1, Vector2i(6, 0), 0)
		
#	for room in $Rooms.get_children():
#		# carve connecting corridor first
#		var p = path.get_closest_point(room.position)
#		for conn in path.get_point_connections(p):
#			if not conn in corridors:
#				var start = Map.local_to_map(path.get_point_position(p))
#				var end = Map.local_to_map(path.get_point_position(conn))
#				carve_path(start, end)
#		corridors.append(p)
#		#then add the rooms
#		var s = ((room.size / tile_size) / 2).floor()
#		var pos = Map.local_to_map(room.position)
#		var upperleft = (room.position / tile_size).floor() - s
#		for x in range(2, s.x * 2 -1):
#			for y in range(2, s.y * 2 -1):
#				Map.set_cell(1, Vector2i(upperleft.x + x, upperleft.y + y), 2, Vector2i(7, 0), 0) #floor

func _draw():
	#print("enter draw")
	queue_redraw()
	#for room in $Rooms.get_children():
		#draw_rect(room.rect_area, Color(0,0,255), false)
		#draw_rect(Rect2(room.position- (room.size / 2), room.size), Color(32,228,0), false)
		#draw_circle(room.position, 10, Color(255,0,0))
		#draw_circle(room.upper_left, 10, Color(255,0,0))
		#for door in room.door_position:
		#	draw_line(door, door + Vector2(door_size * tile_size, 0), Color(255,0,0), 1, true)
