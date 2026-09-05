extends Panel

# PVZ-style almanac: one cookie per page, showing its sprite, ability and details.
signal back_pressed

# Order shown in the almanac. Add new cookies here to include them.
const COOKIES = [
	preload("res://Pickup/Cookie Resources/peanut_cookie.tres"),
	preload("res://Pickup/Cookie Resources/lion_crackers.tres"),
	preload("res://Pickup/Cookie Resources/graham.tres"),
	preload("res://Pickup/Cookie Resources/macaroon.tres"),
	preload("res://Pickup/Cookie Resources/pistachio_cookie.tres"),
	preload("res://Pickup/Cookie Resources/oreo.tres"),
	preload("res://Pickup/Cookie Resources/cookie_cat.tres"),
	preload("res://Pickup/Cookie Resources/biscoff_cookie.tres"),
	preload("res://Pickup/Cookie Resources/cookie_bag.tres"),
]

var page := 0

@onready var cookie_sprite: TextureRect = $SpriteFrame/CookieSprite
@onready var cookie_name: Label = $CookieName
@onready var ability_name: Label = $AbilityName
@onready var meta_label: Label = $MetaLabel
@onready var details_label: Label = $DetailsPanel/DetailsLabel
@onready var page_label: Label = $PageLabel

func _ready() -> void:
	$PrevButton.pressed.connect(func(): _change_page(-1))
	$NextButton.pressed.connect(func(): _change_page(1))
	$BackButton.pressed.connect(func(): back_pressed.emit())


func open() -> void:
	page = 0
	_show_page()


func _change_page(dir: int) -> void:
	page = (page + dir + COOKIES.size()) % COOKIES.size()
	_show_page()


func _show_page() -> void:
	var c: Cookie = COOKIES[page]
	cookie_name.text = c.cookie_name
	ability_name.text = c.pickup_message
	meta_label.text = "MIN POTENCY: %d    COOLDOWN: %s" % [c.min_potency, _cooldown_text(c.attack_cooldown)]
	details_label.text = c.description if c.description != "" else "No details available yet."
	page_label.text = "%d / %d" % [page + 1, COOKIES.size()]
	cookie_sprite.texture = _texture_for(c)


func _cooldown_text(cd: float) -> String:
	if cd <= 0.0:
		return "Instant"
	return "%.1fs" % cd


func _texture_for(c: Cookie) -> Texture2D:
	# Prefer the first frame of the cookie's spritesheet, fall back to its icon.
	if c.atlas_texture:
		var at := AtlasTexture.new()
		at.atlas = c.atlas_texture
		at.region = Rect2(0, 0, 32, 32)
		return at
	return c.icon_texture
