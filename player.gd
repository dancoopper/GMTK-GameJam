extends CharacterBody2D

@export var Speed := 15
@export var Run_speed := 25
@export var Friction := 15
@export var Jump_velocity := -450  # Negative = upward jump

var move_speed := Speed * 10
var run_speed := Run_speed * 10
var friction := Friction * 100

const accel := 1500
var health := 100

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim := $AnimatedSprite2D

var input := Vector2.ZERO

func on_ready():
	anim.play("idle")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta  # Apply gravity when not grounded

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = Jump_velocity  # Jump if on floor

	player_movement(delta)
	move_and_slide()  # Moves using the built-in velocity

func get_input() -> Vector2:
	input.x = Input.get_axis("ui_left", "ui_right")
	return input.normalized()

func player_movement(delta):
	input = get_input()

	if input == Vector2.ZERO:
		if abs(velocity.x) > friction * delta:
			velocity.x -= sign(velocity.x) * friction * delta
		else:
			velocity.x = 0
			anim.play("idle")
	else:
		anim.play("run")
		anim.flip_h = input.x < 0

		velocity.x += input.x * accel * delta
		velocity.x = clamp(velocity.x, -move_speed, move_speed)

func _on_child_entered_tree(node):
	if node.name == "Game":
		position = Vector2(980, 105)
		move_speed = 10000
		run_speed = 200

func _on_child_exiting_tree(node):
	move_speed = 10000
	run_speed = 1
