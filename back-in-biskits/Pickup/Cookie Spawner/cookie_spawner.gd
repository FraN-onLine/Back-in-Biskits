extends Node2D

@export var possible_cookies: Array[Cookie] = []  # assign in inspector
@export var cookie_scene: PackedScene                    # CookiePickup.tscn

@export var spawn_interval: float = 5.0   # seconds between spawns
@export var max_active_cookies: int = 3   # limit at once

var _active_cookies: Array[Node] = []

func _ready() -> void:
	spawn_loop()


func spawn_loop() -> void:
	while true:
		await get_tree().create_timer(spawn_interval).timeout
		if _active_cookies.size() < max_active_cookies:
			spawn_cookie()


func spawn_cookie() -> void:
	if possible_cookies.is_empty():
		return

	# Filter cookies based on Global.Potency
	var valid = []
	for c in possible_cookies:
		if Global.potency >= c.min_potency:
			valid.append(c)

	if valid.is_empty():
		return

	# Pick a random cookie resource
	var chosen: Cookie = valid.pick_random()

	# Instance a CookiePickup scene
	var cookie = cookie_scene.instantiate()
	cookie.cookie = chosen   # assign resource to cookie
	add_child(cookie)

	# Pick a random spawn point (Marker2D child)
	var spawn_points = get_children().filter(func(n): return n is Marker2D)
	if spawn_points.is_empty():
		cookie.queue_free()
		return

	var spot: Marker2D = spawn_points.pick_random()
	cookie.global_position = spot.global_position

	# Track active cookies
	_active_cookies.append(cookie)
	cookie.tree_exited.connect(func(): _active_cookies.erase(cookie))
