class_name Player
extends Area2D

signal reached_middle
signal died

enum State { RISING, PLAYING, DEAD }

@export var rise_speed: float = 350.0
@export var triangle_width: float = 60.0
@export var triangle_height: float = 65.0
@export var player_color: Color = Color("#0075ff")
@export var explosion_scene: PackedScene = preload("res://scenes/explosion.tscn")

@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D

var current_state: State = State.RISING
var target_y: float = 0.0

func _ready() -> void:
	_setup_triangle()
	area_entered.connect(_on_area_entered)
	
	var viewport_size: Vector2 = get_viewport_rect().size
	position.x = viewport_size.x / 2.0
	position.y = viewport_size.y + triangle_height * 2.0
	target_y = viewport_size.y / 2.0

func _setup_triangle() -> void:
	var half_w: float = triangle_width / 2.0
	var half_h: float = triangle_height / 2.0
	
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(0, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	
	if polygon_2d:
		polygon_2d.polygon = points
		polygon_2d.color = player_color
		
	if collision_polygon_2d:
		collision_polygon_2d.polygon = points

func _process(delta: float) -> void:
	if current_state == State.RISING:
		position.y -= rise_speed * delta
		if position.y <= target_y:
			position.y = target_y
			current_state = State.PLAYING
			reached_middle.emit()

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
