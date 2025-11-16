extends Control


func _ready():
	get_tree().paused = false
	
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
	print ("Pressed")
	
func _on_quit_pressed() -> void:
	get_tree().quit()
	
