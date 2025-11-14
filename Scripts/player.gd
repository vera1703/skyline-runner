extends CharacterBody2D

const GRAVITY := 900.0
const SPEED := 120.0
const JUMP_FORCE := -350.0

var speed_multiplier := 1.0

func _physics_process(delta):

	# --- LINKS ---
	if Input.is_action_pressed("left"):
		velocity.x = -SPEED * speed_multiplier
		$Sprite2D.flip_h = false

	# --- RECHTS ---
	elif Input.is_action_pressed("right"):
		velocity.x = SPEED * speed_multiplier
		$Sprite2D.flip_h = true

	# --- IDLE ---
	else:
		velocity.x = 0

	# --- JUMP ---
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_FORCE

	# --- GRAVITY ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# --- MOVE ---
	move_and_slide()

	# --- SPEED WIRD IMMER SCHNELLER ---
	speed_multiplier += 0.05 * delta
