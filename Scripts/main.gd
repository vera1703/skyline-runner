extends Node2D

var score: int = 0

@onready var score_label: Label = $CanvasLayer/Control/Control/ScoreLabel
@onready var game_over_menu: Control = $CanvasLayer2/GameOver

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		pass
		
func pauseMenu():
	pass

func _ready() -> void:
	update_score_label()
	game_over_menu.visible = false
	
func	add_score(amount: int = 1) -> void:
	score +=amount
	update_score_label()
	
func update_score_label() -> void:
	score_label.text = "Coins: %d" % score
	
func game_over() -> void:
	if game_over_menu and game_over_menu.has_method("set_coins"):
		game_over_menu.set_coins(score)
		game_over_menu.visible = true
		get_tree().paused = true
