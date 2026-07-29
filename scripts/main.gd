extends Node2D

@export var falling_square_scene: PackedScene = preload("res://scenes/falling_square.tscn")
@export var spawn_interval: float = 2.0
@export var max_squares: int = 5

@onready var spawn_timer: Timer = $SpawnTimer
@onready var squares_container: Node2D = $SquaresContainer

const COLOR_PALETTE: Array[Color] = [
	Color("#00f0ff"),
	Color("#ff007f"),
	Color("#ffd700"),
	Color("#39ff14"),
	Color("#9d00ff"),
	Color("#ff5722"),
	Color("#00e5ff")
]

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#0f111a"))
	
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	_spawn_square()

func _on_spawn_timer_timeout() -> void:
	if squares_container.get_child_count() < max_squares:
		_spawn_square()
	
	spawn_timer.wait_time = randf_range(1.5, 2.5)

func _spawn_square() -> void:
	if not falling_square_scene:
		return
		
	var viewport_size: Vector2 = get_viewport_rect().size
	var square_instance: FallingSquare = falling_square_scene.instantiate() as FallingSquare
	
	var size: float = randf_range(50.0, 90.0)
	var margin: float = size
	var random_x: float = randf_range(margin, viewport_size.x - margin)
	var start_y: float = -size * 1.5
	
	var color: Color = COLOR_PALETTE.pick_random()
	var fall_speed: float = randf_range(160.0, 240.0)
	var rot_speed: float = randf_range(0.8, 2.2) * (1.0 if randf() > 0.5 else -1.0)
	
	square_instance.position = Vector2(random_x, start_y)
	squares_container.add_child(square_instance)
	square_instance.setup(size, color, fall_speed, rot_speed)
