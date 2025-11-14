extends Node2D

# Alle möglichen Plattform-Szenen (später 10 Stück)
@export var building_scenes: Array[PackedScene] = []

# Node, unter dem alle Plattformen hängen (PlatformsRoot in Main)
@export var platforms_root: Node2D

# Referenz zum Player, damit wir wissen, wie weit er ist
@export var player: Node2D                      # 👈 NEU

# Wie weit VOR dem Spieler sollen schon Plattformen existieren?
@export var look_ahead: float = 1200.0          # 👈 NEU

# Höhenbereich der Plattformen
@export var y_min: float = 250.0
@export var y_max: float = 350.0

# Abstand zwischen Plattformen (zusätzlich zur Breite)
@export var gap_min: float = 200.0
@export var gap_max: float = 400.0

# Wie weit HINTER dem Spieler dürfen Plattformen bleiben,
# bevor wir sie löschen (Performance)?
@export var despawn_distance: float = 800.0     # 👈 NEU

# Startplattform (breit, mittig)
@export var start_platform_scene: PackedScene
@export var start_platform_x: float = 200.0
@export var start_platform_y: float = 350.0

var rng := RandomNumberGenerator.new()

# Merken, welche Plattform die zuletzt gespawnte ist
var last_building: Node2D = null


func _ready() -> void:
	rng.randomize()

	# 1) Startplattform spawnen (falls gesetzt)
	if start_platform_scene and platforms_root:
		var s := start_platform_scene.instantiate() as Node2D
		platforms_root.add_child(s)
		s.position = Vector2(start_platform_x, start_platform_y)
		last_building = s

	# 2) Direkt am Anfang genug Plattformen vor den Spieler legen
	_ensure_platforms_ahead()


func _process(delta: float) -> void:
	if player == null or platforms_root == null:
		return

	# Immer genug Plattformen vor dem Spieler?
	_ensure_platforms_ahead()

	# Alte Plattformen weit hinter dem Spieler löschen
	_despawn_behind()


# ---------------------------------------------------------
#  GENUG PLATTFORMEN VOR DEM SPIELER
# ---------------------------------------------------------

func _ensure_platforms_ahead() -> void:
	# Falls aus irgendeinem Grund keine letzte Plattform gesetzt ist:
	if last_building == null:
		var first := _spawn_building_after_x(player.global_position.x)
		if first:
			last_building = first

	# Wir wollen, dass Plattformen mindestens bis player.x + look_ahead reichen
	var target_x := player.global_position.x + look_ahead

	# Solange die rechte Kante der letzten Plattform noch vor target_x liegt:
	while _get_right_edge(last_building) < target_x:
		var next := _spawn_next_building()
		if next:
			last_building = next
		else:
			break


# Spawnt eine Plattform rechts von der letzten Plattform (mit Abstand)
func _spawn_next_building() -> Node2D:
	if last_building == null:
		return _spawn_building_after_x(player.global_position.x)

	var last_right := _get_right_edge(last_building)
	var gap := rng.randf_range(gap_min, gap_max)

	# Linke Kante der neuen Plattform = rechte Kante der letzten + gap
	var left_x := last_right + gap
	return _spawn_building_with_left_edge(left_x)


# Erste Plattform, wenn noch keine existiert → nach Spieler
func _spawn_building_after_x(x: float) -> Node2D:
	var gap := rng.randf_range(gap_min, gap_max)
	var left_x := x + gap
	return _spawn_building_with_left_edge(left_x)


# Spawnt neue Plattform so, dass ihre LINKE Kante bei left_x liegt
func _spawn_building_with_left_edge(left_x: float) -> Node2D:
	if building_scenes.is_empty():
		return null

	var index := rng.randi_range(0, building_scenes.size() - 1)
	var scene: PackedScene = building_scenes[index]
	if scene == null:
		return null

	var building := scene.instantiate() as Node2D
	platforms_root.add_child(building)

	var width := _get_building_width(building)
	var center_x := left_x + width * 0.5
	var y := rng.randf_range(y_min, y_max)

	building.position = Vector2(center_x, y)
	return building


# ---------------------------------------------------------
#  PLATFORMEN HINTER DEM SPIELER LÖSCHEN
# ---------------------------------------------------------

func _despawn_behind() -> void:
	var limit_x := player.global_position.x - despawn_distance

	for b in platforms_root.get_children():
		# rechte Kante der Plattform
		var right := _get_right_edge(b)
		if right < limit_x and b != last_building:
			b.queue_free()


# ---------------------------------------------------------
#  HILFSFUNKTIONEN: BREITE UND RECHTE KANTE
# ---------------------------------------------------------

func _get_building_width(building: Node2D) -> float:
	var sprite := building.get_node_or_null("Sprite2D")
	if sprite and sprite is Sprite2D and sprite.texture:
		var s := sprite as Sprite2D
		return s.texture.get_width() * s.scale.x

	# Fallback, falls kein Sprite gefunden:
	return 200.0


func _get_right_edge(building: Node2D) -> float:
	var w := _get_building_width(building)
	return building.position.x + w * 0.5
