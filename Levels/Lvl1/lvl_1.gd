extends Node2D


var cam

var player
var gs
var active_enemy_group = null
var birds_timer

@onready var world = $World
@onready var parallax = $World/Parallax
@onready var tilemap = $World/TileMap

@onready var sky_explorer = $World/Parallax/SkyLayer
@onready var sky_survivor = $World/Parallax/SkyLayerSurvivor
@onready var sky_king = $World/Parallax/SkyLayerKing

@onready var enemies_container = $World/Difficulty/Enemies
@onready var smoke = $World/Difficulty/Smoke
@onready var difficulty_items = $World/Difficulty/Items

# --- Son et bruitages ---
@onready var lvl1_explorer = $Sound/Lvl1_explorer
@onready var lvl1_survivor = $Sound/Lvl1_survivor
@onready var lvl1_king = $Sound/Lvl1_king
@onready var lvl1_birds_survivor = $Sound/Lvl1_birds_survivor
@onready var lvl1_drums_king = $Sound/Lvl1_drums_king

const ENEMY_SCENE_PATHS = {
	"explorer": "res://Levels/Lvl1/Difficulty/Enemies/enemy_explorer.tscn",
	"survivor": "res://Levels/Lvl1/Difficulty/Enemies/enemy_survivor.tscn",
	"king": "res://Levels/Lvl1/Difficulty/Enemies/enemy_king.tscn"
}


func _ready():
	gs = get_node("/root/GameState")
	#gs.difficulty = "king" # difficulté

	await get_tree().process_frame

	player = gs.player
	player.z_index = 60

	cam = player.get_node("Camera2D")

	setup_environment_difficulty()
	
	$World/Exit.rune_activated.connect(_on_rune_activated)

	cam.limit_right = 9550
	cam.limit_top = -300
	cam.limit_bottom = 1500

	if not gs.all_seeds_collected.is_connected(_on_all_seeds_collected):
		gs.all_seeds_collected.connect(_on_all_seeds_collected)

	if not gs.rune_collected.is_connected(_on_rune_collected):
		gs.rune_collected.connect(_on_rune_collected)
	
	if not gs.key_collected.is_connected(_on_key_collected):
		gs.key_collected.connect(_on_key_collected)

	# === CINÉMATIQUE D'INTRO ===
	await start_intro_sequence()


# ============================================================
# DIFFICULTÉ ET SONS
# ============================================================

func setup_environment_difficulty():
	sky_explorer.visible = false
	sky_survivor.visible = false
	sky_king.visible = false
	difficulty_items.visible = false
	difficulty_items.process_mode = Node.PROCESS_MODE_DISABLED

	lvl1_explorer.stop()
	lvl1_survivor.stop()
	lvl1_king.stop()
	lvl1_birds_survivor.stop()
	lvl1_drums_king.stop()

	var enemy_scene_path = ENEMY_SCENE_PATHS.get(gs.difficulty, "")

	if enemy_scene_path.is_empty():
		push_error("Difficulté inconnue : " + str(gs.difficulty))
		return

	var enemy_scene = load(enemy_scene_path)

	if enemy_scene == null:
		push_error("Impossible de charger : " + enemy_scene_path)
		return

	active_enemy_group = enemy_scene.instantiate()
	enemies_container.add_child(active_enemy_group)

	match gs.difficulty:

		"explorer":
			setup_enemy_group(
				active_enemy_group,
				false,
				Color("ffffffff")
			)

			set_world_color(Color("ffffffff"))
			gs.hud.set_difficulty_color(Color("ffffffff"))

			sky_explorer.visible = true
			smoke.visible = false

			lvl1_explorer.play()

		"survivor":
			var survivor_color = Color("f2a11fff")

			setup_enemy_group(
				active_enemy_group,
				true,
				survivor_color
			)

			set_world_color(survivor_color)
			gs.hud.set_difficulty_color(survivor_color)

			sky_survivor.visible = true
			smoke.visible = true

			lvl1_survivor.play()
			start_survivor_birds()

		"king":
			setup_enemy_group(
				active_enemy_group,
				true,
				Color("262c9bff")
			)

			set_world_color(Color("2b32aaff"))
			gs.hud.set_difficulty_color(Color("7a84abff"))

			sky_king.visible = true
			smoke.visible = false
			difficulty_items.visible = true
			difficulty_items.process_mode = Node.PROCESS_MODE_INHERIT

			lvl1_king.play()
			lvl1_drums_king.play()

	var total_enemies = gs.score_system.count_enemies_in_node(active_enemy_group)
	gs.score_system.set_enemies_total(total_enemies)


