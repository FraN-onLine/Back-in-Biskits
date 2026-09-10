extends Node

var lives = 5
var shield = 0
var potency = 1
var timer = 0.0
var stage = 0
var warning_enabled = false
var dialog_open = false       # true while the battle popup is up (player locked)
var potency_paused = false    # true in hallways (no potency accumulation)
var last_death_time := 0.0    # stopwatch time of the run the player just died on
var last_fight_time := 0.0    # stopwatch time of the last won fight

# Best times (per boss stage)
const BEST_TIMES_PATH = "user://best_times.json"
var best_times: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_best_times()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_tick_timescale()
	if potency_paused:
		return
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
				if player:
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


# ---------------- Game feel (hit-stop / kill slow-mo) ----------------
const MIN_TIME_SCALE := 0.01  # never reach 0: ts=0 can halt SceneTree process
							 # iteration, which would prevent our own restore
var _time_scale_requests := 0
var _timescale_pending := false
var _timescale_end_msec := 0

# Micro freeze-frame when attacks land.
func hitstop(duration: float = 0.05) -> void:
	await _apply_time_scale(0.0, duration)

# Brief slow-motion drop before the K.O. banner.
func kill_slowmo(duration: float = 0.45, scale: float = 0.18) -> void:
	await _apply_time_scale(scale, duration)

# Central time-scale controller. Multiple overlapping requests are tracked so
# the last one to finish restores normal speed.
#
# The freeze window is tracked in REAL time and the engine is restored from
# _tick_timescale()/_self_heal_timescale() (run every frame). time_scale is
# clamped above 0 so the SceneTree keeps iterating (process_frame keeps
# firing, Global._process keeps running) and the restore always happens.
func _apply_time_scale(scale: float, duration: float) -> void:
	if not is_instance_valid(get_tree()):
		Engine.time_scale = 1.0
		return
	var safe_scale := maxf(scale, MIN_TIME_SCALE)
	_time_scale_requests += 1
	if _time_scale_requests == 1:
		Engine.time_scale = safe_scale
	var end_msec := Time.get_ticks_msec() + int(duration * 1000.0)
	_timescale_end_msec = maxi(_timescale_end_msec, end_msec)
	_timescale_pending = true

	# Wait for the real-time window to elapse.
	while _timescale_pending and is_instance_valid(get_tree()):
		await get_tree().process_frame
		if Time.get_ticks_msec() >= _timescale_end_msec:
			break

	_time_scale_requests -= 1
	if _time_scale_requests <= 0:
		_time_scale_requests = 0
		_timescale_pending = false
		_timescale_end_msec = 0
		Engine.time_scale = 1.0


# Called every frame: clears the pending flag once the real-time window ends,
# then restores the engine in case a coroutine died (scene change, etc).
# This makes the system fully self-healing - a freeze can never outlive its
# duration by more than one frame.
func _tick_timescale() -> void:
	if _timescale_pending and Time.get_ticks_msec() >= _timescale_end_msec:
		_timescale_pending = false
	if not _timescale_pending and Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
