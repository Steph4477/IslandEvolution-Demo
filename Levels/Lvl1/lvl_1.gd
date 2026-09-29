extends Node2D                          

var cam
var player
var gs

@onready var world = $World
@onready var parallax = $World/Parallax
@onready var tilemap = $World/TileMap
@onready var trees = $World/Trees

@onready var sky_explorer = $World/Parallax/SkyLayer
@onready var sky_survivor = $World/Parallax/SkyLayerSurvivor
@onready var sky_king = $World/Parallax/SkyLayerKing

@onready var enemy_explorer: Node2D = $World/Difficulty/Enemies/EnemyExplorer
@onready var enemy_survivor: Node2D = $World/Difficulty/Enemies/EnemySurvivor
@onready var enemy_king: Node2D = $World/Difficulty/Enemies/EnemyKing

@onready var survivor_fx = $World/Difficulty/Smokes/SmokeSurvivorFX
@onready var king_fx = $World/Difficulty/FiresKing
func _ready():
	gs = get_node("/root/GameState")
	#gs.difficulty = "explorer" # test difficulté

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

	#if not gs.key_collected.is_connected(_on_key_collected):
		#gs.key_collected.connect(_on_key_collected)

	$Sound/Lvl1.play()

func setup_environment_difficulty():
	# Reset environnement
	sky_explorer.visible = false
	sky_survivor.visible = false
	sky_king.visible = false

	survivor_fx.visible = false
	king_fx.visible = false

	# Reset ennemis
	for enemy_group in [enemy_explorer, enemy_survivor, enemy_king]:
		enemy_group.visible = false
		enemy_group.process_mode = Node.PROCESS_MODE_DISABLED

	match gs.difficulty:
		
		"survivor":
			# === ENNEMIS ===
			enemy_survivor.visible = true
			enemy_survivor.process_mode = Node.PROCESS_MODE_INHERIT

			# === ENVIRONNEMENT ===
			world.modulate = Color("fec583ff")
			player.modulate = Color("9e8c63ff")
			player.get_node("Node2D/Sprite").modulate = Color(0.738, 0.738, 0.738, 1.0)
			gs.hud.set_difficulty_color(Color("d8b98fff"))
			sky_survivor.visible = true

			parallax.modulate = Color("#c89a72")
			tilemap.modulate = Color("#c89a72")
			trees.modulate = Color("#c89a72")

			survivor_fx.visible = true

			print("LVL1 ENEMIES : SURVIVOR")


		"king":
			# === ENNEMIS ===
			enemy_king.visible = true
			enemy_king.process_mode = Node.PROCESS_MODE_INHERIT

			# === ENVIRONNEMENT ===
			world.modulate = Color("313131")
			player.get_node("Node2D/Sprite").modulate = Color(0.4, 0.4, 0.4)
			gs.hud.set_difficulty_color(Color("8c7960ff"))
			sky_king.visible = true

			parallax.modulate = Color("#66738a")
			tilemap.modulate = Color("#66738a")
			trees.modulate = Color("#66738a")

			survivor_fx.visible = true
			king_fx.visible = true

			print("LVL1 ENEMIES : KING")


		"explorer":
			# === ENNEMIS ===
			enemy_explorer.visible = true
			enemy_explorer.process_mode = Node.PROCESS_MODE_INHERIT

			print("=== DEBUG ENEMY EXPLORER ===")
			print("EnemyExplorer visible : ", enemy_explorer.visible)
			print("Enemies visible : ", enemy_explorer.get_parent().visible)
			print("Nombre ennemis Explorer : ", enemy_explorer.get_child_count())

			for enemy in enemy_explorer.get_children():
				print(
					enemy.name,
					" | visible : ", enemy.visible if enemy is CanvasItem else "N/A",
					" | position : ", enemy.position if enemy is Node2D else "N/A"
				)

			# === ENVIRONNEMENT ===
			world.modulate = Color("ffff")
			player.modulate = Color("f4efe3ff")
			player.get_node("Node2D/Sprite").modulate = Color(0.881, 0.881, 0.881, 1.0)
			gs.hud.set_difficulty_color(Color.WHITE)
			sky_explorer.visible = true

			parallax.modulate = Color("#8ba499")
			tilemap.modulate = Color("#ffffff")
			trees.modulate = Color("#8ba499")

			print("LVL1 ENEMIES : EXPLORER")

func _on_all_seeds_collected():
	player.disable_controls()
	set_enemies_blocked(true)

	await focus_camera_on_node("Totem")
	await return_camera_to_player()

	await get_tree().create_timer(1.0).timeout

	player.enable_controls()
	set_enemies_blocked(false)
	


# === CINÉMATIQUE D’INTRO ===
func start_intro_sequence():
	player.disable_controls()

	set_enemies_blocked(true)

	cam.top_level = true
	cam.global_position = player.global_position

	if gs.hud and gs.lvl1_quest_revealed == false:
		gs.lvl1_quest_revealed = true
		await gs.hud.appear_lvl1_quest()
	
	await focus_camera_on_node("Totem")
	await focus_camera_on_node("Exit")
	await return_camera_to_player()

	player.enable_controls()
	set_enemies_blocked(false)


# === BLOQUAGE / DÉBLOQUAGE ENNEMIS ===
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


# === FOCUS CAMÉRA GÉNÉRIQUE ===
func focus_camera_on_node(node_name):
	var target = get_node_or_null(node_name)
	if not target:
		return

	var tween = create_tween()
	tween.tween_property(cam, "global_position", target.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(0.6).timeout


# === RETOUR CAMÉRA VERS MOKO ===
func return_camera_to_player():
	var tween = create_tween()
	tween.tween_property(cam, "global_position", player.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	cam.top_level = false
	cam.position = Vector2.ZERO


func _on_key_collected():
	await focus_camera_on_exit_and_fade()

	if gs.hud:
		await get_tree().create_timer(0.5).timeout
		await gs.hud.disappear_lvl1_quest()


# === FOCUS SORTIE + FADE + RETOUR MOKO ===
func focus_camera_on_exit_and_fade():
	player.disable_controls()
	set_enemies_blocked(true)

	cam.top_level = true
	cam.global_position = player.global_position

	var exit = get_node_or_null("Exit")
	if not exit:
		cam.top_level = false
		cam.position = Vector2.ZERO

		set_enemies_blocked(false)
		player.enable_controls()
		return

	var original_position = player.global_position

	var tween = create_tween()
	tween.tween_property(cam, "global_position", exit.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(1.0).timeout

	if exit.has_method("play_fade"):
		exit.play_fade()

	await get_tree().create_timer(1.5).timeout

	var back = create_tween()
	back.tween_property(cam, "global_position", original_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await back.finished

	cam.top_level = false
	cam.position = Vector2.ZERO

	player.enable_controls()
	set_enemies_blocked(false)
	
