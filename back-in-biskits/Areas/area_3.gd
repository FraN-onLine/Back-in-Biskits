extends Node2D

# Area 3: Cookout Craze - environmental hazard stage.
# The Stage AnimatedSprite2D randomly plays flame_1..flame_4 every 5 seconds.
# The matching Attack1..Attack4 Area2D only deals damage during animation
# frames 7-11, then the Stage returns to its default sprite.

@export var flame_interval: float = 3
@export var attack_damage: int = 1

@onready var stage: AnimatedSprite2D = $Stage

var _attack_areas: Array[Area2D] = []
var _flame_idx: int = 0
var _hit_done: bool = false


func _ready() -> void:
	Global.stage = 3
	Global.potency_paused = false
	var ui_node = get_tree().get_first_node_in_group("ui")
	if ui_node and ui_node.has_method("begin_battle"):
		ui_node.begin_battle()
	elif ui_node and ui_node.has_method("start_stopwatch"):
		ui_node.start_stopwatch()

	# Collect the attack areas tied to each flame animation (StoveAttacks/Attack1..4)
	for i in range(1, 5):
		var area := get_node_or_null("StoveAttacks/Attack%d" % i) as Area2D
		if area:
			area.monitoring = false
			_attack_areas.append(area)

	stage.animation_finished.connect(_on_stage_animation_finished)
	stage.play("default")
	_start_flame_cycle()


func _process(_delta: float) -> void:
	_update_attack_areas()
	_check_hit()


# ---------------- Flame cycle ----------------
func _start_flame_cycle() -> void:
	while true:
		await get_tree().create_timer(flame_interval).timeout
		if not is_instance_valid(self):
			return
		_trigger_flame()


func _trigger_flame() -> void:
	# Only roll flame animations that actually have frames assigned.
	var candidates: Array[int] = []
	for i in range(1, 5):
		var anim := "flame_%d" % i
		if stage.sprite_frames.has_animation(anim) and stage.sprite_frames.get_frame_count(anim) > 0:
			candidates.append(i)
	if candidates.is_empty():
		return
	var idx: int = candidates.pick_random()
	_flame_idx = idx
	_hit_done = false
	stage.play("flame_%d" % idx)


func _on_stage_animation_finished() -> void:
	if _flame_idx > 0:
		_flame_idx = 0
		_hit_done = false
		stage.play("default")


# ---------------- Attack areas ----------------
func _update_attack_areas() -> void:
	var active := -1
	if _flame_idx > 0 and stage.is_playing() and stage.animation == "flame_%d" % _flame_idx:
		if stage.frame >= 7 and stage.frame <= 11:
			active = _flame_idx - 1
	for i in range(_attack_areas.size()):
		_attack_areas[i].monitoring = (i == active)


func _check_hit() -> void:
	if _flame_idx == 0 or _hit_done:
		return
	var area: Area2D = _attack_areas[_flame_idx - 1]
	if not area.monitoring:
		return
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(attack_damage, (body.global_position - area.global_position).normalized())
			_hit_done = true
			return
