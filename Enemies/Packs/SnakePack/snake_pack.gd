extends Node2D

@export var auto_spawn = true
@export var snake_distance_scene = preload("res://Enemies/Snake/SnakeDistance/snake_distance.tscn")
@export var snake_melee_scene = preload("res://Enemies/Snake/SnakeMelee/snake_melee.tscn")
@export var snake_heal_scene = preload("res://Enemies/Snake/SnakeHeal/snake_heal.tscn")

@onready var spawn_1 = $Spawn1
@onready var spawn_2 = $Spawn2
@onready var spawn_3 = $Spawn3

var gs 


func _ready():
	gs = get_node("/root/GameState")
	
	if auto_spawn:
		spawn_pack(gs.difficulty)

func spawn_pack(difficulty):
	match difficulty:
		"explorer":
			spawn_enemy(snake_melee_scene, spawn_1)
			spawn_enemy(snake_melee_scene, spawn_2)
			spawn_enemy(snake_melee_scene, spawn_3)

		"survivor":
			spawn_enemy(snake_distance_scene, spawn_1)
			spawn_enemy(snake_distance_scene, spawn_2)
			spawn_enemy(snake_melee_scene, spawn_3)

		"king":
			spawn_enemy(snake_distance_scene, spawn_1)
			spawn_enemy(snake_melee_scene, spawn_2)
			spawn_enemy(snake_heal_scene, spawn_3)


func spawn_enemy(scene, spawn_point):
	var enemy = scene.instantiate()
	add_child(enemy)

	enemy.global_position = spawn_point.global_position
	enemy.add_to_group("snake")
