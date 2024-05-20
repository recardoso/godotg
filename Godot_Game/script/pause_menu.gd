extends Control

# @onready var pause_menu = $"."

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("pause"):
		var pause_state = not get_tree().paused
		get_tree().paused = pause_state
		visible = pause_state

func _on_resume_pressed():
	var pause_state = not get_tree().paused
	get_tree().paused = pause_state
	visible = pause_state
	
func _on_main_menu_pressed():
	#unpause to be able to move in main menu
	#TODO: add if suer you want to quit
	var pause_state = not get_tree().paused
	get_tree().paused = pause_state
	visible = pause_state
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	
func _on_quit_pressed():
	#TODO: add if suer you want to quit
	get_tree().quit()
