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
	var head_rot: float = triangle_head.rotation if triangle_head else 0.0
	
	var rel_pts := PackedVector2Array()
	var top_overlap: Vector2 = Vector2(0, -12.0).rotated(head_rot)
	rel_pts.append(top_overlap)
	
	for pt in trail_points:
		rel_pts.append(pt - global_position)
		
	if rel_pts.size() >= 2:
		draw_polyline(rel_pts, player_color, current_tail_width)

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
