extends Node2D

# Player data
var player = {
	"pos": Vector2(100, 400),
	"vel": Vector2.ZERO,
	"on_floor": false,
	"hearts": 3,
	"apples": 0,
	"powers": [],
	"has_won": false
}

const GRAVITY = 1100
const MOVE_SPEED = 210
const JUMP_SPEED = -420
const FART_STRENGTH = -600

var apples_pos = [Vector2(300, 400), Vector2(650, 300), Vector2(500, 375)]
var apples_taken = [false, false, false]
var enemies = [
	{ "pos": Vector2(600, 400), "dir": 1, "range": 120.0, "startx": 600 }
]
var ground_y = 450 # Change for your ground level
var shop_open = false
var boss_active = false

var msg = ""
var show_game_over = false
var show_menu = true
var show_shop = false

onready var camera = $Camera2D

# Platform sample
var platforms = [
	Rect2(50, 450, 800, 25),	# Ground
	Rect2(285, 410, 110, 15),
	Rect2(630, 281, 120, 15),
	Rect2(470, 356, 130, 15)
]

# Shop
var shop_powers = {
	"Fart Jump": { "cost": 5, "desc": "Press X to fart jump!" },
	"Brutal Bite": { "cost": 7, "desc": "Bite enemies in front!" },
	"Capybara Ray": { "cost": 10, "desc": "Powerful ranged attack." }
}

func _ready():
	set_process(true)
	camera.position = player.pos

func _input(event):
	if show_game_over and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
	if show_menu and event.is_action_pressed("ui_accept"):
		show_menu = false
	if not show_menu and event is InputEventKey and event.pressed:
		if event.scancode == KEY_S:
			show_shop = not show_shop
			msg = ""
		if show_shop and event.as_text() in ["1","2","3"]:
			var idx = int(event.as_text())-1
			var pwr = shop_powers.keys()[idx]
			if pwr in player.powers:
				msg = "Already owned!"
			elif player.apples >= shop_powers[pwr]["cost"]:
				player.apples -= shop_powers[pwr]["cost"]
				player.powers.append(pwr)
				msg = "Bought: %s" % pwr
			else:
				msg = "Not enough apples!"

func _physics_process(delta):
	if show_menu or show_shop or show_game_over:
		return
	# ----- PLAYER PHYSICS/MOVEMENT -----
	var h = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	player.vel.x = h * MOVE_SPEED
	player.vel.y += GRAVITY * delta
	
	# Check platforms collision
	player.on_floor = false
	for plat in platforms:
		if (player.pos.y + 40) >= plat.position.y and (player.pos.y + 40 + player.vel.y * delta) >= plat.position.y and player.pos.x + 16 > plat.position.x and player.pos.x - 16 < plat.position.x + plat.size.x and player.vel.y > 0:
			player.pos.y = plat.position.y-40
			player.vel.y = 0
			player.on_floor = true
	
	# Jump
	if player.on_floor and Input.is_action_just_pressed("ui_jump"):
		player.vel.y = JUMP_SPEED
	# Fart Jump Power (X key, if owned)
	if "Fart Jump" in player.powers and Input.is_key_pressed(KEY_X) and not player.on_floor:
		player.vel.y = FART_STRENGTH
	
	player.pos += player.vel * delta
	
	# Level boundary
	player.pos.x = clamp(player.pos.x, 0, 850)
	player.pos.y = clamp(player.pos.y, 0, 480)
	
	# ---- APPLE PICKUP ----
	for i in apples_pos.size():
		if not apples_taken[i] and player.pos.distance_to(apples_pos[i]) < 32:
			apples_taken[i] = true
			player.apples += 1
	
	# ---- ENEMY LOGIC ----
	for enemy in enemies:
		enemy["pos"].x += enemy["dir"] * 80 * delta
		if abs(enemy["pos"].x - enemy["startx"]) > enemy["range"]:
			enemy["dir"] *= -1
		# Hit test
		if player.pos.distance_to(enemy["pos"]) < 36:
			player.hearts -= 1
			player.pos = Vector2(100, 400)
			if player.hearts <= 0:
				show_game_over = true
	
	# ---- CAMERA FOLLOW ----
	camera.position = player.pos

	# ---- WIN CONDITION ----
	if player.apples == apples_pos.size() and not player.has_won:
		msg = "All apples! Go home (right edge)."
	if player.apples == apples_pos.size() and player.pos.x > 850:
		player.has_won = true
		msg = "Stage complete!"

func _draw():
	# Draw platforms
	for plat in platforms:
		draw_rect(plat, Color(0.38,0.7,0.24), false, 2)
	
	# Draw apples
	for i in apples_pos.size():
		if not apples_taken[i]:
			draw_circle(apples_pos[i], 12, Color(1,0.2,0))
			draw_circle(apples_pos[i], 6, Color(0.9,0.6,0.2))
	# Draw enemies
	for enemy in enemies:
		draw_rect(Rect2(enemy["pos"].x-16, enemy["pos"].y-32, 32, 32), Color(0.7,0.1,0.05))
	# Draw player (Capybara rectangle)
	draw_rect(Rect2(player.pos.x-16, player.pos.y-32, 32, 40), Color(0.87, 0.72, 0.49))
	# Hearts
	for i in range(player.hearts):
		draw_circle(Vector2(32 + i*28, 32), 12, Color(1,0.3,0.3))
	# Apples
	draw_string(get_font("font", "Label"), Vector2(28, 64), "🍎 x %d" % player.apples, Color.BLACK)
	# HUD/Msg
	draw_string(get_font("font", "Label"), Vector2(420, 32), msg, Color(0.2,0.2,0.7))
	
	# Shop
	if show_shop:
		draw_rect(Rect2(190, 50, 470, 190), Color(0.95,0.95,1,0.89), true)
		var y = 90
		draw_string(get_font("font", "Label"), Vector2(220, 80), "SHOP: Spend your apples (press S to close)", Color(0.2,0.2,0.7))
		var idx = 1
		for k in shop_powers.keys():
			var owned = " (OWNED)" if (k in player.powers) else ""
			draw_string(get_font("font", "Label"), Vector2(220, y), "%d) %s - %d apples%s. %s" % [idx, k, shop_powers[k]["cost"], owned, shop_powers[k]["desc"]], Color(0.15,0.3,0.3))
			y += 32
			idx += 1
		draw_string(get_font("font", "Label"), Vector2(220,210), msg, Color(0.2,0.2,0.7))
	if show_menu:
		draw_rect(Rect2(190, 140, 430, 120), Color(0.97,0.97,0.97,0.95), true)
		draw_string(get_font("font", "Label"), Vector2(220, 170), "CAPYBARA HERCULES PLATFORMER", Color(0,0,0.5))
		draw_string(get_font("font", "Label"), Vector2(220, 210), "Press [Enter] to start", Color(0.10,0.10,0.55))
	if show_game_over:
		draw_rect(Rect2(190, 160, 430, 80), Color(1,0.9,0.95,0.96), true)
		draw_string(get_font("font", "Label"), Vector2(310, 200), "GAME OVER! Press Enter", Color(1,0,0))

func _process(_delta):
	update() # Redraw every frame