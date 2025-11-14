extends CharacterBody2D

const SPEED = 200.0
const JUMP_FORCE = -400.0
const GRAVITY = 900.0

func _physics_process(delta):
	# Schwerkraft
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Springen
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_FORCE

	# Nach rechts laufen
	velocity.x = SPEED

	move_and_slide()

	# Wenn Spieler aus dem Bild fällt → Neustart
	if global_position.y > 800:
		get_tree().reload_current_scene()
