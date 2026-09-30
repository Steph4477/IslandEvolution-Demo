extends Area2D

var collected = false

func _ready():
	var gs = get_node("/root/GameState")

	if gs.wood_collected:
		queue_free()

func _on_body_entered(body):
	if collected:
		return

	if body.is_in_group("Player"):
		collected = true
		body.collect_items.collect_wood()

		queue_free()
