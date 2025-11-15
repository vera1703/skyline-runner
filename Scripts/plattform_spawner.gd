extends Node2D

# Alle möglichen Plattform-Szenen
@export var building_scenes: Array[PackedScene] = []
@export var coin_scene: PackedScene

# Node, unter dem alle Plattformen hängen
@export var platforms_root: Node2D

# Referenz zum Player
@export var player: Node2D

var camera: Camera2D = null

# Wie weit VOR dem Spieler sollen Plattformen existieren?
@export var look_ahead: float = 1200.0

# Höhenbereich der Plattformen (absolute Werte)
@export var y_min: float = 400.0
@export var y_max: float = 500.0

# Maximaler Höhenunterschied zur vorherigen Plattform
@export var max_height_difference: float = 80.0

# Abstand zwischen Plattformen
@export var gap_min: float = 200.0
@export var gap_max: float = 400.0

# Wie weit HINTER dem Spieler dürfen Plattformen bleiben?
@export var despawn_distance: float = 800.0

# Startplattform
@export var start_platform_scene: PackedScene
@export var start_platform_x: float = 200.0
@export var start_platform_y: float = 350.0

var rng := RandomNumberGenerator.new()
var last_platform_right_x: float = 0.0
var last_platform_y: float = 0.0

var debug_enabled: bool = true
var debug_frame_count: int = 0
var last_player_x: float = 0.0


@export var coin_height_offset: float = 50.0  # Erhöht von 30.0 auf 50.0 für bessere Positionierung

var max_coins_per_platform: int = 3


func _ready() -> void:
	rng.randomize()
	
	camera = get_viewport().get_camera_2d()
	
	print("[DEBUG] Platform Spawner _ready() aufgerufen")
	print("[DEBUG] building_scenes.size() = ", building_scenes.size())
	print("[DEBUG] platforms_root = ", platforms_root)
	print("[DEBUG] player = ", player)
	print("[DEBUG] camera (auto-detected) = ", camera)
	
	if camera:
		print("[DEBUG] Kamera erfolgreich gefunden bei Position: ", camera.global_position)
	else:
		print("[DEBUG] WARNUNG: Keine Kamera gefunden!")
	
	# Startplattform spawnen
	if start_platform_scene and platforms_root:
		var s := start_platform_scene.instantiate() as Node2D
		platforms_root.add_child(s)
		s.position = Vector2(start_platform_x, start_platform_y)
		last_platform_right_x = _get_right_edge(s)
		last_platform_y = start_platform_y
		print("[DEBUG] Startplattform gespawnt bei x=", start_platform_x, ", rechte Kante bei x=", last_platform_right_x)
	
	# Erste Plattformen spawnen
	_ensure_platforms_ahead()


func _process(delta: float) -> void:
	if camera == null or not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()
	
	debug_frame_count += 1
	
	var tracking_position := _get_tracking_position()
	
	# Debug-Ausgabe alle 60 Frames (ca. jede Sekunde)
	if debug_enabled and debug_frame_count % 60 == 0:
		print("[DEBUG Frame ", debug_frame_count, "] Tracking Position: ", tracking_position)
		if camera:
			print("[DEBUG] Camera Position: ", camera.global_position.x)
		if player:
			print("[DEBUG] Player Position: ", player.global_position.x)
		print("[DEBUG] last_platform_right_x: ", last_platform_right_x)
		print("[DEBUG] target_x (tracking + look_ahead): ", tracking_position + look_ahead)
		print("[DEBUG] Differenz: ", last_platform_right_x - (tracking_position + look_ahead))
		print("[DEBUG] Anzahl Plattformen: ", platforms_root.get_child_count() if platforms_root else 0)
	
	if tracking_position == 0.0 and camera == null and player == null:
		if debug_enabled and debug_frame_count % 60 == 0:
			print("[DEBUG] FEHLER: Weder camera noch player ist gesetzt!")
		return
	
	if platforms_root == null:
		if debug_enabled and debug_frame_count % 60 == 0:
			print("[DEBUG] FEHLER: platforms_root ist null in _process!")
		return
	
	if debug_enabled and abs(tracking_position - last_player_x) > 10.0:
		print("[DEBUG] Position bewegt sich! Von x=", last_player_x, " zu x=", tracking_position)
		last_player_x = tracking_position
	
	# Plattformen spawnen
	_ensure_platforms_ahead()
	
	# Alte Plattformen löschen
	_despawn_behind()


func _ensure_platforms_ahead() -> void:
	var tracking_pos := _get_tracking_position()
	
	if tracking_pos == 0.0:
		print("[DEBUG] _ensure_platforms_ahead: tracking_pos ist 0!")
		return
	
	# Fallback für erste Plattform
	if last_platform_right_x == 0.0:
		last_platform_right_x = tracking_pos
		last_platform_y = (y_min + y_max) / 2.0
		print("[DEBUG] last_platform_right_x war 0, jetzt gesetzt auf: ", last_platform_right_x)
	
	var target_x := tracking_pos + look_ahead
	
	var spawned_count := 0
	var safety_counter := 0
	
	while last_platform_right_x < target_x:
		var success := _spawn_next_building()
		if not success:
			print("[DEBUG] _spawn_next_building fehlgeschlagen!")
			break
		
		spawned_count += 1
		safety_counter += 1
		
		if safety_counter > 100:
			print("[DEBUG] WARNUNG: Safety counter erreicht! Abbruch nach ", spawned_count, " Plattformen")
			break
	
	if debug_enabled and spawned_count > 0:
		print("[DEBUG] ", spawned_count, " neue Plattform(en) gespawnt. last_platform_right_x jetzt: ", last_platform_right_x)


