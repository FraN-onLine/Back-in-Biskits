extends Area2D

# Hallway teleporter: walk in -> interact key appears -> press "interact" (E)
# to open the Battle popup for the configured boss.

@export var display_title: String = "BOSS BATTLE"
@export var boss_icon: Texture2D
@export var cookies: Array[Cookie] = []   # available cookies (popup shows up to 6)
@export var boss_stage: int = 1           # used for best-time lookup / record
@export var next_area_path: String = ""   # scene to load on "BATTLE BEGIN"

const BATTLE_SCENE = preload("res://UI/Battle.tscn")

var player_inside := false
var _battle_popup: Control = null

@onready var interact_key: AnimatedSprite2D = $InteractKey

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interact_key.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not player_inside:
		return
	if event.is_action_pressed("interact"):
		_open_battle_popup()
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = true
	interact_key.visible = true


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = false
	interact_key.visible = false
	_close_battle_popup()


func _open_battle_popup() -> void:
	if _battle_popup and is_instance_valid(_battle_popup):
		return
	var popup: Control = BATTLE_SCENE.instantiate()
	popup.setup({
		"title": display_title,
		"boss_icon": boss_icon,
		"cookies": cookies,
		"best_time_stage": boss_stage,
		"next_scene": next_area_path,
	})
	var ui_layer: Node = get_tree().get_first_node_in_group("ui")
	if ui_layer:
		ui_layer.add_child(popup)
	else:
		get_tree().current_scene.add_child(popup)
	_battle_popup = popup
	Global.dialog_open = true


func _close_battle_popup() -> void:
	if _battle_popup and is_instance_valid(_battle_popup):
		_battle_popup.queue_free()
	_battle_popup = null
	Global.dialog_open = false
