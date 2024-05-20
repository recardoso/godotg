extends Node2D

var player_in_area = false

var time_in_teleporter = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play('default')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if player_in_area:
		time_in_teleporter += delta
		if time_in_teleporter >= 3:
			print('teleporting')
			time_in_teleporter = 0
			get_tree().change_scene_to_file("res://scene/first_dungeon.tscn")


func _on_portal_area_body_entered(body):
	if body.has_method('player'):
		player_in_area = true


func _on_portal_area_body_exited(body):
	if body.has_method('player'):
		player_in_area = false