# ============================================================
# CONFIGURATION GÉNÉRIQUE DES ENNEMIS
# ============================================================

func setup_enemy_group(group, eyes_enabled, color):
	group.visible = true
	group.process_mode = Node.PROCESS_MODE_INHERIT

	for enemy in group.get_children():
		var rotator = enemy.get_node_or_null("Rotator")

		if rotator:
			for eye_name in ["Eye", "Eye2"]:
				var eye = rotator.get_node_or_null(eye_name)

				if eye:
					eye.visible = eyes_enabled

					var light = eye.get_node_or_null("Light")

					if light:
						light.enabled = eyes_enabled

			for sprite_name in ["Sprite", "Sprite2D", "AnimatedSprite2D"]:
				var sprite = rotator.get_node_or_null(sprite_name)

				if sprite:
					sprite.modulate = color

		var health_bar = enemy.get_node_or_null("HealthBar")

		if health_bar:
			health_bar.modulate = color


# ============================================================
# COULEUR GÉNÉRALE DU NIVEAU
# ============================================================

func set_world_color(color):
	player.get_node("Node2D/Sprite").modulate = color

	parallax.modulate = color
	tilemap.modulate = color

	for node in [
		$World/Totem,
		$World/Exit,
		$World/Traps,
		$World/Carnivores,
		$World/Items,
		$World/Lianas,
		$World/Toucan
	]:
		node.modulate = color


# ============================================================
# TOUTES LES GRAINES RÉCUPÉRÉES
# ============================================================

func _on_all_seeds_collected():
	player.disable_controls()
	set_enemies_blocked(true)

	parallax.pause_parallax()

	await focus_camera_on_node("World/Totem")
	await return_camera_to_player()

	parallax.resume_parallax()

	await get_tree().create_timer(1.0).timeout

	player.enable_controls()
	set_enemies_blocked(false)


# ============================================================
# RUNE RÉCUPÉRÉE
# ============================================================

func _on_rune_collected():
	player.disable_controls()
	set_enemies_blocked(true)

	parallax.pause_parallax()

	await focus_camera_on_node("World/Exit/RuneSymbols/CameraFocus")

	await get_tree().create_timer(2.0).timeout

	await return_camera_to_player()

	parallax.resume_parallax()

	player.enable_controls()
	set_enemies_blocked(false)


func _on_rune_activated():
	set_enemies_blocked(true)
	parallax.pause_parallax()

	await focus_camera_on_node(
		"World/Exit/RuneSymbols/CameraFocus"
	)

	var exit = $World/Exit

	await exit.play_temple_reaction()

	# ========================================================
	# KING : APPARITION DU BOSS
	# ========================================================

	var boss = null

	if gs.difficulty == "king":
		boss = get_boss_pyg()

		if boss:
			boss.process_mode = Node.PROCESS_MODE_INHERIT
			boss.global_position = exit.global_position

			await get_tree().create_timer(0.5).timeout

			await boss.start_boss_appear()

			await get_tree().create_timer(0.3).timeout

			exit.close_temple()

	# ========================================================
	# RETOUR CAMÉRA
	# ========================================================

	await get_tree().create_timer(1.0).timeout

	await return_camera_to_player()

	parallax.resume_parallax()
	set_enemies_blocked(false)

	# ========================================================
	# SUITE SELON DIFFICULTÉ
	# ========================================================

	match gs.difficulty:

		"explorer", "survivor":
			await exit._finish_level()

		"king":
			player.enable_controls()

			if boss:
				boss.activate_boss()


# ============================================================
# CLE RECUPEREE
# ============================================================

func _on_key_collected():
	if gs.difficulty != "king":
		return

	var exit = $World/Exit

	await exit.open_temple_with_fade()


# ============================================================
# CINÉMATIQUE D'INTRO
# ============================================================

