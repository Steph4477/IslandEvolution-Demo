extends CharacterBody2D


# ============================================================================
#                                  RÉGLAGES
# ============================================================================

@export var speed = 800
@export var damage = 0
@export var arc_force = -150
@export var gravity_force = 1200


# ============================================================================
#                                  ÉTAT
# ============================================================================

var direction = Vector2.RIGHT
var is_planted = false


# ============================================================================
#                                  READY
# ============================================================================

func _ready():
	$Area2D/CollisionPolygon2D.disabled = true


# ============================================================================
#                                  PHYSICS
# ============================================================================

func _physics_process(delta):
	if is_planted:
		return

	velocity.y += gravity_force * delta
	rotation = velocity.angle()

	var collision = move_and_collide(velocity * delta)

	if collision:
		plant_spear()


# ============================================================================
#                                  START
# ============================================================================

func start(pos, dir, projectile_damage):
	damage = projectile_damage
	global_position = pos

	if typeof(dir) == TYPE_VECTOR2:
		direction = dir.normalized()
	else:
		if dir < 0:
			direction = Vector2.LEFT
		else:
			direction = Vector2.RIGHT

	$Area2D/CollisionPolygon2D.disabled = false

	var player = get_tree().get_first_node_in_group("Player")

	if player == null:
		start_simple_throw()
		return

	var target_pos = player.global_position

	if player.has_node("TurnAxis"):
		target_pos = player.get_node("TurnAxis").global_position

	if direction.x > 0:
		target_pos.x -= 35
	else:
		target_pos.x += 35

	var target_vector = target_pos - global_position

	var horizontal_distance = abs(target_vector.x)

	if horizontal_distance < 1:
		horizontal_distance = 1

	var horizontal_direction = sign(target_vector.x)

	if horizontal_direction == 0:
		horizontal_direction = sign(direction.x)

	if horizontal_direction == 0:
		horizontal_direction = 1

	var travel_time = horizontal_distance / speed

	var vertical_speed = (
		target_vector.y
		- 0.5 * gravity_force * travel_time * travel_time
	) / travel_time

	velocity = Vector2(
		horizontal_direction * speed,
		vertical_speed
	)

	if horizontal_direction < 0:
		$SpearSprite.flip_v = true
	else:
		$SpearSprite.flip_v = false


# ============================================================================
#                           TIR DE SECOURS
# ============================================================================

func start_simple_throw():
	var horizontal_direction = sign(direction.x)

	if horizontal_direction == 0:
		horizontal_direction = 1

	velocity = Vector2(
		horizontal_direction * speed,
		arc_force
	)

	if horizontal_direction < 0:
		$SpearSprite.flip_v = true
	else:
		$SpearSprite.flip_v = false


# ============================================================================
#                              PLANTER LA LANCE
# ============================================================================

func plant_spear():
	if is_planted:
		return

	is_planted = true
	velocity = Vector2.ZERO

	set_physics_process(false)

	$Area2D/CollisionPolygon2D.disabled = true

	await get_tree().create_timer(1).timeout

	queue_free()


# ============================================================================
#                              TOUCHER MOKO
# ============================================================================

func _on_area_2d_body_entered(body):
	if is_planted:
		return

	if not body.is_in_group("Player"):
		return

	body.damage_mod.on_hit(damage)

	queue_free()
