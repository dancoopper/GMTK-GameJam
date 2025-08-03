extends Area2D


@export var target_portal : Node2D
@onready var collision_right = $CollisionShapeRight
@onready var collision_left = $CollisionShapeLeft

var is_enabled = true
var object: Node2D

func on_teleport():
	is_enabled = false

func _on_body_entered(body: Node2D) -> void:
	if target_portal == null || !is_enabled:
		return

	target_portal.on_teleport()
	
	if body.name == "player":
		body.position = target_portal.position

func _on_body_exited(body: Node2D) -> void:
	is_enabled = true

		
