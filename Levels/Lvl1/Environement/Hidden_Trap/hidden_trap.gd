extends Node2D

var gs


func _ready():
	gs = get_node("/root/GameState")

	# Attend que le Lvl1 ait appliqué la difficulté
	await get_tree().process_frame

	_apply_difficulty()


# ============================================================
# DIFFICULTÉ
# ============================================================
func _apply_difficulty():
	# Reset
	$LeafSprite.visible = true
	$HoleSprite.visible = false
	$Harrow.visible = false

	match gs.difficulty:
		"explorer":
			$LeafSprite.visible = true
			$HoleSprite.visible = false

		"survivor":
			$LeafSprite.visible = true
			$HoleSprite.visible = false

		"king":
			# Plus de feuilles en King :
			# le trou est directement visible
			$LeafSprite.visible = false
			$HoleSprite.visible = true


# ============================================================
# JOUEUR ENTRE DANS LE PIÈGE
# ============================================================
func _on_area_2d_body_entered(body):
	if body.name == "Player":
		$LeafSprite.visible = false
		$HoleSprite.visible = true
		$Harrow.visible = true
