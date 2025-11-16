extends CharacterBody2D

@onready var anim = $AnimatedSprite2D

const GRAVITY := 900.0
const SPEED := 120.0
const JUMP_FORCE := -450.0
const MAX_SPEED_MULTIPLIER := 2.5  

var speed_multiplier := 1.0

# --- COYOTE TIME ---
var coyote_time := 0.2
var coyote_timer := 0.0

# --- DOUBLE JUMP ---
var max_jumps := 2
var jumps_left := 2

func _physics_process(delta):
	if position.y > 900:
		var main = get_tree().current_scene
		if main and main.has_method("game_over"):
			main.game_over()
			return  

	# --- COYOTE TIME ---
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_left = max_jumps
	else:
		coyote_timer -= delta

	# --- LINKS ---
	if Input.is_action_pressed("left"):
		velocity.x = -SPEED * speed_multiplier
		anim.flip_h = true   # LINKS

	# --- RECHTS ---
	elif Input.is_action_pressed("right"):
		velocity.x = SPEED * speed_multiplier
		anim.flip_h = false  # RECHTS

	# --- IDLE ---
	else:
		velocity.x = 0

	# --- JUMP + DOUBLE JUMP ---
	if Input.is_action_just_pressed("jump"):
		if coyote_timer > 0 or is_on_floor():
			velocity.y = JUMP_FORCE
			jumps_left -= 1
			coyote_timer = 0

		elif jumps_left > 0:
			velocity.y = JUMP_FORCE
			jumps_left -= 1

	# --- GRAVITY ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# --- MOVE ---
	move_and_slide()

	
	speed_multiplier = min(speed_multiplier + 0.05 * delta, MAX_SPEED_MULTIPLIER)  

	# --- ANIMATION ---
	update_animation()
	

func update_animation():
	if not is_on_floor():
		if velocity.y < 0:
			anim.play("jump")
		return

	if velocity.x == 0:
		anim.play("idle")
	else:
		anim.play("run")
