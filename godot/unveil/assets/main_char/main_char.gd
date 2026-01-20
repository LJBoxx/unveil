extends CharacterBody3D

# --- Node References ---
@onready var camera = $"Root Scene/RootNode/CharacterArmature/Skeleton3D/Head/Head_end/Camera3D"
@onready var skeleton = $"Root Scene/RootNode/CharacterArmature/Skeleton3D"
@onready var anim_tree = $"Root Scene/AnimationTree"

@export_group("External Nodes")
@export var main_camera: Camera3D
@export var sprint_timer: Timer
@export var body_turn_threshold: float = deg_to_rad(15.0)

# --- Settings ---
@export_group("Movement Settings")
@export var mouse_sensitivity: float = 0.001
@export var base_speed: float = 1.6
@export var acceleration: float = 10.0
@export var sprint_speed_mult: float = 1.8
@export var walk_speed_mult: float = 0.6
@export var sprint_replenish_rate: float = 0.3
@export var enable_sprint: bool = true
@export var sprint_cooldown_time: float = 3.0
@export var sprint_time: float = 1.0
@export var motion_sick: bool = false
@export_range(0.01,1.0) var air_acceleration_modifier: float = 0.1
var sprint_on_cooldown: bool = false
var sprint_time_remaining: float = sprint_time

const NORMAL_speed = 1
@export_range(1.0,3.0) var sprint_speed: float = 2.0
@export_range(0.1,1.0) var walk_speed: float = 0.5
var speed_modifier: float = NORMAL_speed

# --- Internal Variables ---
var camera_rotation: Vector2 = Vector2.ZERO
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var cam_y_min = deg_to_rad(-50)
var cam_y_max = deg_to_rad(55)
var head_bone: int

func _ready() -> void:
	head_bone = skeleton.find_bone("Head")
	print(head_bone)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	update_camera_rotation()

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

	# Sprint Logic
	if Input.is_action_just_pressed("sprint") and not sprint_on_cooldown:
		speed_modifier = sprint_speed_mult
	
	if Input.is_action_just_released("sprint"):
		speed_modifier = 1.0

func _physics_process(delta: float) -> void:
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
	print(horizontal_speed)
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
		print(tresh)
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
