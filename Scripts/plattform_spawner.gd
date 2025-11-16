extends Node2D

@export var building_scenes: Array[PackedScene] = []
@export var coin_scene: PackedScene
@export var platforms_root: Node2D
@export var player: Node2D

var camera: Camera2D = null

@export var look_ahead: float = 1200.0
@export var y_min: float = 400.0
@export var y_max: float = 500.0
@export var max_height_difference: float = 80.0
@export var gap_min: float = 200.0
@export var gap_max: float = 400.0
@export var despawn_distance: float = 900.0

@export var start_platform_scene: PackedScene
@export var start_platform_x: float = 200.0
@export var start_platform_y: float = 350.0

var rng := RandomNumberGenerator.new()
var last_platform_right_x: float = 0.0
var last_platform_y: float = 0.0

var debug_enabled: bool = false  
var debug_frame_count: int = 0
var last_player_x: float = 0.0

@export var coin_height_offset: float = 50.0
@export var coin_height_min: float = 40.0
@export var coin_height_max: float = 120.0

var max_coins_per_platform: int = 3

func _ready() -> void:
	rng.randomize()
	camera = get_viewport().get_camera_2d()
	
	if start_platform_scene and platforms_root:
		var s := start_platform_scene.instantiate() as Node2D
		platforms_root.add_child(s)
		s.position = Vector2(start_platform_x, start_platform_y)
		last_platform_right_x = _get_right_edge(s)
		last_platform_y = start_platform_y
	
	_ensure_platforms_ahead()

func _process(delta: float) -> void:
	if camera == null or not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()
	
	debug_frame_count += 1
	
	var tracking_position := _get_tracking_position()
	
	if tracking_position == 0.0 and camera == null and player == null:
		return
	
	if platforms_root == null:
		return
	
	if debug_enabled and abs(tracking_position - last_player_x) > 10.0:
		last_player_x = tracking_position
	
	_ensure_platforms_ahead()
	_despawn_behind()

func _ensure_platforms_ahead() -> void:
	var tracking_pos := _get_tracking_position()
	
	if tracking_pos == 0.0:
		return
	
	if last_platform_right_x == 0.0:
		last_platform_right_x = tracking_pos
		last_platform_y = (y_min + y_max) / 2.0
	
	var target_x := tracking_pos + look_ahead
	
	var spawned_count := 0
	var safety_counter := 0
	
	while last_platform_right_x < target_x:
		var success := _spawn_next_building()
		if not success:
			break
		
		spawned_count += 1
		safety_counter += 1
		
		if safety_counter > 100:
			break

func _spawn_next_building() -> bool:
	if building_scenes.is_empty():
		return false
	
	var gap := rng.randf_range(gap_min, gap_max)
	var left_x := last_platform_right_x + gap
	
	var index := rng.randi_range(0, building_scenes.size() - 1)
	var scene: PackedScene = building_scenes[index]
	if scene == null:
		return false
	
	var building := scene.instantiate() as Node2D
	if building == null:
		return false
	
	platforms_root.add_child(building)
	
	var y_offset := rng.randf_range(-max_height_difference, max_height_difference)
	var y := last_platform_y + y_offset
	y = clamp(y, y_min, y_max)
	
	var width := _get_building_width(building)
	var center_x := left_x + width * 0.5
	building.position = Vector2(center_x, y)
	
	last_platform_right_x = center_x + width * 0.5
	last_platform_y = y
	
	_spawn_coins_on_building(building, center_x, y, width)
	
	return true

func _spawn_coins_on_building(building: Node2D, platform_center_x: float, platform_y: float, platform_width: float) -> void:
	if coin_scene == null:
		return
	
	var coin_count := rng.randi_range(0, max_coins_per_platform)
	if coin_count == 0:
		return
	
	var building_height := _get_building_height(building)
	
	for i in range(coin_count):
		var coin := coin_scene.instantiate() as Node2D
		if coin == null:
			continue
		
		platforms_root.add_child(coin)
		
		var x_offset := rng.randf_range(-platform_width * 0.3, platform_width * 0.3)
		var coin_x := platform_center_x + x_offset
		
		var random_height_offset := rng.randf_range(coin_height_min, coin_height_max)
		var coin_y := platform_y - (building_height * 0.5) - random_height_offset
		
		coin.position = Vector2(coin_x, coin_y)

func _despawn_behind() -> void:
	var tracking_pos := _get_tracking_position()
	if tracking_pos == 0.0:
		return
	
	var limit_x := tracking_pos - despawn_distance
	for b in platforms_root.get_children():
		if b == null or not is_instance_valid(b):
			continue
		
		var right := _get_right_edge(b)
		if right < limit_x:
			b.queue_free()

func _get_building_width(building: Node2D) -> float:
	if building == null or not is_instance_valid(building):
		return 200.0
	
	var sprite := building.get_node_or_null("Sprite2D")
	if sprite and sprite is Sprite2D and sprite.texture:
		var s := sprite as Sprite2D
		return s.texture.get_width() * s.scale.x
	
	return 200.0

func _get_building_height(building: Node2D) -> float:
	if building == null or not is_instance_valid(building):
		return 300.0
	
	var sprite := building.get_node_or_null("Sprite2D")
	if sprite and sprite is Sprite2D and sprite.texture:
		var s := sprite as Sprite2D
		return s.texture.get_height() * s.scale.y
	
	return 300.0

func _get_right_edge(building: Node2D) -> float:
	if building == null or not is_instance_valid(building):
		return 0.0
	
	var w := _get_building_width(building)
	return building.position.x + w * 0.5

func _get_tracking_position() -> float:
	if camera != null and is_instance_valid(camera):
		return camera.global_position.x
	elif player != null:
		return player.global_position.x
	else:
		return 0.0
