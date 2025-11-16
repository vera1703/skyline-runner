extends Control

@onready var coins_label: Label = $Control/VBoxContainer/CoinsLabel


func set_coins(amount: int) -> void:
	coins_label.text = "Your Score: %d" % amount
	
func _on_Quit_pressed():
	get_tree().paused = false   
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
