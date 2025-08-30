extends Sprite2D

@export var boss_index: int = 0  # Which boss this marker should target (0 = first boss, 1 = second boss, etc.)

@export var on_screen_offset: Vector2 = Vector2(0, -30)
@export var screen_margin: float = 60
@export var smoothing_speed: float = 8

var camera_node: Camera2D
var target_boss: Node2D

func _ready():
	camera_node = get_viewport().get_camera_2d()
	
	# Move this node to a higher CanvasLayer to ensure it renders above other UI elements
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10 # Higher than the UI CanvasLayer (which is likely 0)
	get_tree().current_scene.add_child(canvas_layer)
	
	# Remove this node from its current parent and add it to the new CanvasLayer
	var current_parent = get_parent()
	current_parent.remove_child(self)
	canvas_layer.add_child(self)
	
	find_boss()

func find_boss():
	# Search for any boss in the scene using the bosses group
	var bosses = get_tree().get_nodes_in_group("bosses")
	
	if bosses.size() > boss_index:
		target_boss = bosses[boss_index]
		print("Waypoint marker found boss ", boss_index, ": ", target_boss.name)
		return
	
	# If the specified boss_index doesn't exist, try to find any available boss
	if bosses.size() > 0:
		target_boss = bosses[0]
		print("Waypoint marker defaulting to first boss: ", target_boss.name)
		return
	
	# Fallback: search for CookieBoss class instances
	var all_nodes = get_tree().get_nodes_in_group("*")
	var cookie_bosses = []
	for node in all_nodes:
		if node is CookieBoss:
			cookie_bosses.append(node)
	
	if cookie_bosses.size() > boss_index:
		target_boss = cookie_bosses[boss_index]
		print("Waypoint marker found CookieBoss ", boss_index, ": ", target_boss.name)
		return
	elif cookie_bosses.size() > 0:
		target_boss = cookie_bosses[0]
		print("Waypoint marker defaulting to first CookieBoss: ", target_boss.name)
		return
	
	# Final fallback: search recursively for boss scripts
	var root = get_tree().current_scene
	target_boss = find_boss_recursive(root)
	if target_boss:
		print("Waypoint marker found boss via recursive search: ", target_boss.name)

func find_boss_recursive(node: Node) -> Node2D:
	# Check if current node is a boss by script name (robust for all Node2D types)
	if node.has_method("get_script") and node.get_script() and "boss" in str(node.get_script()).to_lower():
		return node as Node2D

	# Search children
	for child in node.get_children():
		var result = find_boss_recursive(child)
		if result:
			return result

	return null

func _process(delta: float) -> void:
	if not camera_node:
		camera_node = get_viewport().get_camera_2d()
		return
	
	# If we don't have a boss target, try to find one
	if not target_boss or not is_instance_valid(target_boss):
		find_boss()
		if not target_boss:
			visible = false
			return
	
	var target_global_position: Vector2 = target_boss.global_position
	var viewport_dimensions: Vector2 = get_viewport().get_visible_rect().size
	var screen_coordinates: Vector2 = (target_global_position - camera_node.global_position) * camera_node.zoom + viewport_dimensions * 0.5
	var screen_inset_rectangle: Rect2 = Rect2(Vector2.ZERO, viewport_dimensions).grow(-screen_margin)
		
	var target_display_position: Vector2
	var target_display_rotation: float

	if screen_inset_rectangle.has_point(screen_coordinates):
		target_display_position = target_global_position + on_screen_offset
		target_display_rotation = 0.0
		visible = true # Show marker even when boss is on screen
		
	else:
		visible = true
		var clamped_x = clamp(screen_coordinates.x, screen_margin, viewport_dimensions.x - screen_margin)
		var clamped_y = clamp(screen_coordinates.y, screen_margin, viewport_dimensions.y - screen_margin)
		var clamped_screen_coords: Vector2 = Vector2(clamped_x, clamped_y)
		
		target_display_position = camera_node.global_position + (clamped_screen_coords - viewport_dimensions * 0.5) / camera_node.zoom
		
		var vector_to_target: Vector2 = target_global_position - target_display_position
		target_display_rotation = vector_to_target.angle() - PI * 0.5
	global_position = lerp(global_position, target_display_position, delta * smoothing_speed)
	rotation = lerp(rotation, target_display_rotation, delta * smoothing_speed)
