extends CanvasLayer

@export var frames: Array[Texture2D] = []    # Images for each cutscene frame
@export var texts: Array[String] = []        # Texts for each frame
@export var type_speed: float = 0.05         # Seconds per character
@export var fade_time: float = 0.5           # Seconds for fade in/out

var current_index: int = 0
var current_text: String = ""
var typed_text: String = ""
var typing: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var typer: Timer
var fade_rect: ColorRect
var fading: bool = false

func _ready() -> void:
	# Dynamically add Timer
	typer = Timer.new()
	typer.wait_time = type_speed
	typer.one_shot = false
	add_child(typer)
	typer.timeout.connect(_on_Typer_timeout)

	# Dynamically add FadeRect
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0) # transparent black
	fade_rect.size = get_viewport().get_visible_rect().size
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)

	show_frame(0)
	set_process_input(true)


# ---------------- FRAME HANDLING ----------------
func show_frame(index: int) -> void:
	if index >= frames.size() or index >= texts.size():
		end_cutscene()
		return

	current_index = index
	typed_text = ""
	label.text = ""
	current_text = texts[index]

	# Fade out → change frame → fade in
	await fade_out()
	sprite.texture = frames[index]
	await fade_in()

	# Start typing text AFTER frame fade in
	typing = true
	typer.start()


# ---------------- TYPEWRITER ----------------
func _on_Typer_timeout() -> void:
	if typed_text.length() < current_text.length():
		typed_text += current_text[typed_text.length()]
		label.text = typed_text
	else:
		typing = false
		typer.stop()


# ---------------- INPUT ----------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and !fading:
		if typing:
			# Skip typing and instantly show full text
			label.text = current_text
			typing = false
			typer.stop()
		else:
			# Go to next frame
			show_frame(current_index + 1)


# ---------------- FADE HELPERS ----------------
func fade_out() -> void:
	fading = true
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, fade_time) # alpha to 1
	await tween.finished
	fading = false

func fade_in() -> void:
	fading = true
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, fade_time) # alpha back to 0
	await tween.finished
	fading = false


# ---------------- END ----------------
func end_cutscene() -> void:
	get_tree().change_scene_to_file("res://Screens/title_screen.tscn")
