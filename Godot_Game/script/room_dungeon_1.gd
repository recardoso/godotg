extends Node2D


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var size
var type
var number_doors
var upper_left
var door_size = 3
var tile_size = 32

var type_array = ['normal_room', 'large_room', 'secret_room', 'boss_room', 'corridor_vertical', 'corridor_horizontal']
var door_possible_locations = ['north', 'east', 'south', 'west']
var door_locations = []
var door_position = []
var door_without_room = [] 
var door_with_room = []

var overlapping_areas = false

var rect_area

func make_room(_pos, _size, _type, max_doors):
	assert( max_doors < 5, "ERROR: max_doors are 4.");
	assert(_type in type_array, "ERROR: room type must be of type normal_room, large_room, secret_room, boss_room, corridor_vertical, corridor_horizontal.")
	randomize()
	position = _pos
	size = _size
	upper_left = (position - size / 2).floor()
	type = _type
	var s = RectangleShape2D.new()
	s.size = size
	rect_area = Rect2(upper_left, size)
	if type == 'corridor':
		number_doors = 2
	else:
		number_doors = randi() % max_doors + 1
		var d_i = 0
		for d in range(number_doors):
			d_i = randi() % door_possible_locations.size()
			door_locations.append(door_possible_locations[d_i])
			door_without_room.append(d)
			door_position.append(door_position_calc(door_possible_locations[d_i]))
			door_possible_locations.remove_at(d_i)
		
func door_position_calc(location):
	if location == 'north':
		return (upper_left + Vector2((size.x - door_size * tile_size) /2, 0).floor())
	if location == 'east':
		return (upper_left + Vector2(size.x, (size.y - door_size * tile_size) /2).floor())
	if location == 'south':
		return (upper_left + Vector2((size.x - door_size * tile_size) /2, size.y).floor())
	if location == 'west':
		return (upper_left + Vector2(0, (size.y - door_size * tile_size) /2).floor())
		
func get_random_door_position():
	var d_i = randi() % door_without_room.size()
	var door = door_without_room[d_i]
	door_without_room.remove_at(d_i)
	return [door_position[door], door]

func add_door_back(door):
	door_without_room.append(door)
	
func add_to_door_with_room(door):
	door_with_room.append(door)
	
func get_next_room_position(room_size):
	var random_door = get_random_door_position()
	var door_p = random_door[0]
	var door_i = random_door[1]
	var door_l = door_locations[door_i]
	if door_l == 'north':
		return [(door_p - Vector2(0, room_size.y/2) + Vector2(door_size * tile_size / 2, 0)), door_i]
	if door_l == 'east':
		return [(door_p + Vector2(room_size.x/2, 0) + Vector2(0,door_size * tile_size / 2)), door_i]
	if door_l == 'south':
		return [(door_p + Vector2(0, room_size.y/2) + Vector2(door_size * tile_size / 2, 0)), door_i]
	if door_l == 'west':
		return [(door_p - Vector2(room_size.x/2, 0) + Vector2(0,door_size * tile_size / 2)), door_i]
	
func room():
	pass

func colides_with_room(rect2):
	return rect_area.intersects(rect2,false)

