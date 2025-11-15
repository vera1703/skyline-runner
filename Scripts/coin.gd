extends Area2D

@export var value := 1 

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# TODO: Score erhöhen
		queue_free()
