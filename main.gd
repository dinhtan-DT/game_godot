extends Node2D

@onready var player = $Player_A
@onready var enemy = $Enemy_B

const PLAYER_SPEED = 300.0
const ENEMY_SPEED = 180.0
const Projectile = preload("res://projectile.gd")
const CharacterArt = preload("res://character_art.gd")
const AUTO_FIRE_INTERVAL = 0.65
const INITIAL_ENEMY_COUNT = 2
const MAX_ENEMIES = 5
const ENEMY_SPAWN_INTERVAL = 2.5
const ENEMY_HIT_POINTS = 3
const PROJECTILE_HIT_RADIUS = 52.0
# Vùng va chạm phủ hết hai drone (gồm cả cánh), để B chạm A là thua ngay.
const PLAYER_HIT_RADIUS = 92.0

var held_keys: Dictionary = {}
var fire_cooldown := 0.0
var enemy_spawn_cooldown := ENEMY_SPAWN_INTERVAL
var game_over := false
var enemy_template: CharacterBody2D


func _ready():
	var size = get_viewport_rect().size
	queue_redraw()

	# Thay icon mặc định bằng hai drone có ngoại hình riêng.
	$Player_A/Sprite_A.visible = false
	$Enemy_B/Sprite_B.visible = false
	add_character_art(player, Color("29b6f6"), Color("d8f6ff"), false)
	add_character_art(enemy, Color("ef476f"), Color("ffd166"), true)
	enemy_template = enemy.duplicate() as CharacterBody2D

	# A ở giữa biên trái
	player.position = Vector2(60, size.y / 2)

	# B ở giữa biên phải
	setup_enemy(enemy, Vector2(size.x - 60, size.y / 2))

	# Chỉ khởi tạo ít B; phần còn lại sẽ sinh dần trong lúc chơi.
	for index in range(INITIAL_ENEMY_COUNT - 1):
		spawn_enemy(size)

func _physics_process(delta):
	if game_over:
		return

	var size = get_viewport_rect().size
	spawn_enemies_over_time(delta, size)

	# C tự động bắn về phía vị trí con trỏ chuột, không cần click.
	fire_cooldown -= delta
	if fire_cooldown <= 0.0:
		fire_projectile(get_viewport().get_mouse_position())
		fire_cooldown = AUTO_FIRE_INTERVAL

	# ==================================
	# A - DI CHUYỂN BẰNG BÀN PHÍM
	# ==================================
	var direction = Vector2.ZERO

	if held_keys.get(KEY_A, false) or held_keys.get(KEY_LEFT, false):
		direction.x -= 1
	if held_keys.get(KEY_D, false) or held_keys.get(KEY_RIGHT, false):
		direction.x += 1
	if held_keys.get(KEY_W, false) or held_keys.get(KEY_UP, false):
		direction.y -= 1
	if held_keys.get(KEY_S, false) or held_keys.get(KEY_DOWN, false):
		direction.y += 1

	# CharacterBody2D phải di chuyển bằng velocity + move_and_slide() để
	# hoạt động ổn định với vòng lặp vật lý và va chạm.
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		player.velocity = direction * PLAYER_SPEED
	else:
		player.velocity = Vector2.ZERO

	player.move_and_slide()

	# ==================================
	# GIỮ A TRONG MÀN HÌNH
	# ==================================
	player.position.x = clamp(player.position.x, 60.0, size.x - 60.0)
	player.position.y = clamp(player.position.y, 60.0, size.y - 60.0)

	move_enemies(delta, size)
	check_projectile_hits()
	check_player_hits()


func _input(event):
	# Lưu trạng thái nhấn/thả trực tiếp từ cửa sổ game, thay vì chỉ hỏi
	# trạng thái bàn phím toàn cục. Cả keycode và physical_keycode được hỗ trợ.
	if event is InputEventKey and not event.echo:
		for key in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
			if event.keycode == key or event.physical_keycode == key:
				held_keys[key] = event.pressed
				get_viewport().set_input_as_handled()
				return

func fire_projectile(target_position: Vector2) -> void:
	if game_over:
		return
	var projectile = Projectile.new()
	projectile.name = "Projectile_C"
	add_child(projectile)
	projectile.add_to_group("projectiles")
	projectile.setup(player.global_position, target_position)


func add_character_art(character: Node2D, base_color: Color, accent_color: Color, is_enemy: bool) -> void:
	var art = CharacterArt.new()
	character.add_child(art)
	art.setup(base_color, accent_color, is_enemy)


func setup_enemy(current_enemy: CharacterBody2D, spawn_position: Vector2) -> void:
	current_enemy.global_position = spawn_position
	current_enemy.set_meta("hits", 0)
	current_enemy.add_to_group("enemies")


func spawn_enemies_over_time(delta: float, screen_size: Vector2) -> void:
	enemy_spawn_cooldown -= delta
	if enemy_spawn_cooldown <= 0.0 and get_tree().get_nodes_in_group("enemies").size() < MAX_ENEMIES:
		spawn_enemy(screen_size)
		enemy_spawn_cooldown = ENEMY_SPAWN_INTERVAL


func spawn_enemy(screen_size: Vector2) -> void:
	var new_enemy := enemy_template.duplicate() as CharacterBody2D
	new_enemy.name = "Enemy_B"
	add_child(new_enemy)
	setup_enemy(new_enemy, Vector2(screen_size.x + 60.0, randf_range(60.0, screen_size.y - 60.0)))


func move_enemies(delta: float, screen_size: Vector2) -> void:
	for current_enemy in get_tree().get_nodes_in_group("enemies"):
		current_enemy.global_position.x -= ENEMY_SPEED * delta
		if current_enemy.global_position.x < -60.0:
			current_enemy.global_position.x = screen_size.x + 60.0
			current_enemy.global_position.y = randf_range(60.0, screen_size.y - 60.0)


func check_projectile_hits() -> void:
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		for current_enemy in get_tree().get_nodes_in_group("enemies"):
			if projectile.global_position.distance_to(current_enemy.global_position) <= PROJECTILE_HIT_RADIUS:
				projectile.queue_free()
				var hit_count := int(current_enemy.get_meta("hits", 0)) + 1
				current_enemy.set_meta("hits", hit_count)
				if hit_count >= ENEMY_HIT_POINTS:
					current_enemy.queue_free()
					enemy_spawn_cooldown = maxf(enemy_spawn_cooldown, ENEMY_SPAWN_INTERVAL)
				break


func check_player_hits() -> void:
	for current_enemy in get_tree().get_nodes_in_group("enemies"):
		if player.global_position.distance_to(current_enemy.global_position) <= PLAYER_HIT_RADIUS:
			game_over = true
			player.velocity = Vector2.ZERO
			player.visible = false
			for projectile in get_tree().get_nodes_in_group("projectiles"):
				projectile.queue_free()
			return


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("071326"))

	# Sao và lưới phối cảnh tạo nền không gian cho màn chơi.
	for i in range(72):
		var x := fposmod(float(i * 197), size.x)
		var y := fposmod(float(i * 83), size.y)
		var star_size := 1.0 + float(i % 3)
		draw_circle(Vector2(x, y), star_size, Color(0.45, 0.72, 1.0, 0.48))

	for y in range(0, int(size.y) + 1, 90):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.12, 0.38, 0.6, 0.24), 1.0)
	for x in range(0, int(size.x) + 1, 120):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.12, 0.38, 0.6, 0.18), 1.0)
