extends Node2D

@export var building_scenes: Array[PackedScene] = []
@export var platforms_root: Node2D

@export var scroll_speed: float = 200.0
@export var spawn_x: float = 800.0

@export var y_min: float = 250.0
@export var y_max: float = 350.0

@export var gap_min: float = 280.0
@export var gap_max: float = 520.0

@export var despawn_x: float = -400.0

@export var start_platform_scene: PackedScene
@export var start_platform_x: float = 200.0
@export var start_platform_y: float = 350.0

@export var preload_count: int = 5             # 🔹 NEU: wie viele Plattformen am Start

var rng := RandomNumberGenerator.new()

var distance_since_last_spawn: float = 0.0
var next_gap: float = 400.0

var last_building: Node2D = null               # 🔹 NEU: letzte Plattform merken


func _ready() -> void:
	rng.randomize()
	next_gap = rng.randf_range(gap_min, gap_max)

	# 1) Startplattform (breit, mittig)
	if start_platform_scene:
		var s := start_platform_scene.instantiate() as Node2D
		platforms_root.add_child(s)
		s.position = Vector2(start_platform_x, start_platform_y)
		last_building = s                           # 🔹 WICHTIG: als "letzte" Plattform merken

	# 2) Weitere Plattformen rechts vorspawnen – OHNE Überlappung
	for i in range(preload_count):                 # 🔹 jetzt nur noch spawn_building()
		spawn_building()


func _process(delta: float) -> void:
	if platforms_root == null:
		return

	# 1) Alle Plattformen nach links scrollen
	for building in platforms_root.get_children():
		building.position.x -= scroll_speed * delta

		if building.position.x < despawn_x:
			building.queue_free()

	# 2) Strecke hochzählen (wie weit die Welt "gelaufen" ist)
	distance_since_last_spawn += scroll_speed * delta

	# 3) Neue Plattform, wenn genug Strecke vergangen ist
	if distance_since_last_spawn >= next_gap:
		spawn_building()
		distance_since_last_spawn = 0.0
		next_gap = rng.randf_range(gap_min, gap_max)


func spawn_building() -> void:                    # 🔹 KOMPLETT NEU AUFGEBAUT
	if building_scenes.is_empty() or platforms_root == null:
		return

	var index := rng.randi_range(0, building_scenes.size() - 1)
	var scene: PackedScene = building_scenes[index]
	if scene == null:
		return

	var building := scene.instantiate() as Node2D
	platforms_root.add_child(building)

	# Höhe randomisieren
	var y := rng.randf_range(y_min, y_max)

	# Breite der neuen Plattform ermitteln
	var new_width := get_building_width(building)

	var x: float
	if last_building:
		# rechte Kante der letzten Plattform:
		var last_width := get_building_width(last_building)
		var last_right := last_building.position.x + last_width * 0.5

		# neue Plattform rechts daneben: letzte rechte Kante + zufälliger Abstand + halbe neue Breite
		x = last_right + rng.randf_range(gap_min, gap_max) + new_width * 0.5
	else:
		# falls noch keine Plattform existiert (Sicherheitsfall)
		x = spawn_x

	building.position = Vector2(x, y)
	last_building = building                        # 🔹 neue Plattform merken


func get_building_width(building: Node2D) -> float: # 🔹 NEU: Breite aus Sprite holen
	# Erwartung: Jede Plattform-Szene hat einen Knoten "Sprite2D"
	var sprite := building.get_node_or_null("Sprite2D")
	if sprite and sprite is Sprite2D and sprite.texture:
		var s := sprite as Sprite2D
		return s.texture.get_width() * s.scale.x

	# Fallback, falls kein Sprite gefunden wird
	return 200.0
