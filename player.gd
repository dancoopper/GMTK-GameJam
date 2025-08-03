extends CharacterBody2D

@export var Speed = 15
@export var Run_speed = 25
@export var Friction = 15

var move_speed = Speed * 10
var run_speed = Run_speed * 10
var friction = Friction * 100

const accel = 1500


var health = 100

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = get_node("AnimatedSprite2D")

var input = Vector2.ZERO



# Called when the node enters the scene tree for the first time.
func on_ready(): 
	anim.play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#print(position)
	if not is_on_floor():
		velocity += get_gravity() * delta
	player_movement(delta)
	

# 	
func get_input():
	input.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")) #takes the move left away from the right 
	#input.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up")) #takes the move right away from the left
	
	
	return input.normalized() # makes it a more manageabel number 

func player_movement(delta):
	input = get_input()
	if input == Vector2.ZERO:
		if velocity.length() > (friction * delta):
			velocity -= velocity.normalized() * (friction * delta)
		else:
			anim.play("idle")
			velocity = Vector2.ZERO
	else:
		anim.play("run")
		
		#this block makes sure that the lil guy faces the right way
		var dir = Input.get_axis("ui_left", "ui_right")
		if dir == -1:
			get_node("AnimatedSprite2D").flip_h = true
		elif dir == 1:
			get_node("AnimatedSprite2D").flip_h = false
		
		
		
		velocity += (input * accel * delta)
		if Input.is_action_pressed("ui_run"):
			velocity = velocity.limit_length(run_speed)
		else:
			velocity = velocity.limit_length(move_speed)
	move_and_slide()
	



func _on_child_entered_tree(node):
	if node.name =="Game":
		self.position = Vector2(980, 105)
		move_speed = 10000
		run_speed = 200


func _on_child_exiting_tree(node):
	
	move_speed = 10000
	run_speed = 1
	
