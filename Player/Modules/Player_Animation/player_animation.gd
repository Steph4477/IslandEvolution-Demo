extends Node

var p
var is_interacting = false

func setup(player):
	p = player

func set_interact(value):
	is_interacting = value

func process():
	if p == null:
		return

	if p.is_dead:
		return

	if is_interacting:
		if p.anim.current_animation != "push":
			p.anim.play("push")
		return

	if p.is_kicking:
		if p.anim.current_animation != "kick":
			p.anim.play("kick")
		return

	if p.animation_locked:
		return

	if p.is_hit_locked:
		return

	if p.is_on_liana:
		return

	if p.is_hanging:
		return

	if p.climbing_anim != "" and p.velocity.y != 0:
		p.anim.play(p.climbing_anim)
		return

	if p.anim.current_animation == "hang":
		return

	if p.is_gazed:
		p.velocity.x = 0

		if not p.is_on_floor():
			p.velocity.y = 2000

		if p.anim.current_animation != "walk_gaz":
			p.anim.play("walk_gaz")
		return

	if p.is_jump_clacing:
		if p.anim.current_animation != "jump_clac":
			p.anim.play("jump_clac")
		return

	if p.is_on_floor():
		if abs(p.velocity.x) > 0.1:
			if p.is_gazed:
				p.anim.play("walk_gaz")
			else:
				p.anim.play("walk")
		else:
			if p.in_combat:
				if p.anim.current_animation != "combat_idle":
					p.anim.play("combat_idle")
			else:
				if p.anim.current_animation != "idle":
					p.anim.play("idle")
		return

	if p.velocity.y < 0:
		if p.jump_count > 1:
			p.anim.play("jump2_up")
		else:
			p.anim.play("jump_up")
	elif p.velocity.y > 0:
		if p.jump_count > 1:
			p.anim.play("jump2_down")
		else:
			p.anim.play("jump_down")
