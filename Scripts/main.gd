extends Node2D

var score: int = 0

@onready var score_label: Label = $CanvasLayer/ScoreLabel

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		pass
		
func pauseMenu():
	pass

func _ready() -> void:
	update_score_label()
	
func	add_score(amount: int = 1) -> void:
	score +=amount
	update_score_label()
	
func update_score_label() -> void:
	score_label.text = "Coins: %d" % score
