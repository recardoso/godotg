extends CharacterBody2D

var speed = 100
var player_state
var previous_direction = Input.get_vector("left","right", "up", "down")

var _step = 0
var _step_to_move = 64 * 3
var _step_size = (1 / _step_to_move)

func _physics_process(delta):
	
	#print(delta)
	
	_step += delta
	#print(_step)
	
	
	var direction = Input.get_vector("left","right", "up", "down")
	
	if direction.x == 0 and direction.y == 0:
		player_state = 'idle'
	elif direction.x != 0 or direction.y != 0:
		player_state = 'walking'
		previous_direction = direction
		
	velocity = direction * _step_to_move * delta #pixels per second
	#move_and_slide()
	move_and_collide(velocity)
	
	play_anim(direction)

func play_anim(direction):
	if player_state == 'idle':
		if previous_direction.y == 1:
			$AnimatedSprite2D.play('idle_south')
		if previous_direction.y == -1:
			$AnimatedSprite2D.play('idle_north')
		if previous_direction.x == 1:
			$AnimatedSprite2D.play('idle_east')
		if previous_direction.x == -1:
			$AnimatedSprite2D.play('idle_west')
	if player_state == 'walking':
		if direction.y == 1:
			$AnimatedSprite2D.play('walk_south')
		if direction.y == -1:
			$AnimatedSprite2D.play('walk_north')
		if direction.x == 1:
			$AnimatedSprite2D.play('walk_east')
		if direction.x == -1:
			$AnimatedSprite2D.play('walk_west')
			
func player():
	pass
	
func _input(event):
	if event.is_action_pressed('scroll_up'):
		$Camera2D.zoom = $Camera2D.zoom + Vector2(0.1, 0.1)
	if event.is_action_pressed('scroll_down'):
		$Camera2D.zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
