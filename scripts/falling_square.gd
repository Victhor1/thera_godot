class_name FallingSquare
extends Node2D

@export var fall_speed: float = 200.0
@export var rotation_speed: float = 1.5
@export var square_size: float = 60.0
@export var square_color: Color = Color.WHITE

@onready var polygon_2d: Polygon2D = $Polygon2D

func _ready() -> void:
	_setup_polygon()

func setup(p_size: float, p_color: Color, p_fall_speed: float, p_rot_speed: float) -> void:
	square_size = p_size
	square_color = p_color
	fall_speed = p_fall_speed
	rotation_speed = p_rot_speed
	if is_node_ready():
		_setup_polygon()

func _setup_polygon() -> void:
	if not polygon_2d:
		return
	var half: float = square_size / 2.0
	polygon_2d.polygon = PackedVector2Array([
		Vector2(-half, -half),
		Vector2(half, -half),
		Vector2(half, half),
		Vector2(-half, half)
	])
	polygon_2d.color = square_color

func _process(delta: float) -> void:
	position.y += fall_speed * delta
	rotation += rotation_speed * delta
	
	var viewport_height: float = get_viewport_rect().size.y
	if position.y > viewport_height + square_size * 2.0:
		queue_free()
