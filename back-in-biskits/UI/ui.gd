extends CanvasLayer
var blink = false
var stopwatch_time := 0.0
var stopwatch_running := false
@onready var stopwatch_label = $StopwatchLabel

func _ready():
	add_to_group("ui")

func start_stopwatch():
	stopwatch_time = 0.0
	stopwatch_running = true
	stopwatch_label.text = "00:00.00"


func _process(delta: float) -> void:
	if stopwatch_running:
		stopwatch_time += delta
		stopwatch_label.text = format_time(stopwatch_time)

	var boss = get_tree().get_first_node_in_group("boss")
	if boss:
		$BossLabel.visible = true
		$Healthbar.visible = true
		$HPLabel.visible = true
		$HPLabel.text = "HP: " + str(boss.current_hp) + "/" + str(boss.max_hp)
		$BossLabel.text = boss.boss_name
	else:
		$BossLabel.visible = false
		$Healthbar.visible = false
		$HPLabel.visible = false
	$TextureRect.size.x = Global.lives * 32
	$Label.text = "Potency: " + str(Global.potency)
	$PotencyRect.size.x = Global.potency * 32
	$ShieldRect.size.x = Global.shield * 32
	if Global.potency == 3 and Global.timer >= 4 and blink == false:
		blink = true
		$PotencyRect.modulate = Color(1, 0.5, 0.5) # light red
		await get_tree().create_timer(1.2).timeout
		$PotencyRect.modulate = Color(1, 1, 1)
		blink = false
	if Global.potency == 3 and Global.timer >= 9.5:
		$PotencyRect.modulate = Color(1, 1, 1)
	if Global.lives == 0:
		$TextureRect.visible = false
	if Global.potency == 0:
		$PotencyRect.visible = false
	else:
		$PotencyRect.visible = true
	if Global.shield == 0:
		$ShieldRect.visible = false
	else:
		$ShieldRect.visible = true
		#btw potency can reach 0, 0 potency means all buffs are null and void
		# so dont eat too much or else ull suffer doing nothing

func stop_stopwatch():
	stopwatch_running = false

func get_stopwatch_time() -> float:
	return stopwatch_time

func format_time(time: float) -> String:
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var centiseconds = int((time - int(time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, centiseconds]
		
	
#ok push ko 9:50, by then everything should be done na necessary for yall to build on
#bosses 2-4
#UI
#title screen, death screen, proceed to next stage on boss defeat
#sound effects
#weapons
#lots and lots of weapons and polish
#lol copilot thinks thats it
#and maybe a main menu (copilot said so) these are srs, i want a movie adaptation, til tutorial screen pero like prototype,
# maybe tutorial stage kung gusto niyo, yes meron per boss lang nacode ko so....
# oh and wait i forgot what i was gonna say, ah yes layout niyo yung stages 3-4 w/ tilemaps (Tilemap Layer btw not TileMap) ginamit kasi sa raniag
# nowp, ask reign and cass, reign, ask reign, ok thats it, ss mo til vr mode (copilot said so)
#and a pause menu (copilot said so)
#and a credits screen (copilot said so)
#and a tutorial screen (copilot said so)
#and a settings menu (copilot said so)
#and a high score screen (copilot said so)
#and a level select screen (copilot said so)
#and a save/load system (copilot said so)
#and a multiplayer mode (copilot said so)
#and a level editor (copilot said so)
#and a modding API (copilot said so)
#and a steam workshop integration (copilot said so)
#and a VR mode (copilot said so)
#and a mobile port (copilot said so)
#and a console port (copilot said so)
#and a sequel (copilot said so)
#and a prequel (copilot said so)
#and a spin-off (copilot said so)
#and a movie adaptation (copilot said so)
#and a TV series adaptation (copilot said so)
#and a comic book adaptation (copilot said so)
#and a novel adaptation (copilot said so)
#and a board game adaptation (copilot said so)
#and a card game adaptation (copilot said so)
