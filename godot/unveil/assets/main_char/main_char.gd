extends CharacterBody3D

# --- Node References ---
@onready var camera = $"Root Scene/RootNode/CharacterArmature/Skeleton3D/Head/Head_end/Camera3D"
@onready var skeleton = $"Root Scene/RootNode/CharacterArmature/Skeleton3D"
@onready var anim_tree = $"Root Scene/AnimationTree"
@onready var canvas = $CanvasLayer
@onready var root = $"."
@onready var stamina : ProgressBar = $CanvasLayer/Control/stamina
@onready var pill_counter : Label = $CanvasLayer/Control/Label

@export_group("External Nodes")
@export var bed_camera: Camera3D
@export var sprint_timer: Timer
@export var body_turn_threshold: float = deg_to_rad(15.0)

# --- Settings ---
@export_group("Movement Settings")
@export var mouse_sensitivity: float = 0.001
@export var base_speed: float = 1.6
@export var acceleration: float = 6.0
@export var sprint_speed_mult: float = 1.8
@export var walk_speed_mult: float = 0.6
@export var sprint_replenish_rate: float = 0.3
@export var enable_sprint: bool = true
@export var sprint_cooldown_time: float = 3.0
@export var sprint_time: float = 1.0
var current_sprint_time: float = 1.0
@export var motion_sick: bool = false
@export_range(0.01,1.0) var air_acceleration_modifier: float = 0.1
var sprint_on_cooldown: bool = false

const NORMAL_speed = 1
@export_range(1.0,3.0) var sprint_speed: float = 2.0
@export_range(0.1,1.0) var walk_speed: float = 0.5
var speed_modifier: float = NORMAL_speed
@export_range(0.5,3.0) var reach: float = 2
@export_range(0,10) var pills: int = 0


# --- Internal Variables ---
var camera_rotation: Vector2 = Vector2.ZERO
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var cam_y_min = deg_to_rad(-50)
var cam_y_max = deg_to_rad(55)
var head_bone: int
var hover_object =  null
var interacting: bool = false
var sleeping: bool = false
var viewing: bool = false

func _ready() -> void:
	head_bone = skeleton.find_bone("Head")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_camera_rotation()
	disable_all_outlines(get_tree().root)

func _process(_delta):
	camera_look(Vector2.ZERO)
	
func _input(event: InputEvent) -> void:
	# Toggle Mouse
	if event.is_action_pressed("ui_cancel"):
		var mode = Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		Input.set_mouse_mode(mode)
		
	# Mouse Look
	if event is InputEventMouseMotion:
		camera_rotation += event.relative * mouse_sensitivity
		check_hover()
	
	if hover_object != null and Input.is_action_just_pressed("action"):
#		print(hover_object)
		interact(hover_object)
		
func _physics_process(delta: float) -> void:
	handle_movement_state(delta)
	handle_stamina(delta)
	# Apply Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	# Handle Input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var target_speed = base_speed * speed_modifier
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)
	
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	anim_tree.set("parameters/walk/blend_position", horizontal_speed)

	move_and_slide()

func camera_look(movement: Vector2) -> void:
	camera_rotation += movement
	camera_rotation.y = clamp(camera_rotation.y, cam_y_min, cam_y_max)
# for motion sickness
	if motion_sick: 
		transform.basis = Basis()
		camera.transform.basis = Basis()
		rotate_object_local(Vector3.UP, -camera_rotation.x)
		camera.rotate_object_local(Vector3.RIGHT, -camera_rotation.y)
	else:
		var tresh = max(body_turn_threshold - pow(abs(camera_rotation.y), 3), 0.005)
		if abs(camera_rotation.x) > tresh:
			var overflow = camera_rotation.x - (sign(camera_rotation.x)*tresh)
			rotate_object_local(Vector3.UP, -overflow)
			camera_rotation.x -= overflow
		var pitch_quat = Quaternion(Vector3.RIGHT, camera_rotation.y) * Quaternion(Vector3.UP, -camera_rotation.x)
		var parent_bone = skeleton.get_bone_parent(head_bone)
		var parent_global = skeleton.get_bone_global_pose(parent_bone)
		var head_rest_pos = skeleton.get_bone_rest(head_bone).origin
		var head_local_transform = Transform3D(Basis(pitch_quat), head_rest_pos)
		var final_global_pose = parent_global * head_local_transform
		skeleton.set_bone_global_pose_override(head_bone, final_global_pose, 1.0, true)

