extends Area2D

# Every existing cookie, used when a Cookie Bag (cookie_type == "cookie_bag")
# is picked up so a random one of these effects is granted.
const COOKIE_POOL = [
	preload("res://Pickup/Cookie Resources/peanut_cookie.tres"),
	preload("res://Pickup/Cookie Resources/lion_crackers.tres"),
	preload("res://Pickup/Cookie Resources/graham.tres"),
	preload("res://Pickup/Cookie Resources/macaroon.tres"),
	preload("res://Pickup/Cookie Resources/pistachio_cookie.tres"),
	preload("res://Pickup/Cookie Resources/oreo.tres"),
	preload("res://Pickup/Cookie Resources/cookie_cat.tres"),
	preload("res://Pickup/Cookie Resources/biscoff_cookie.tres"),
]

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
	if cookie:
		cookie_type = cookie.cookie_type
		cookie_name = cookie.cookie_name
		icon_texture = cookie.icon_texture
		min_potency = cookie.min_potency
		pickup_message = cookie.pickup_message
		if cookie.atlas_texture:
			sprite.texture = cookie.atlas_texture
			sprite.region_enabled = true
			sprite.region_rect = Rect2(0, 0, frame_w, frame_h)
		else:
			# No texture assigned yet (e.g. Cookie Bag) -> keep the sprite blank
			sprite.texture = null
			sprite.region_enabled = false

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


# Cookie Bag: swap this pickup for a random existing cookie that the player
# can actually use at their current potency (same filter as the cookie spawner).
func _roll_cookie_bag() -> void:
	var valid: Array[Cookie] = []
	for c in COOKIE_POOL:
		var candidate: Cookie = c
		if Global.potency >= candidate.min_potency:
			valid.append(candidate)

	if valid.is_empty():
		return  # keep as-is; pickup_cookie() will handle a void pickup

	var rolled: Cookie = valid.pick_random()
	cookie = rolled
	cookie_type = rolled.cookie_type
	cookie_name = rolled.cookie_name
	icon_texture = rolled.icon_texture
	pickup_message = "Cookie Bag: " + rolled.pickup_message
	min_potency = rolled.min_potency
	atlas_texture = rolled.atlas_texture


func _on_body_entered(body: Node) -> void:
	if body.has_method("pickup_cookie"):
		if cookie_type == "cookie_bag":
			_roll_cookie_bag()
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

	