func _spawn_next_building() -> bool:
	if building_scenes.is_empty():
		print("[DEBUG] FEHLER: building_scenes ist leer!")
		return false
	
	# Gap berechnen
	var gap := rng.randf_range(gap_min, gap_max)
	var left_x := last_platform_right_x + gap
	
	# Szene auswählen
	var index := rng.randi_range(0, building_scenes.size() - 1)
	var scene: PackedScene = building_scenes[index]
	if scene == null:
		print("[DEBUG] FEHLER: building_scene an Index ", index, " ist null!")
		return false
	
	# Plattform instanzieren
	var building := scene.instantiate() as Node2D
	if building == null:
		print("[DEBUG] FEHLER: Konnte Plattform nicht instanzieren!")
		return false
	
	platforms_root.add_child(building)
	
	# Zuerst zufälligen Offset zur letzten Plattform
	var y_offset := rng.randf_range(-max_height_difference, max_height_difference)
	var y := last_platform_y + y_offset
	
	# Dann in den erlaubten Bereich clampen
	y = clamp(y, y_min, y_max)
	
	# Position berechnen
	var width := _get_building_width(building)
	var center_x := left_x + width * 0.5
	
	building.position = Vector2(center_x, y)
	
	# Neue rechte Kante und Y-Position speichern
	var old_right := last_platform_right_x
	last_platform_right_x = center_x + width * 0.5
	last_platform_y = y
	
	# Coins auf der Plattform spawnen
	_spawn_coins_on_building(building, center_x, y, width)
	
	if debug_enabled:
		print("[DEBUG] Plattform gespawnt bei x=", center_x, ", y=", y, " (Breite: ", width, "). Rechte Kante: ", old_right, " -> ", last_platform_right_x)
	
	return true


# Neue Funktion: Coins auf Plattform spawnen
func _spawn_coins_on_building(building: Node2D, platform_center_x: float, platform_y: float, platform_width: float) -> void:
	if coin_scene == null:
		print("[DEBUG] WARNUNG: coin_scene ist nicht gesetzt! Keine Coins gespawnt.")
		return
	
	# Zufällige Anzahl Coins: 0–3
	var coin_count := rng.randi_range(0, max_coins_per_platform)
	
	if coin_count == 0:
		return
	
	var building_height := _get_building_height(building)
	
	# Für jeden Coin eine Instanz erstellen
	for i in range(coin_count):
		var coin := coin_scene.instantiate() as Node2D
		if coin == null:
			print("[DEBUG] FEHLER: Konnte Coin nicht instanzieren!")
			continue
		
		# Coin zum platforms_root hinzufügen (für einfaches Cleanup)
		platforms_root.add_child(coin)
		
		# Zufällige X-Position auf der Plattform (±etwas vom Rand weg)
		var x_offset := rng.randf_range(-platform_width * 0.3, platform_width * 0.3)
		var coin_x := platform_center_x + x_offset
		
		# platform_y ist die Mitte des Gebäudes, also ziehen wir die halbe Höhe ab
		# und fügen dann coin_height_offset hinzu, um den Coin über dem Gebäude zu platzieren
		var coin_y := platform_y - (building_height * 0.5) - coin_height_offset
		
		coin.position = Vector2(coin_x, coin_y)
		
		if debug_enabled:
			print("[DEBUG] Coin ", i + 1, " von ", coin_count, " gespawnt bei x=", coin_x, ", y=", coin_y, " (Gebäudehöhe: ", building_height, ")")


func _despawn_behind() -> void:
	var tracking_pos := _get_tracking_position()
	
	if tracking_pos == 0.0:
		return
	
	var limit_x := tracking_pos - despawn_distance
	var despawned_count := 0
	
	for b in platforms_root.get_children():
		if b == null or not is_instance_valid(b):
			continue
		
		var right := _get_right_edge(b)
		if right < limit_x:
			b.queue_free()
			despawned_count += 1
	
	if debug_enabled and despawned_count > 0:
		print("[DEBUG] ", despawned_count, " Plattform(en) gelöscht")


func _get_building_width(building: Node2D) -> float:
	if building == null or not is_instance_valid(building):
		return 200.0
	
	var sprite := building.get_node_or_null("Sprite2D")
	if sprite and sprite is Sprite2D and sprite.texture:
		var s := sprite as Sprite2D
		return s.texture.get_width() * s.scale.x
	
	# Fallback
	return 200.0


func _get_building_height(building: Node2D) -> float:
	if building == null or not is_instance_valid(building):
		return 300.0  # Fallback-Höhe
	
	var sprite := building.get_node_or_null("Sprite2D")
	if sprite and sprite is Sprite2D and sprite.texture:
		var s := sprite as Sprite2D
		return s.texture.get_height() * s.scale.y
	
	# Fallback
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
