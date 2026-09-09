extends Node2D

const SPEED := 620.0
const RADIUS := 12.0

var direction := Vector2.RIGHT


func setup(start_position: Vector2, target_position: Vector2) -> void:
	global_position = start_position
	direction = start_position.direction_to(target_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	rotation = direction.angle()


func _ready() -> void:
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	var screen_size := get_viewport_rect().size
	if global_position.x < -RADIUS or global_position.x > screen_size.x + RADIUS \
		or global_position.y < -RADIUS or global_position.y > screen_size.y + RADIUS:
		queue_free()


func _draw() -> void:
	# Đạn C: vòng tròn vàng để dễ phân biệt với A và B.
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.82, 0.15))
	draw_circle(Vector2.ZERO, RADIUS * 0.45, Color(1.0, 0.35, 0.08))
