extends Node2D
var speed = 30
var playIcon = preload("res://images/UI_images/play_button.png")
var pauseIcon = preload("res://images/UI_images/pause_button.png")
var fastIcon = preload("res://images/UI_images/fast_forward_button.png")
var pauseB = false
var speedB = 1
var length = 0
var pos = 0
var switch = false
var canswitch = true

func _ready():
	$Sprite2D.texture = load(Settings.textured[Settings.theme])
	$Label.text = "Mission Statement\n\n" + Mitre.blue_objective + "\n\n\n\nOPFOR Mission Statement\n\n" + Mitre.red_objective
	Music.scroll_music(1)
	length = $Label.get_combined_minimum_size().y


func _process(delta):
	var velocity = Vector2(0, -speed)
	$Label.position += velocity * delta
	pos = $Label.position.y
	if pos + length <= 0 && canswitch:
		switch = true
		canswitch = false
	if switch:
		switch = false
		next()
		

func _on_back_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/prompts_screen/starting_prompts.tscn")
	hide ()

func _on_skip_pressed():
	Music.mouse_click()
	next()

func next():
	TransitionScene.transition()
	await TransitionScene.on_transition_finished
	get_tree().change_scene_to_file("res://game_scenes/game_screen/game_screen.tscn")
	hide ()

func _on_pause_pressed():
	if pauseB == false:
		pauseB = true
		$pause.icon = playIcon
		speed = 0
		Music.scroll_music(0)
	else:
		if speedB == 1:
			pauseB = false
			$pause.icon = pauseIcon
			speed = 30
			Music.scroll_music(1)
		if speedB == 2:
			pauseB = false
			$pause.icon = pauseIcon
			speed = 60
			Music.scroll_music(1.5)

func _on_speed_button_pressed():
	if speedB == 1:
		$speed_button.icon = playIcon
		if pauseB == false:
			speed = 60
			speedB = 2
			Music.scroll_music(1.5)
		else:
			speedB = 2
	else:
		$speed_button.icon = fastIcon
		if pauseB == false:
			speed = 30
			speedB = 1
			Music.scroll_music(1)
		else:
			speedB = 1
