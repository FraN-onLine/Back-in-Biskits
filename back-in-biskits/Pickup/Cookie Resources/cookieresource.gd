extends Resource
class_name Cookie

@export var cookie_type: String = "basic_cookie"   # what Player uses to switch attacks
@export var cookie_name: String = "Basic Cookie"   # display name
@export var atlas_texture: Texture2D               # spritesheet
@export var icon_texture: Texture2D                # for popup
@export var min_potency: int = 1                    # minimum effect strength
@export var pickup_message: String = "Item Obtained"
@export var attack_cooldown: float = 0.0  # cd of the attack
#yah
