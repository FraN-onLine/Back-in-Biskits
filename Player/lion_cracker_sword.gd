# In LionCrackerSword script
extends Node2D  # or whatever node type it is

func _ready():
	visible = false  # Start hidden

func perform_swing(potency: int):
	print("Performing swing with potency: ", potency)
	visible = true
	# Add your attack logic here
	# Play animation, detect enemies, etc.
	
	# Hide after a short time
	await get_tree().create_timer(0.5).timeout
	visible = false
