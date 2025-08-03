extends Area2D

@export var destination_point_path: NodePath
var destination_point: Node2D

func _ready():
	if destination_point_path:
		destination_point = get_node(destination_point_path)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and destination_point:
		body.set_position(destination_point.global_position)
