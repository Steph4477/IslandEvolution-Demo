extends Node
class_name GameBalance

# ============================================================================
#                           PLAYER - PV / SOINS
# ============================================================================
const PLAYER_MAX_PV = 500
const PLAYER_COOLDOWN_POTION = 10
const PLAYER_HEAL_AMOUNT = 50

# ============================================================================
#                           PLAYER - MOUVEMENT
# ============================================================================
const PLAYER_SPEED = 400
const PLAYER_JUMP_FORCE = -800
const PLAYER_GRAVITY = 1200
const PLAYER_CLIMB_SPEED = 100

# ============================================================================
#                          PLAYER - DÉGÂTS
# ============================================================================
const PLAYER_DAMAGE = {
	"clac": 20,
	"kick": 30,
	"headbutt": 35,
	"coco": 40,
	"bone": 45,
	"lance": 50,

	"clac_fire": 40,
	"kick_fire": 60,
	"coco_fire": 80

}

# ============================================================================
#                          PLAYER - SOINS
# ============================================================================
const PLAYER_HEAL = {
	"banana": 400,
}

# ============================================================================
#                     PLAYER - DÉGÂTS DE CHUTE
# ============================================================================
const PLAYER_FALL_DAMAGE_ENABLED = true
const PLAYER_FALL_SAFE_LIMIT = 1200
const PLAYER_FALL_SPEED_MAX = 1800
const PLAYER_FALL_DAMAGE_MAX = 200
const PLAYER_FALL_DAMAGE_MIN = 10


# ============================================================================
#                    PLAYER - TIRS / COMBAT
# ============================================================================
const PLAYER_RATE_OF_FIRE = 0.4
const PLAYER_HIT_LOCK_TIME = 0.2

# ============================================================================
#                    PLAYER - TIRS / COMBAT
# ============================================================================
const PLAYER_FIRE_BUFF_DURATION = 5

# ============================================================================
#                              ENEMIES
# ============================================================================
const ENEMY_HP = {
	"mosquito": 20,
	"snake": 200,
	"snake_melee": 300,
	"snake_distance": 250,
	"snake_heal": 200
}

const ENEMY_DAMAGE = {
	"mosquito": 20,
	"snake": 12,
	"snake_melee": 12,
	"snake_distance": 12,
	"snake_heal": 12
}

const ENEMY_PROJECTILE = {
	"gaz": 10
}

const ENEMY_SPEED = {
	"mosquito": 400,
	"snake": 450,
	"snake_melee": 450,
	"snake_distance": 450,
	"snake_heal": 450
}

const ENEMY_RANGE = {
	"mosquito": 1000,
	"snake": 1000,
	"snake_melee": 1000,
	"snake_distance": 1000,
	"snake_heal": 1000,
}

const ENEMY_MELEE_DISTANCE = {
	"snake": 200,
	"snake_melee": 200,
	"snake_distance": 200,
	"snake_heal": 200
}

const ENEMY_MIN_SHOOT_DISTANCE = {
	"snake": 200,
	"snake_distance": 200
}

const ENEMY_MAX_SHOOT_DISTANCE = {
	"snake": 360,
	"snake_distance": 300
}

const ENEMY_COOLDOWN = {
	"mosquito": 0.6,
	"snake": 3.0,
	"snake_melee": 0.5,
	"snake_distance": 0.8,
	"snake_heal": 3.0
}

const ENEMY_ANIMATION_ATTACK = {
	"snake_melee": "attack",
	"snake_distance": "attack",
	"snake_heal": "attack"
}

const ENEMY_ANIMATION_WALK = {
	"snake_melee": "walk",
	"snake_distance": "walk",
	"snake_heal": "walk"
}

const ENEMY_PROJECTILE_DAMAGE = {
	"snake_distance": 20
}

const ENEMY_FIRE_INTERVAL = {
	"snake_distance": 2.0,
	"snake_heal": 3.0
}

const ENEMY_PROJECTILE_SCENE = {
	"snake_distance": "res://Shoot/Enemies/Gaz/gaz.tscn",
	"snake_heal": "res://Enemies/Snake/SnakeHeal/heal_projectile/heal_projectile.tscn"
}

const ENEMY_ANIMATION_SHOOT = {
	"snake_distance": "attack",
	"snake_heal": "attack"
}

const ENEMY_CAN_JUMP = {
	"snake_heal": false
}
