extends CanvasLayer

@onready var skeleton = $"../RootNode/Root Scene/RootNode/CharacterArmature/Skeleton3D"
@onready var anim_tree = $"../RootNode/Root Scene/AnimationTree"
@onready var character = $"../RootNode"
@onready var blackscr = $ColorRect

var head_bone: int
var pressed: bool = false
var current_angle: float = 0.0
var timer: float = 0.0

func _ready() -> void:
	# Get the bone index once
	head_bone = skeleton.find_bone("Head")
	if head_bone == -1:
		print("Bone 'Head' not found!")
	blackscr.hide()

func _process(delta: float) -> void:
	if pressed:
		timer += delta
		if timer < 1.5:
			current_angle = sin(timer * 5.0) * 0.5
			turn(current_angle)
		else:
			skeleton.clear_bones_global_pose_override()
			anim_tree.set("parameters/TimeScale/scale", 1.5)
			anim_tree.set("parameters/OneShot 2/request", 1)
			await get_tree().create_timer(0.22).timeout
			anim_tree.set("parameters/OneShot/request", 1)
			pressed = false
			await get_tree().create_timer(1).timeout
			character.hide()
			blackscr.show()
			await get_tree().create_timer(0.2).timeout
			get_tree().change_scene_to_file("res://level.tscn")

func _on_button_pressed() -> void:
	pressed = true
	timer = 0
	current_angle = 0

func turn(increment: float):
	var pitch_quat = Quaternion(Vector3.UP, increment)
	var parent_bone = skeleton.get_bone_parent(head_bone)
	var parent_global = skeleton.get_bone_global_pose(parent_bone)
	var head_rest_pos = skeleton.get_bone_rest(head_bone).origin
	var head_local_transform = Transform3D(Basis(pitch_quat), head_rest_pos)
	var final_global_pose = parent_global * head_local_transform
	skeleton.set_bone_global_pose_override(head_bone, final_global_pose, 1.0, true)
