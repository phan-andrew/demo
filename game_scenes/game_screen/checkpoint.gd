extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Settings.theme == 0:
		$weed.show()
		$loon.hide()
		$tree.hide()
	if Settings.theme == 1:
		$weed.hide()
		$loon.show()
		$tree.hide()
	if Settings.theme == 2:
		$weed.hide()
		$loon.hide()
		$tree.show()
