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
	var valid: Array[Cookie] = []
	for c in possible_cookies:
		if Global.potency >= c.min_potency:
			valid.append(c)

	if valid.is_empty():
		return

	# Instance a CookiePickup scene
	var cookie = cookie_scene.instantiate()
	cookie.cookie = valid.pick_random()

	# Get spawn points (Marker2Ds)
	var spawn_points = get_children().filter(func(n): return n is Marker2D)
	if spawn_points.is_empty():
		cookie.queue_free()
		return

	# Shuffle spawn points so it tries random ones until it finds a free spot
	spawn_points.shuffle()

	var placed := false
	for spot in spawn_points:
		var spot_pos: Vector2 = spot.global_position
		var too_close := false

		for existing in _active_cookies:
			if existing.global_position.distance_to(spot_pos) < 10:
				too_close = true
				break

		if not too_close:
			# Found a free spot → place cookie here
			add_child(cookie)
			cookie.global_position = spot_pos
			_active_cookies.append(cookie)
			cookie.tree_exited.connect(func(): _active_cookies.erase(cookie))
			placed = true
			break

	# If no spot was valid, discard the cookie
	if not placed:
		cookie.queue_free()
