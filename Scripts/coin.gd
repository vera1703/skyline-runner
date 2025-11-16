extends Area2D

@export var value := 1

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		var main = get_tree().current_scene
		
		if main and main.has_method("add_score"):
			main.add_score(value)
		queue_free()
