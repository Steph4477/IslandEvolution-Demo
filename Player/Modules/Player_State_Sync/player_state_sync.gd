extends Node

var p

func setup(player):
	p = player

func apply_from_gamestate():
	p.game_state = p.get_node_or_null("/root/GameState")
	if not p.game_state:
		return

	p.game_state.set_player(p)

	p.banane_count = p.game_state.banane_count

	p.coco_count = p.game_state.coco_count

	# Aligné sur la logique GameState
	p.seed_count = p.game_state.collected_seeds

	p.can_fire_coco = p.game_state.can_fire_coco

	p.fire_buff_active = false

	# Recrée les listes après respawn / reload
	p.heal_potions.clear()
	for i in range(p.banane_count):
		p.heal_potions.append(p.game_state.heal_amount)

	p.max_jump_count = 1
	if p.game_state.double_jump_unlocked:
		p.max_jump_count = 2
