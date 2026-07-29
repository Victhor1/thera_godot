class_name Player
extends Area2D

signal reached_middle
signal died

enum State { RISING, PLAYING, DEAD }

@export var rise_speed: float = 350.0
@export var lateral_speed: float = 240.0
@export var scroll_speed: float = 200.0
@export var triangle_width: float = 60.0
@export var triangle_height: float = 65.0
@export var tilt_angle_degrees: float = 25.0
@export var rotation_speed_tween: float = 0.15
@export var player_color: Color = Color("#0075ff")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")

@onready var triangle_head: Node2D = $TriangleHead
@onready var polygon_2d: Polygon2D = $TriangleHead/Polygon2D
@onready var collision_polygon_2d: CollisionPolygon2D = $TriangleHead/CollisionPolygon2D

var current_state: State = State.RISING
var target_y: float = 0.0
var is_tilted_right: bool = false
var active_tween: Tween = null
var trail_points: Array[Vector2] = []

func _ready() -> void:
	_setup_triangle()
	area_entered.connect(_on_area_entered)
	
	var viewport_size: Vector2 = get_viewport_rect().size
	position.x = viewport_size.x / 2.0
	position.y = viewport_size.y + triangle_height * 2.0
	target_y = viewport_size.y / 2.0
	
	trail_points.clear()
	var initial_bottom: Vector2 = Vector2(position.x, viewport_size.y + 100.0)
	trail_points.append(initial_bottom)

func _setup_triangle() -> void:
	var half_w: float = triangle_width / 2.0
	
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(0, -triangle_height),
		Vector2(half_w, 0),
		Vector2(-half_w, 0)
	])
	
	if polygon_2d:
		polygon_2d.polygon = points
		polygon_2d.color = player_color
		
	if collision_polygon_2d:
		collision_polygon_2d.polygon = points

func _get_base_world_pos() -> Vector2:
	return global_position

func _unhandled_input(event: InputEvent) -> void:
	if current_state != State.PLAYING:
		return
		
	var is_click: bool = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_click = true
	elif event is InputEventScreenTouch and event.pressed:
		is_click = true
		
	if is_click:
		_toggle_rotation()

func _toggle_rotation() -> void:
	is_tilted_right = !is_tilted_right
	var target_angle: float = deg_to_rad(tilt_angle_degrees) if is_tilted_right else deg_to_rad(-tilt_angle_degrees)
	
	var current_base_world: Vector2 = _get_base_world_pos()
	
	if trail_points.is_empty() or current_base_world.distance_to(trail_points[0]) > 6.0:
		trail_points.insert(0, current_base_world)
	else:
		trail_points[0] = current_base_world
		
	if active_tween and active_tween.is_running():
		active_tween.kill()
		
	active_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(triangle_head, "rotation", target_angle, rotation_speed_tween)

func _process(delta: float) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var margin: float = triangle_width / 2.0
	
	if current_state == State.RISING:
		position.y -= rise_speed * delta
		if position.y <= target_y:
			position.y = target_y
			current_state = State.PLAYING
			reached_middle.emit()
			_toggle_rotation()
			
	elif current_state == State.PLAYING:
		var dir: float = 1.0 if is_tilted_right else -1.0
		position.x += dir * lateral_speed * delta
		
		if position.x <= margin and !is_tilted_right:
			position.x = margin
			_toggle_rotation()
		elif position.x >= viewport_size.x - margin and is_tilted_right:
			position.x = viewport_size.x - margin
			_toggle_rotation()
			
		for i in range(trail_points.size()):
			trail_points[i].y += scroll_speed * delta
			
		while trail_points.size() > 1 and trail_points.back().y > viewport_size.y + 700.0:
			trail_points.pop_back()
			
	queue_redraw()

func _draw() -> void:
	if current_state == State.DEAD:
		return
		
	var current_tail_width: float = triangle_width * 0.60
	var half_tw: float = current_tail_width / 2.0
	var head_rot: float = triangle_head.rotation if triangle_head else 0.0
	
	var all_world_pts: Array[Vector2] = []
	all_world_pts.append(global_position)
	all_world_pts.append_array(trail_points)
	
	if all_world_pts.size() < 2:
		return
		
	for i in range(all_world_pts.size() - 1):
		var p_start_world: Vector2 = all_world_pts[i]
		var p_end_world: Vector2 = all_world_pts[i + 1]
		
		var rel_start: Vector2 = p_start_world - global_position
		var rel_end: Vector2 = p_end_world - global_position
		
		var dir: Vector2 = rel_end - rel_start
		if dir.length_squared() < 0.5:
			continue
			
		var norm: Vector2 = Vector2(-dir.y, dir.x).normalized() * half_tw
		
		var pt_tl: Vector2
		var pt_tr: Vector2
		var pt_br: Vector2
		var pt_bl: Vector2
		
		if i == 0:
			var base_right: Vector2 = Vector2(half_tw, 0.0).rotated(head_rot)
			pt_tl = Vector2(-half_tw, -6.0).rotated(head_rot)
			pt_tr = Vector2(half_tw, -6.0).rotated(head_rot)
			pt_br = rel_end + base_right
			pt_bl = rel_end - base_right
		else:
			pt_tl = rel_start - norm
			pt_tr = rel_start + norm
			pt_br = rel_end + norm
			pt_bl = rel_end - norm
			
		var quad := PackedVector2Array([pt_tl, pt_tr, pt_br, pt_bl])
		draw_colored_polygon(quad, player_color)
		draw_circle(rel_end, half_tw, player_color)

func _on_area_entered(area: Area2D) -> void:
	if current_state == State.DEAD:
		return
	if area is FallingSquare or area.is_in_group("enemies"):
		die()

func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	
	if explosion_scene:
		var exp_instance: Node2D = explosion_scene.instantiate() as Node2D
		exp_instance.global_position = global_position
		get_parent().add_child(exp_instance)
		
	died.emit()
	queue_free()
