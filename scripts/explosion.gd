class_name Explosion
extends Node2D

@export var particle_count: int = 18
@export var duration: float = 0.55

var particles: Array[Dictionary] = []
var elapsed: float = 0.0

const EXPLOSION_COLORS: Array[Color] = [
	Color("#ff2a4b"),
	Color("#0075ff"),
	Color("#ffffff"),
	Color("#ff9900")
]

const TRIANGLE_PTS: PackedVector2Array = [
	Vector2(0, -8), Vector2(7, 6), Vector2(-7, 6)
]
const SQUARE_PTS: PackedVector2Array = [
	Vector2(-6, -6), Vector2(6, -6), Vector2(6, 6), Vector2(-6, 6)
]

func _ready() -> void:
	for i in range(particle_count):
		var angle: float = randf_range(0.0, TAU)
		var speed: float = randf_range(180.0, 440.0)
		
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.RIGHT.rotated(angle) * speed,
			"rot": randf_range(0.0, TAU),
			"rot_speed": randf_range(-12.0, 12.0),
			"scale": randf_range(0.6, 1.4),
			"color": EXPLOSION_COLORS.pick_random(),
			"shape": randi() % 2
		})

func _process(delta: float) -> void:
	elapsed += delta
	var progress: float = elapsed / duration
	
	if progress >= 1.0:
		queue_free()
		return
		
	var speed_mult: float = 1.0 - (progress * 0.5)
	var fade_alpha: float = 1.0 - progress
	
	for p in particles:
		p["pos"] += p["vel"] * speed_mult * delta
		p["rot"] += p["rot_speed"] * delta
		p["color"].a = fade_alpha
		
	queue_redraw()

func _draw() -> void:
	var progress: float = elapsed / duration
	var scale_mult: float = 1.0 - (progress * 0.7)
	
	for p in particles:
		var transform_mat := Transform2D(p["rot"], Vector2.ONE * (p["scale"] * scale_mult), 0.0, p["pos"])
		var base_pts: PackedVector2Array = TRIANGLE_PTS if p["shape"] == 0 else SQUARE_PTS
		var transformed_pts := transform_mat * base_pts
		draw_colored_polygon(transformed_pts, p["color"])
