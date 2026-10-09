extends Node2D


var cam
var player
var gs


@onready var world = $World
@onready var parallax = $World/Parallax
@onready var tilemap = $World/TileMap

@onready var sky_explorer = $World/Parallax/SkyLayer
@onready var sky_survivor = $World/Parallax/SkyLayerSurvivor
@onready var sky_king = $World/Parallax/SkyLayerKing

@onready var enemy_explorer = $World/Difficulty/Enemies/EnemyExplorer
@onready var enemy_survivor = $World/Difficulty/Enemies/EnemySurvivor
@onready var enemy_king = $World/Difficulty/Enemies/EnemyKing

@onready var survivor_fx = $World/Difficulty/Smokes/SmokeSurvivorFX


func _ready():
	gs = get_node("/root/GameState")
	gs.difficulty = "survivor" #difficulté

	await get_tree().process_frame

	player = gs.player
	player.z_index = 60

	cam = player.get_node("Camera2D")

	setup_environment_difficulty()

	cam.limit_right = 9500
	cam.limit_top = -300
	cam.limit_bottom = 1500

	if not gs.all_seeds_collected.is_connected(_on_all_seeds_collected):
		gs.all_seeds_collected.connect(_on_all_seeds_collected)

	if not gs.key_collected.is_connected(_on_key_collected):
		gs.key_collected.connect(_on_key_collected)

	$Sound/Lvl1.play()

	# === CINÉMATIQUE D'INTRO ===
	await start_intro_sequence()


# ============================================================
# DIFFICULTÉ
# ============================================================

func setup_environment_difficulty():
	# Reset environnement
	sky_explorer.visible = false
	sky_survivor.visible = false
	sky_king.visible = false

	survivor_fx.visible = false

	# Reset ennemis
	for enemy_group in [enemy_explorer, enemy_survivor, enemy_king]:
		enemy_group.visible = false
		enemy_group.process_mode = Node.PROCESS_MODE_DISABLED

	match gs.difficulty:

		"explorer":
			setup_enemy_group(
				enemy_explorer,
				false,
				Color("ffffffff")
			)

			set_world_color(Color("ffffffff"))
			gs.hud.set_difficulty_color(Color("ffffffff"))

			sky_explorer.visible = true

			print("LVL1 ENEMIES : EXPLORER")


		"survivor":
			var survivor_color = Color("f2a11fff")

			setup_enemy_group(
				enemy_survivor,
				true,
				survivor_color
			)

			set_world_color(survivor_color)
			gs.hud.set_difficulty_color(survivor_color)

			sky_survivor.visible = true
			survivor_fx.visible = true

			print("LVL1 ENEMIES : SURVIVOR")


		"king":
			setup_enemy_group(
				enemy_king,
				true,
				Color("262c9bff")
			)

			set_world_color(Color("2b32aaff"))
			gs.hud.set_difficulty_color(Color("7a84abff"))

			sky_king.visible = true

			print("LVL1 ENEMIES : KING")


# ============================================================
# CONFIGURATION GÉNÉRIQUE DES ENNEMIS
# ============================================================

func setup_enemy_group(group: Node, eyes_enabled: bool, color: Color):
	group.visible = true
	group.process_mode = Node.PROCESS_MODE_INHERIT

	for enemy in group.get_children():
		var rotator = enemy.get_node_or_null("Rotator")

		if rotator:
			# === YEUX ===
			for eye_name in ["Eye", "Eye2"]:
				var eye = rotator.get_node_or_null(eye_name)

				if eye:
					eye.visible = eyes_enabled

					var light = eye.get_node_or_null("Light")

					if light:
						light.enabled = eyes_enabled

			# === SPRITES ===
			for sprite_name in ["Sprite", "Sprite2D", "AnimatedSprite2D"]:
				var sprite = rotator.get_node_or_null(sprite_name)

				if sprite:
					sprite.modulate = color

		# === BARRE DE VIE ===
		var health_bar = enemy.get_node_or_null("HealthBar")

		if health_bar:
			health_bar.modulate = color


# ============================================================
# COULEUR GÉNÉRALE DU NIVEAU
# ============================================================

