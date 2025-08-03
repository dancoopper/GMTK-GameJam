extends Timer

@export var freezables: Array[Node2D]
@export var duplicate_opacity: float = 0.5
@export var rewind_duration: float = 1.0  # Duration of rewind animation
@export var time_label: Label  # Assign in inspector or code
@export var record_interval: float = 0.1  # How often to record positions (in seconds)
@export var max_history_length: int = 100  # Maximum number of history entries
@export var crt_shader: ColorRect # How to enable / disable this shader during the rewind 
@export var time_bar: ProgressBar

var original_positions: Array[Transform2D]
var _duplicates: Array[Node2D]
var is_rewind = true
var is_rewinding = false

# History recording variables
var history_timer: float = 0.0
var position_history: Array[Array] = []  # Array of Arrays containing Transform2D for each freezable
var velocity_history: Array[Array] = []  # Array of Arrays containing velocity data

func _ready():
	_duplicates = []
	original_positions = []
	position_history = []
	velocity_history = []
	
	for i in freezables.size():
		original_positions.append(freezables[i].global_transform)
		_duplicates.append(null)
		position_history.append([])
		velocity_history.append([])
	
	# Record initial positions
	record_current_state()

func _process(delta):
	# Update time display
	if time_label:
		time_label.text = "Time: %.1fs" % time_left
		
	if time_bar:
		time_bar.max_value = wait_time
		time_bar.value = time_left
	
	# Record history at intervals
	if not is_rewinding:
		history_timer += delta
		if history_timer >= record_interval:
			record_current_state()
			history_timer = 0.0

func record_current_state():
	for i in freezables.size():
		var freezable = freezables[i]
		
		# Record transform
		position_history[i].append(freezable.global_transform)
		
		# Record velocity data
		var velocity_data = {}
		if freezable is CharacterBody2D:
			velocity_data["type"] = "CharacterBody2D"
			velocity_data["velocity"] = (freezable as CharacterBody2D).velocity
		elif freezable is RigidBody2D:
			var body := freezable as RigidBody2D
			velocity_data["type"] = "RigidBody2D"
			velocity_data["linear_velocity"] = body.linear_velocity
			velocity_data["angular_velocity"] = body.angular_velocity
		else:
			velocity_data["type"] = "Node2D"
		
		velocity_history[i].append(velocity_data)
		
		# Limit history length to prevent memory issues
		if position_history[i].size() > max_history_length:
			position_history[i].pop_front()
			velocity_history[i].pop_front()

func on_timeout():
	if not is_rewinding:
		handle_duplicate()
		start_rewind_animation()

func handle_duplicate():
	for i in freezables.size():
		if _duplicates[i]:
			_duplicates[i].queue_free()
		
		var dup := freezables[i].duplicate() as Node2D
		dup.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		dup.set_process(false)
		dup.set_physics_process(false)
		set_opacity_recursive(dup, duplicate_opacity)
		add_child(dup)
		_duplicates[i] = dup

func start_rewind_animation():
	if crt_shader:
		crt_shader.visible = true
	is_rewinding = true
	set_paused(true)  # Disable timer during rewind
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	for i in freezables.size():
		animate_rewind_for_object(i, tween)
	
	tween.tween_callback(finish_rewind)

func animate_rewind_for_object(index: int, tween: Tween):
	var freezable = freezables[index]
	var history = position_history[index]
	
	if history.is_empty():
		return
	
	# Reset velocity immediately
	reset_velocity(freezable, index)
	
	# Always use smooth history-based rewind if we have enough data
	if history.size() >= 3:
		animate_through_history(freezable, history, tween, index)
	else:
		# Simple fallback for insufficient history
		tween.parallel().tween_property(freezable, "global_transform", original_positions[index], rewind_duration)

func animate_through_history(freezable: Node2D, history: Array, tween: Tween, index: int):
	# Create the complete rewind path
	var rewind_path: Array[Transform2D] = []
	
	# Add current position as starting point
	rewind_path.append(freezable.global_transform)
	
	# Add history in reverse chronological order (recent to old)
	for i in range(history.size() - 1, -1, -1):
		rewind_path.append(history[i])
	
	# Make sure we end at original position
	rewind_path.append(original_positions[index])
	
	# Use a single tween that walks through the path
	tween.parallel().tween_method(
		func(t: float):
			# t goes from 0.0 to 1.0 over the duration
			var path_progress = t * (rewind_path.size() - 1)
			var current_index = int(path_progress)
			var next_index = min(current_index + 1, rewind_path.size() - 1)
			var blend_factor = path_progress - current_index
			
			# Interpolate between current and next transform
			var current_transform = rewind_path[current_index]
			var next_transform = rewind_path[next_index]
			
			var blended_transform = Transform2D()
			blended_transform.origin = current_transform.origin.lerp(next_transform.origin, blend_factor)
			blended_transform.x = current_transform.x.lerp(next_transform.x, blend_factor)
			blended_transform.y = current_transform.y.lerp(next_transform.y, blend_factor)
			
			freezable.global_transform = blended_transform,
		0.0,
		1.0,
		rewind_duration
	)

func reset_velocity(freezable: Node2D, index: int):
	if freezable is CharacterBody2D:
		(freezable as CharacterBody2D).velocity = Vector2.ZERO
	elif freezable is RigidBody2D:
		var body := freezable as RigidBody2D
		body.linear_velocity = Vector2.ZERO
		body.angular_velocity = 0.0

func finish_rewind():
	if crt_shader:
		crt_shader.visible = false  # Hide CRT effect after rewind
	is_rewinding = false
	
	# Clear history for fresh start
	for i in freezables.size():
		position_history[i].clear()
		velocity_history[i].clear()
	
	# Record initial positions again
	record_current_state()
	
	set_paused(false)  # Re-enable timer
	start()  # Restart timer for next cycle

func set_opacity_recursive(node: Node, opacity: float) -> void:
	if node is CanvasItem:
		var canvas_item := node as CanvasItem
		var current_color = canvas_item.modulate
		canvas_item.modulate = Color(current_color.r, current_color.g, current_color.b, opacity)
	
	for child in node.get_children():
		set_opacity_recursive(child, opacity)

# Optional: Get current history length for debugging
func get_history_length() -> int:
	if position_history.is_empty():
		return 0
	return position_history[0].size()

# Optional: Clear history manually
func clear_history():
	for i in freezables.size():
		position_history[i].clear()
		velocity_history[i].clear()
	record_current_state()
