extends Control

# Battle intro popup, spawned by a hallway Teleporter.
# Fill it with setup() BEFORE adding it to the scene tree.

@onready var title_label: Label = $Stagename
@onready var time_label: Label = $Time
@onready var boss_icon_rect: TextureRect = $BossIcon
@onready var battle_button: TextureButton = $BattleButton
@onready var back_button: Button = $BackButton

var _config: Dictionary = {}

func setup(config: Dictionary) -> void:
	_config = config


func _ready() -> void:
	title_label.text = str(_config.get("title", "BOSS BATTLE"))
	battle_button.pressed.connect(_on_battle_begin_pressed)
	back_button.pressed.connect(queue_free)

	var icon: Texture2D = _config.get("boss_icon", null)
	if icon:
		boss_icon_rect.texture = icon
	else:
		boss_icon_rect.visible = false

	var stage: int = int(_config.get("best_time_stage", 0))
	var best: float = Global.get_best_time(stage)
	if stage <= 0 or best <= 0.0:
		time_label.text = "Best time: --:--"
	else:
		time_label.text = "Best time: " + Global.format_time(best)

	_populate_cookies()


func _populate_cookies() -> void:
	var cookies: Array = _config.get("cookies", [])
	for i in range(6):
		var slot: TextureRect = get_node("Container/Cookie-%d" % (i + 1))
		if i < cookies.size() and cookies[i] != null:
			slot.texture = _cookie_icon(cookies[i])
			slot.visible = true
		else:
			slot.visible = false


func _cookie_icon(c: Cookie) -> Texture2D:
	if c.icon_texture:
		return c.icon_texture
	if c.atlas_texture:
		var at := AtlasTexture.new()
		at.atlas = c.atlas_texture
		at.region = Rect2(0, 0, 32, 32)
		return at
	return null


func _on_battle_begin_pressed() -> void:
	var next: String = str(_config.get("next_scene", ""))
	if next != "":
		Global.timer = 0
		Global.warning_enabled = false
		FadeManager.fade_out_then_change_scene(next)
	else:
		queue_free()
