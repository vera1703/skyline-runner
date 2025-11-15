extends CharacterBody2D

const GRAVITY := 900.0
const SPEED := 120.0
const JUMP_FORCE := -350.0

var speed_multiplier := 1.0

# --- COYOTE TIME ---
var coyote_time := 0.1
var coyote_timer := 0.0

# --- DOUBLE JUMP ---
var max_jumps := 2
var jumps_left := 2

func _physics_process(delta):

	# --- COYOTE TIME ---
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_left = max_jumps       # Sprünge zurücksetzen
	else:
		coyote_timer -= delta

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

	# --- JUMP (auch Double Jump) ---
	if Input.is_action_just_pressed("jump"):
		
		# normaler Sprung oder Sprung an Kante
		if coyote_timer > 0 or is_on_floor():
			velocity.y = JUMP_FORCE
			jumps_left -= 1
			coyote_timer = 0

		# DOUBLE JUMP
		elif jumps_left > 0:
			velocity.y = JUMP_FORCE
			jumps_left -= 1

	# --- GRAVITY ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# --- MOVE ---
	move_and_slide()

	# --- SPEED WIRD IMMER SCHNELLER ---
	speed_multiplier += 0.05 * delta
