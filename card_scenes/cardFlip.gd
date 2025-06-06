extends Node2D

var flipped = false
var inPlay = false
var dPics = []
var aBack = "res://images/card_images/general/redcard-back.png"
var dBack = "res://images/card_images/general/bluecard-back.png"
var cost=["res://images/card_images/general/1 Dollar.png", "res://images/card_images/general/2 Dollars.png", "res://images/card_images/general/3 Dollars.png", "res://images/card_images/general/4 Dollars.png", "res://images/card_images/general/5 Dollars.png", "res://images/card_images/general/6 Dollars.png", "res://images/card_images/general/7 Dollars.png", "res://images/card_images/general/8 Dollars.png", "res://images/card_images/general/9 Dollars.png", "res://images/card_images/general/10 Dollars.png"]
var maturity=["res://images/card_images/general/1 Star.png", "res://images/card_images/general/2 Stars.png", "res://images/card_images/general/3 Stars.png", "res://images/card_images/general/4 Stars.png", "res://images/card_images/general/5 Stars.png"]
var cardType
var original_pos_x
var original_pos_y
var expand_pos_x
var expand_pos_y
var expanded = false
var reset_dropdown = false
var card_index = -1
var time_value = 0
var cost_value = 1
var maturity_level = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	$card.z_index = -1
	$card/card_back.z_index = 0
	original_pos_y = position.y
	original_pos_x  = position.x
	disable_buttons(true)
	$card/sliders.hide()
	$card/Clock.hide()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if inPlay:
		if cardType == "a":
			$card/Dollar.texture = load(cost[$card/sliders/cost_slider.value-1])
			cost_value = $card/sliders/cost_slider.value
			$card/Time.text = str($card/sliders/time_slider.value) + " min"
			if $card/sliders/time_slider.value > 90:
				$card/Clock.play("full")
			elif $card/sliders/time_slider.value > 60:
				$card/Clock.play("0.75")
			elif $card/sliders/time_slider.value > 30:
				$card/Clock.play("0.25")
			else:
				$card/Clock.play("none")
			time_value = $card/sliders/time_slider.value
		if cardType == "d":
			$card/Clock.play("nothing")
			$card/Maturity.texture = load(maturity[$card/sliders/maturity_slider.value-1])
			maturity_level = $card/sliders/maturity_slider.value
			
			
	
func setCard(index):
	if cardType == "a":
		$card.texture = load(Mitre.attack_dict[index+1][4])
		$card/sliders/maturity_slider.hide()
	if cardType == "d":
		$card.texture = load(Mitre.defend_dict[int(index)+1][4])
		$card/sliders/cost_slider.hide()
		$card/sliders/time_slider.hide()
		$card/Clock.hide()
	card_index = int(index)

func play():
	$AnimationPlayer.play("start_flip")
	inPlay = true
	Music.flip_card()
	disable_buttons(false)

func _on_expand_button_pressed():
	if !expanded:
		if cardType == "a":
			expand_pos_x = 300
			expand_pos_y = 300
		if cardType == "d":
			expand_pos_x = 850
			expand_pos_y = 300
		position.x = expand_pos_x
		position.y = expand_pos_y
		scale.x *= 2
		scale.y *= 2
		z_index = 5
		$expand_button.icon = load("res://images/UI_images/shrink_button.png")
		$expand_button.position.x -= 50
		$flip_button.position.x -= 150
		expanded = true
		$close_button.hide()
	else:
		scale.x /= 2
		scale.y /= 2
		position.x = original_pos_x
		position.y = original_pos_y
		z_index = 1
		$expand_button.icon = load("res://images/UI_images/expand_button.png")
		$expand_button.position.x += 50
		$flip_button.position.x += 150
		expanded = false
		$close_button.show()

func make_small_again():
	scale.x /= 2
	scale.y /= 2
	position.x = original_pos_x
	position.y = original_pos_y
	z_index = 1
	$expand_button.icon = load("res://images/UI_images/expand_button.png")
	$expand_button.position.x += 50
	$flip_button.position.x += 150
	expanded = false
	$close_button.show()

func _on_close_button_pressed():
	reset_card()
	reset_dropdown = true

func reset_card():
	inPlay = false
	disable_buttons(true)
	if cardType == "a":
		$card/card_back.frame = 4
	if cardType == "d":
		$card/card_back.frame = 3
	$AnimationPlayer.play("end_flip")
	time_value = 0
	card_index = -1
	Music.flip_card()


func disable_buttons(state):
	$close_button.disabled = state
	$expand_button.disabled = state
	$flip_button.disabled = state
	
func disable_expand(state):
	$expand_button.disabled = state

func disable_close(state):
	$close_button.disabled = state

func disable_flip(state):
	$flip_button.disabled = state
	
func setText(index):
	if cardType=="a":
		$card/definition.text=(Mitre.attack_dict[index+1][3])
		$card/definition.hide()
	if cardType=="d":
		$card/definition.text=(Mitre.defend_dict[int(index)+1][3])
		$card/definition.hide()

func setCost(Cost):
	if cardType=="a":
		$card/sliders/cost_slider.value = Cost

func setMaturity(Maturity):
	if cardType=="d":
		$card/sliders/maturity_slider.value = Maturity
		

		
func setTimeValue(value):
	if cardType == "a":
		$card/sliders/time_slider.value = value

func getTimeValue():
	return time_value

func getCostValue():
	return cost_value

func getMaturityValue():
	return maturity_level

func getString():
	if cardType == "a":
		var printable = Mitre.attack_dict[card_index+1][2] + ": $" + str(cost_value) + " " + str(time_value) + " minutes"
		return printable
	if cardType == "d":
		var printable = Mitre.defend_dict[card_index+1][2] + ": " + str(maturity_level) + " stars"
		return printable


func _on_flip_button_pressed():
	if flipped:
		$AnimationPlayer.play_backwards("card_flip")
		flipped = false
		Music.flip_card()
	else :
		if cardType == "a":
			$card/card_back.frame = 1
		if cardType == "d":
			$card/card_back.frame = 2
		$AnimationPlayer.play("card_flip")
		#while $AnimationPlayer.current_animation_position < 0.2:
		flipped = true
		Music.flip_card()
	
