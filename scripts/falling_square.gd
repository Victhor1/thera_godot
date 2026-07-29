class_name FallingSquare
extends Area2D

@export var fall_speed: float = 200.0
@export var rotation_speed: float = 1.5
@export var square_size: float = 60.0
@export var square_color: Color = Color("#ff2a4b")

@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D

static var _cached_points: PackedVector2Array = []

func _ready() -> void:
	add_to_group("enemies")
	_setup_polygon()

func setup(p_color: Color, p_fall_speed: float, p_rot_speed: float) -> void:
	square_color = p_color
	fall_speed = p_fall_speed
	rotation_speed = p_rot_speed
	if is_node_ready():
		_setup_polygon()

func _setup_polygon() -> void:
	if _cached_points.is_empty():
		var half: float = 30.0
		_cached_points = PackedVector2Array([
			Vector2(-half, -half),
			Vector2(half, -half),
			Vector2(half, half),
			Vector2(-half, half)
		])
	
	if polygon_2d:
		polygon_2d.polygon = _cached_points
		polygon_2d.color = square_color
		
	if collision_polygon_2d:
		collision_polygon_2d.polygon = _cached_points

func _process(delta: float) -> void:
	position.y += fall_speed * delta
	rotation += rotation_speed * delta
	
	var viewport_height: float = get_viewport_rect().size.y
	if position.y > viewport_height + 120.0:
		queue_free()
