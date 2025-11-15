extends Area2D

@export var value := 1

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Get the ScoreLabel node and add score
		var score_label = get_tree().get_first_node_in_group("score_label")
		if score_label:
			score_label.add_score(value)
		queue_free()