func set_world_color(color: Color):
	player.get_node("Node2D/Sprite").modulate = color

	parallax.modulate = color
	tilemap.modulate = color

	for node in [
		$World/Totem,
		$World/Exit,
		$World/Traps,
		$World/Carnivores,
		$World/Items,
		$World/Trees,
		$World/Toucan
	]:
		node.modulate = color


# ============================================================
# TOUTES LES GRAINES RÉCUPÉRÉES
# ============================================================

func _on_all_seeds_collected():
	player.disable_controls()
	set_enemies_blocked(true)

	await focus_camera_on_node("World/Totem")
	await return_camera_to_player()

	await get_tree().create_timer(1.0).timeout

	player.enable_controls()
	set_enemies_blocked(false)


# ============================================================
# CINÉMATIQUE D’INTRO
# ============================================================

func start_intro_sequence():
	player.disable_controls()

	set_enemies_blocked(true)

	cam.top_level = true
	cam.global_position = player.global_position

	if gs.hud and gs.lvl1_quest_revealed == false:
		gs.lvl1_quest_revealed = true
		await gs.hud.appear_lvl1_quest()

	await focus_camera_on_node("World/Totem")
	await focus_camera_on_node("World/Exit")
	await return_camera_to_player()

	player.enable_controls()
	set_enemies_blocked(false)


# ============================================================
# BLOQUAGE / DÉBLOQUAGE ENNEMIS
# ============================================================

func set_enemies_blocked(blocked: bool):
	var active_enemies: Node2D

	match gs.difficulty:
		"explorer":
			active_enemies = enemy_explorer

		"survivor":
			active_enemies = enemy_survivor

		"king":
			active_enemies = enemy_king

		_:
			return

	var mode = Node.PROCESS_MODE_DISABLED if blocked else Node.PROCESS_MODE_INHERIT

	for enemy in active_enemies.get_children():
		enemy.process_mode = mode

		if blocked and enemy is CharacterBody2D:
			enemy.velocity = Vector2.ZERO


# ============================================================
# FOCUS CAMÉRA GÉNÉRIQUE
# ============================================================

func focus_camera_on_node(node_name):
	var target = get_node_or_null(node_name)

	if not target:
		return

	var tween = create_tween()

	tween.tween_property(
		cam,
		"global_position",
		target.global_position,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	await get_tree().create_timer(0.6).timeout


# ============================================================
# RETOUR CAMÉRA VERS MOKO
# ============================================================

func return_camera_to_player():
	var tween = create_tween()

	tween.tween_property(
		cam,
		"global_position",
		player.global_position,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	cam.top_level = false
	cam.position = Vector2.ZERO


# ============================================================
# CLÉ RÉCUPÉRÉE
# ============================================================

func _on_key_collected():
	await focus_camera_on_exit_and_fade()

	if gs.hud:
		await get_tree().create_timer(0.5).timeout
		await gs.hud.disappear_lvl1_quest()


# ============================================================
# FOCUS SORTIE + FADE + RETOUR MOKO
# ============================================================

func focus_camera_on_exit_and_fade():
	player.disable_controls()
	set_enemies_blocked(true)

	cam.top_level = true
	cam.global_position = player.global_position

	# === FOCUS TOTEM ===
	await focus_camera_on_node("World/Totem")

	# === FOCUS EXIT ===
	var exit = get_node_or_null("World/Exit")

	if not exit:
		cam.top_level = false
		cam.position = Vector2.ZERO

		set_enemies_blocked(false)
		player.enable_controls()

		return

	var original_position = player.global_position

	var tween = create_tween()

	tween.tween_property(
		cam,
		"global_position",
		exit.global_position,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	await get_tree().create_timer(1.0).timeout

	if exit.has_method("play_fade"):
		exit.play_fade()

	await get_tree().create_timer(1.5).timeout

	var back = create_tween()

	back.tween_property(
		cam,
		"global_position",
		original_position,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await back.finished

	cam.top_level = false
	cam.position = Vector2.ZERO

	player.enable_controls()
	set_enemies_blocked(false)
