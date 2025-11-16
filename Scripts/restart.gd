extends Button


func _ready() -> void:
	pass 



func _process(delta: float) -> void:
	pass
	
func _pressed():
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
