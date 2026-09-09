extends Node2D

var base_color := Color(0.15, 0.75, 1.0)
var accent_color := Color(0.75, 0.95, 1.0)
var is_enemy := false


func setup(new_base_color: Color, new_accent_color: Color, enemy: bool) -> void:
	base_color = new_base_color
	accent_color = new_accent_color
	is_enemy = enemy
	queue_redraw()


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Halo và viền giúp nhân vật nổi bật trên nền tối.
	draw_circle(Vector2.ZERO, 38.0, Color(base_color, 0.16))
	draw_circle(Vector2.ZERO, 32.0, Color(0.03, 0.08, 0.16, 0.95))
	draw_circle(Vector2.ZERO, 29.0, base_color)

	if is_enemy:
		# Drone địch: thân hình thoi với mắt đỏ.
		draw_colored_polygon(PackedVector2Array([Vector2(-34, 0), Vector2(0, -24), Vector2(34, 0), Vector2(0, 24)]), base_color.darkened(0.18))
		draw_line(Vector2(-24, 0), Vector2(24, 0), accent_color, 4.0, true)
		draw_circle(Vector2.ZERO, 11.0, accent_color)
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.92, 0.72))
	else:
		# Drone người chơi: thân tròn, cánh và lõi năng lượng xanh.
		draw_colored_polygon(PackedVector2Array([Vector2(-42, 9), Vector2(-20, -12), Vector2(-12, 18)]), base_color.darkened(0.12))
		draw_colored_polygon(PackedVector2Array([Vector2(42, 9), Vector2(20, -12), Vector2(12, 18)]), base_color.darkened(0.12))
		draw_circle(Vector2(0, -3), 16.0, accent_color)
		draw_circle(Vector2(0, -3), 8.0, Color(0.08, 0.22, 0.38))
		draw_line(Vector2(-13, 22), Vector2(13, 22), accent_color, 3.0, true)
