extends RigidBody2D

@export_category("Explosion Knockback")
@export_range(0.0, 1000.0, 10.0) var fire_knockback_x = 300.0
@export_range(0.0, 1000.0, 10.0) var fire_knockback_y = 450.0

var damage = 0
var direction = 1
var has_collided = false

const FIRE_IMPACT_SCENE = preload("res://Effects/Fire/Fire_impact/fire_impact.tscn")


func start(pos, dir, projectile_damage):
	damage = projectile_damage
	global_position = pos

	if typeof(dir) == TYPE_VECTOR2:
		direction = -1 if dir.x < 0 else 1
	else:
		direction = dir

	linear_velocity = Vector2(1000 * direction, 0)

	$Area2D/CollisionShape2D.disabled = true

	call_deferred("_enable_hitbox")
	call_deferred("_self_destruct")


func _enable_hitbox():
	await get_tree().process_frame

	if is_instance_valid(self):
		$Area2D/CollisionShape2D.disabled = false


func _self_destruct():
	await get_tree().create_timer(3.0).timeout

	if is_instance_valid(self):
		queue_free()


# ============================================================================
#                              IMPACT ENNEMI
# ============================================================================

func _on_area_2d_body_entered(body):
	if has_collided:
		return

	if not body.is_in_group("Enemies"):
		return

	if body.has_method("on_hit"):
		body.on_hit(damage)

	_explode()


# ============================================================================
#                              IMPACT SOL
# ============================================================================

func _on_body_entered(body):
	if has_collided:
		return

	# Les ennemis sont gérés par l'Area2D.
	if body.is_in_group("Enemies"):
		return

	_explode()


# ============================================================================
#                              EXPLOSION
# ============================================================================

func _explode():
	if has_collided:
		return

	has_collided = true

	$Area2D/CollisionShape2D.set_deferred("disabled", true)

	# Screenshake
	var camera = get_viewport().get_camera_2d()

	if camera and camera.has_node("ShakeAnimation"):
		camera.get_node("ShakeAnimation").play("coco_fire_shake")

	# FX d'impact
	var impact = FIRE_IMPACT_SCENE.instantiate()
	get_tree().current_scene.add_child(impact)

	var impact_offset_x = -8 if linear_velocity.x < 0 else 8
	impact.global_position = global_position + Vector2(impact_offset_x, -6)

	impact.play_impact()

	# Projection Player + Enemies
	_apply_radial_knockback()

	queue_free()


# ============================================================================
#                         KNOCKBACK EXPLOSION
# ============================================================================

func _apply_radial_knockback():
	for body in $KnockbackArea.get_overlapping_bodies():
		if not body.is_in_group("Player") and not body.is_in_group("Enemies"):
			continue

		if not body.has_method("apply_explosion_knockback"):
			continue

		var x_direction = sign(body.global_position.x - global_position.x)

		if x_direction == 0:
			x_direction = direction

		var knockback = Vector2(
			x_direction * fire_knockback_x,
			-fire_knockback_y
		)

		body.apply_explosion_knockback(knockback)