func update_camera_rotation() -> void:
	camera_rotation.x = rotation.y
	camera_rotation.y = camera.rotation.x

func handle_stamina(delta):
	if speed_modifier == sprint_speed:
		current_sprint_time -= delta
		
		if current_sprint_time <= 0:
			current_sprint_time = 0
			sprint_on_cooldown = true 
			speed_modifier = NORMAL_speed
	else:
		if is_on_floor():
			current_sprint_time = move_toward(current_sprint_time, sprint_time, delta * sprint_replenish_rate)
	
	var sprint_bar_value = (current_sprint_time / sprint_time) * 100
	stamina.value = sprint_bar_value
	if sprint_bar_value == 100:
		sprint_on_cooldown = false
		stamina.hide()
	else:
		stamina.show()

func handle_movement_state(_delta):
	var direction = Input.get_vector("left", "right", "forward", "backward")
	var is_moving = direction.length_squared() > 0
	var is_holding_sprint = Input.is_action_pressed("sprint")
	
	if is_moving and is_holding_sprint and not sprint_on_cooldown and current_sprint_time > 0:
		speed_modifier = sprint_speed
	else:
		speed_modifier = NORMAL_speed
		
func check_hover():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	var previous_hover = hover_object
	
	if result:
		var distance = global_position.distance_to(result.position)
		if distance <= reach:
			hover_object = result.collider
		else:
			hover_object = null
	else:
		hover_object = null
	
	if previous_hover != hover_object:
		if previous_hover:
			remove_outline(previous_hover)
		if hover_object:
			add_outline(hover_object)

func interact(object):
	if !interacting:
		if object is Interactable:
#			print("type: ", object.interaction_type)
			match object.interaction_type:
				"Sleep": sleep()
				"View": view(object)
				"Grab": grab(object)
	else:
		exit()

func add_outline(body):
	for child in body.get_children():
		if child is Sprite3D:
			child.show()
		if child is MeshInstance3D:
			var material = child.get_active_material(0)
			if material and material.next_pass:
				material.next_pass.set("grow", true)

func remove_outline(body):
	for child in body.get_children():
		if child is Sprite3D:
			child.hide()
	for child in body.get_children():
		if child is MeshInstance3D:
			var material = child.get_active_material(0)
			if material and material.next_pass:
				material.next_pass.set("grow", false)

func disable_all_outlines(node):
	if node is StaticBody3D:
		remove_outline(node)
	for child in node.get_children():
		disable_all_outlines(child)

func sleep():
	interacting = true
	bed_camera.make_current()
#	print("sleeping")
	root.hide()
	sleeping = true
	freeze_player(true) 

func view(object):
	if object.interaction_data.has("panel"):
		var panel_scene = object.interaction_data["panel"]
		var panel = panel_scene.instantiate()
		canvas.add_child(panel)
		interacting = true
		freeze_player(true)

func grab(object):
	if object.interaction_data.has("Amount"):
		pills += object.interaction_data["Amount"]
		pill_counter.text = "Pills: " + str(pills)
		object.queue_free()

func exit():
	if interacting:
		if sleeping:
			sleeping = false
			root.show()
			camera.make_current()
		else:
			var view_panel = canvas.get_node_or_null("ViewPanel")
			if view_panel:
				view_panel.hide()
		freeze_player(false)
		interacting = false

func freeze_player(is_frozen: bool):
	set_physics_process(!is_frozen)
	set_process(!is_frozen)
