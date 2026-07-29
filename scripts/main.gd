extends Node2D

@export var falling_square_scene: PackedScene = preload("res://scenes/falling_square.tscn")
@export var player_scene: PackedScene = preload("res://scenes/player.tscn")
@export var spawn_interval: float = 2.0
@export var max_squares: int = 5

@onready var spawn_timer: Timer = $SpawnTimer
@onready var squares_container: Node2D = $SquaresContainer
@onready var fps_label: Label = $UILayer/FPSLabel

const RED_PALETTE: Array[Color] = [
	Color("#ff2a4b"),
	Color("#ff0033"),
	Color("#d50000"),
	Color("#ff1744")
]

var active_player: Area2D = null
var _fps_timer: float = 0.0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#0f111a"))
	
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	_spawn_player()

func _process(delta: float) -> void:
	_fps_timer += delta
	if _fps_timer >= 0.1:
		_fps_timer = 0.0
		if fps_label:
			fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func _spawn_player() -> void:
	if not player_scene:
		return
		
	active_player = player_scene.instantiate() as Area2D
	add_child(active_player)
	
	if active_player.has_signal("reached_middle"):
		active_player.connect("reached_middle", _on_player_reached_middle)
	if active_player.has_signal("died"):
		active_player.connect("died", _on_player_died)

func _on_player_reached_middle() -> void:
	spawn_timer.start()
	_spawn_square()

func _on_player_died() -> void:
	spawn_timer.stop()
	await get_tree().create_timer(1.2).timeout
	get_tree().reload_current_scene()

func _on_spawn_timer_timeout() -> void:
	if squares_container.get_child_count() < max_squares:
		_spawn_square()
	
	spawn_timer.wait_time = randf_range(1.5, 2.5)

func _spawn_square() -> void:
	if not falling_square_scene:
		return
		
	var viewport_size: Vector2 = get_viewport_rect().size
	var square_instance: Area2D = falling_square_scene.instantiate() as Area2D
	
	var fixed_size: float = 60.0
	var margin: float = fixed_size
	var random_x: float = randf_range(margin, viewport_size.x - margin)
	var start_y: float = -fixed_size * 1.5
	
	var color: Color = RED_PALETTE.pick_random()
	var fall_speed: float = randf_range(170.0, 230.0)
	var rot_speed: float = randf_range(0.8, 2.2) * (1.0 if randf() > 0.5 else -1.0)
	
	square_instance.position = Vector2(random_x, start_y)
	squares_container.add_child(square_instance)
	if square_instance.has_method("setup"):
		square_instance.call("setup", color, fall_speed, rot_speed)
