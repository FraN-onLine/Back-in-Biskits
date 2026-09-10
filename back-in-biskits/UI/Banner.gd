extends CanvasLayer

# Giant centered banner text ("FIGHT!", "K.O.") shown during battle grace
# periods. While visible the whole SceneTree is paused (for FIGHT!), so
# neither the player nor enemies can move or attack; this node runs in
# PROCESS_MODE_ALWAYS.

# Assign your imported audio in the inspector (Banner -> fight_sfx / ko_sfx).
@export var fight_sfx: AudioStream
@export var ko_sfx: AudioStream

const FADE_IN_TIME := 0.1   # snappy fade-in
const FADE_OUT_TIME := 0.1  # snappy fade-out
const BOB_AMOUNT := 14.0
const BOB_BOUNCE := 0.6

@onready var label: Label = $Label
@onready var fight_audio: AudioStreamPlayer = $FightSfx
@onready var ko_audio: AudioStreamPlayer = $KoSfx

var _bob_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	label.visible = false
	if fight_sfx:
		fight_audio.stream = fight_sfx
	if ko_sfx:
		ko_audio.stream = ko_sfx


func show_banner(text: String, duration: float = 2.0, pause_game: bool = true) -> void:
	if not is_instance_valid(get_tree()):
		return
	if pause_game:
		get_tree().paused = true

	# Play the FIGHT! announcer audio if one is assigned
	if fight_audio.stream:
		fight_audio.play()

	label.text = text
	label.visible = true
	label.pivot_offset = label.size * 0.5  # scale from the center
	label.position = Vector2.ZERO
	label.scale = Vector2.ONE

	# "Pop in" - start at 50% alpha, small scale, then settle fast with a
	# little bounce overshoot. Fade is 50% faster than before.
	label.modulate.a = 0.5
	label.scale = Vector2(0.82, 0.82)
	var pop := create_tween().set_parallel(true)
	pop.tween_property(label, "modulate:a", 1.0, FADE_IN_TIME)
	pop.tween_property(label, "scale", Vector2.ONE, FADE_IN_TIME + 0.05) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Continuous gentle bob while the banner is on screen
	_start_bob()

	# process_always=true so the timer still fires while the tree is paused
	await get_tree().create_timer(duration, true).timeout
	if not is_instance_valid(get_tree()):
		return

	# Fluid exit - fade out quickly, then hide
	if _bob_tween and _bob_tween.is_valid():
		_bob_tween.kill()
		_bob_tween = null
	var out := create_tween().set_parallel(true)
	out.tween_property(label, "modulate:a", 0.0, FADE_OUT_TIME)
	out.tween_property(label, "scale", Vector2(1.08, 1.08), FADE_OUT_TIME)
	await out.finished

	# Reset state
	if pause_game:
		get_tree().paused = false
	label.visible = false
	label.modulate.a = 1.0
	label.scale = Vector2.ONE
	label.position = Vector2.ZERO


# K.O. banner: falls in from above like a slam, smashes into place, then fades.
# Deliberately does NOT pause the tree - the player/map keep running.
# win_time_text (optional) is a second line beneath K.O. showing the clear time.
func show_ko(win_time_text: String = "", hold_time: float = 1.2) -> void:
	if not is_instance_valid(get_tree()):
		return
	# Play the K.O. announcer audio if one is assigned
	if ko_audio.stream:
		ko_audio.play()

	if win_time_text == "":
		label.text = "K.O."
	else:
		label.text = "K.O.\nTIME  %s" % win_time_text
		# Slightly smaller so the two lines fit cleanly
		label.add_theme_font_size_override("font_size", 110)
	label.visible = true
	label.pivot_offset = label.size * 0.5
	label.modulate.a = 0.0
	label.scale = Vector2(1.0, 1.0)
	label.position = Vector2(0, -260)  # start up high

	# Drop from above with gravity (accelerating fall) + fade in
	var fall := create_tween().set_parallel(true)
	fall.tween_property(label, "position:y", 0.0, 0.45) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	fall.tween_property(label, "modulate:a", 1.0, 0.4)
	await fall.finished
	if not is_instance_valid(get_tree()):
		return

	# Bang: squash on landing, then bounce-settle to full size
	var impact := create_tween()
	impact.tween_property(label, "scale", Vector2(1.25, 0.8), 0.07) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	impact.tween_property(label, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await impact.finished

	# Hold for a beat, then fast fade out
	await get_tree().create_timer(hold_time, true).timeout
	if not is_instance_valid(get_tree()):
		return
	var out := create_tween()
	out.tween_property(label, "modulate:a", 0.0, FADE_OUT_TIME)
	await out.finished

	# Reset state
	label.visible = false
	label.modulate.a = 1.0
	label.position = Vector2.ZERO
	label.scale = Vector2.ONE


func _start_bob() -> void:
	if _bob_tween and _bob_tween.is_valid():
		_bob_tween.kill()
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(label, "position:y", BOB_AMOUNT, BOB_BOUNCE) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(label, "position:y", -BOB_AMOUNT, BOB_BOUNCE) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)