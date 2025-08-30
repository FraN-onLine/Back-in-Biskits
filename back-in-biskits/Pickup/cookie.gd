extends Area2D

var cookie_type: String = "basic_cookie"
var cookie_name: String = "Basic Cookie"
var atlas_texture: Texture2D
var icon_texture: Texture2D
var pickup_message: String = "Item Obtained"

@export var frame_w: int = 32
@export var frame_h: int = 32
@export var columns: int = 2   # frames per row
@export var frame_count: int = 2
@export var fps: float = 2   # animation speed

@export var cookie: Cookie
@export var min_potency: int

@onready var sprite: Sprite2D = $Sprite2D

var _frame: int = 0
var _time_acc: float = 0.0

func _ready() -> void:
	if cookie and cookie.atlas_texture:
		sprite.texture = cookie.atlas_texture
		sprite.region_enabled = true
		cookie_type = cookie.cookie_type
		cookie_name = cookie.cookie_name
		icon_texture = cookie.icon_texture
		min_potency = cookie.min_potency
		pickup_message = cookie.pickup_message
		sprite.region_rect = Rect2(0, 0,frame_w, frame_h)
		
	if atlas_texture:
		sprite.texture = atlas_texture
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, frame_w, frame_h)



func _process(delta: float) -> void:
	if frame_count <= 1 or fps <= 0:
		return

	_time_acc += delta
	if _time_acc >= 1.0 / fps:
		_time_acc = 0.0
		_frame = (_frame + 1) % frame_count
		_update_sprite_region()


func _update_sprite_region() -> void:
	var col = _frame % columns
	var row = int(_frame / columns)
	var x = col * frame_w
	var y = row * frame_h
	sprite.region_rect = Rect2(x, y, frame_w, frame_h)


func _on_body_entered(body: Node) -> void:
	if body.has_method("pickup_cookie"):
		body.pickup_cookie(cookie_type, cookie.attack_cooldown, cookie.min_potency)
		queue_free()

	var display_icon = icon_texture
	if display_icon == null and atlas_texture:
		var at = AtlasTexture.new()
		at.atlas = atlas_texture
		at.region = Rect2(0, 0, frame_w, frame_h)
		display_icon = at

	if body.has_method("show_cookie_pickup"):
		body.show_cookie_pickup(pickup_message, display_icon, min_potency)

	
