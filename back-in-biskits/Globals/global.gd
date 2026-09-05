extends Node

var lives = 5
var shield = 0
var potency = 1
var timer = 0.0
var stage = 0
var warning_enabled = false

# Best times (per boss stage)
const BEST_TIMES_PATH = "user://best_times.json"
var best_times: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_best_times()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if timer >= 6.5:
		timer = 0.0
		if potency < 3:
			potency += 1
		elif potency == 3:
			lives -= 1
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.get_node("Sprite2D").modulate = Color(1, 0.5, 0.5)
				await get_tree().create_timer(0.2).timeout
				player.get_node("Sprite2D").modulate = Color(1, 1, 1)
			
# ---------------- Best times -----------------
func load_best_times() -> void:
	if not FileAccess.file_exists(BEST_TIMES_PATH):
		return
	var file = FileAccess.open(BEST_TIMES_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_DICTIONARY:
			best_times = data
		file.close()

func save_best_times() -> void:
	var file = FileAccess.open(BEST_TIMES_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(best_times))
		file.close()

func get_best_time(stage: int) -> float:
	return float(best_times.get(str(stage), 0.0))

func submit_best_time(stage: int, time: float) -> bool:
	var key := str(stage)
	var previous := float(best_times.get(key, 0.0))
	if previous <= 0.0 or time < previous:
		best_times[key] = time
		save_best_times()
		return true
	return false

func format_time(time: float) -> String:
	time = maxf(time, 0.0)
	var minutes := int(time) / 60
	var seconds := int(time) % 60
	var centiseconds := int(fmod(time, 1.0) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]
