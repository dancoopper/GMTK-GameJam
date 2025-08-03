extends CharacterBody2D

@export var Speed = 15
@export var Run_speed = 25
@export var Friction = 15
@export var Jump_velocity = -450  # Negative because up is -Y

var move_speed = Speed * 10
var run_speed = Run_speed * 10
var friction = Friction * 100

const accel = 1500
var health = 100

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = get_node("AnimatedSprite2D")

var input = Vector2.ZERO

func on_ready():
	anim.play("idle")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += (gravity + 1000) * delta  # Apply gravity over time

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = Jump_velocity  # Jump (usually mapped to spacebar)

	player_movement(delta)

func get_input():
	input.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	return input.normalized()

func player_movement(delta):
	input = get_input()

	if input == Vector2.ZERO:
		if velocity.length() > (friction * delta):
			velocity -= velocity.normalized() * (friction * delta)
		else:
			anim.play("idle")
			velocity.x = 0
	else:
		anim.play("run")
		
		var dir = Input.get_axis("ui_left", "ui_right")
		if dir == -1:
			anim.flip_h = true
		elif dir == 1:
			anim.flip_h = false

		velocity.x += input.x * accel * delta
		velocity.x = clamp(velocity.x, -move_speed, move_speed)

	# Apply movement
	move_and_slide()

func _on_child_entered_tree(node):
	if node.name == "Game":
		position = Vector2(980, 105)
		move_speed = 10000
		run_speed = 200

func _on_child_exiting_tree(node):
	move_speed = 10000
	run_speed = 1