func start_intro_sequence():
	player.disable_controls()
	set_enemies_blocked(true)

	parallax.pause_parallax()

	if gs.hud and gs.lvl1_quest_revealed == false:
		gs.lvl1_quest_revealed = true
		await gs.hud.appear_lvl1_quest()

	await focus_camera_on_node("World/Totem")
	await focus_camera_on_node("World/Exit/RuneSymbols/CameraFocus")

	await get_tree().create_timer(2.0).timeout

	await return_camera_to_player()

	parallax.resume_parallax()

	player.enable_controls()
	set_enemies_blocked(false)


# ============================================================
# BLOQUAGE / DÉBLOQUAGE ENNEMIS
# ============================================================

func set_enemies_blocked(blocked):
	if active_enemy_group == null:
		return

	var mode = Node.PROCESS_MODE_DISABLED if blocked else Node.PROCESS_MODE_INHERIT

	for enemy in active_enemy_group.get_children():
		enemy.process_mode = mode

		if blocked and enemy is CharacterBody2D:
			enemy.velocity = Vector2.ZERO


# ============================================================
# RÉCUPÉRATION DU BOSS PYGMÉE
# ============================================================

func get_boss_pyg():
	if gs.difficulty != "king":
		return null

	if active_enemy_group == null:
		return null

	for enemy in active_enemy_group.get_children():
		if enemy.name == "BossPyg":
			print("BOSS PYG TROUVÉ : ", enemy)
			return enemy

	print("ERREUR : BossPyg introuvable dans EnemyKing")
	print("ENFANTS DE ENEMYKING :")

	for enemy in active_enemy_group.get_children():
		print(" - ", enemy.name)

	return null


# ============================================================
# FOCUS CAMÉRA GÉNÉRIQUE
# ============================================================

func focus_camera_on_node(node_name):
	var target = get_node_or_null(node_name)

	if not target:
		return

	var target_position = target.global_position - player.global_position

	var tween = create_tween()

	tween.tween_property(
		cam,
		"position",
		target_position,
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
		"position",
		Vector2.ZERO,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	cam.position = Vector2.ZERO


# ============================================================
# FOCUS TEMPLE + RÉACTION + BOSS
# ============================================================

func focus_camera_on_exit_and_react():
	player.disable_controls()
	set_enemies_blocked(true)

	parallax.pause_parallax()

	var exit = get_node_or_null("World/Exit")

	if not exit:
		parallax.resume_parallax()
		set_enemies_blocked(false)
		player.enable_controls()
		return

	var boss = null

	await focus_camera_on_node("World/Exit/RuneSymbols/CameraFocus")

	await get_tree().create_timer(1.0).timeout

	if exit.has_method("play_temple_reaction"):
		await exit.play_temple_reaction()

	if gs.difficulty == "king":
		boss = get_boss_pyg()

		if boss:
			print("LANCEMENT APPARITION BOSS")

			boss.process_mode = Node.PROCESS_MODE_INHERIT
			boss.global_position = exit.global_position

			print("TEMPLE GLOBAL POSITION : ", exit.global_position)
			print("BOSS GLOBAL POSITION : ", boss.global_position)

			await get_tree().create_timer(0.5).timeout

			if boss.has_method("start_boss_appear"):
				print("APPEL start_boss_appear")
				await boss.start_boss_appear()
			else:
				push_error(
					"LVL1 : start_boss_appear() introuvable"
				)

			await get_tree().create_timer(0.3).timeout

			if exit.has_method("close_temple"):
				exit.close_temple()

		else:
			push_error(
				"LVL1 : BossPyg introuvable dans EnemyKing"
			)

	await get_tree().create_timer(1.0).timeout

	await return_camera_to_player()

	parallax.resume_parallax()

	set_enemies_blocked(false)
	player.enable_controls()

	if gs.difficulty == "king" and boss:
		if boss.has_method("activate_boss"):
			print("ACTIVATION COMBAT BOSS")
			boss.activate_boss()
		else:
			push_error(
				"LVL1 : activate_boss() introuvable"
			)


#####################################################################
#                  SON DES OISEAUX EN SURVIVOR
#####################################################################

func start_survivor_birds():
	lvl1_birds_survivor.play()

	birds_timer = Timer.new()
	birds_timer.one_shot = true
	add_child(birds_timer)

	birds_timer.timeout.connect(play_survivor_birds)

	birds_timer.start(randf_range(20.0, 35.0))


func play_survivor_birds():
	if gs.difficulty != "survivor":
		return

	lvl1_birds_survivor.play()

	birds_timer.start(randf_range(20.0, 35.0))
