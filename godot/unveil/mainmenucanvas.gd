extends CanvasLayer

@onready var skeleton = $"../RootNode/Root Scene/RootNode/CharacterArmature/Skeleton3D"

var head_bone: int
var pressed: bool = false
var current_angle: float = 0.0

func _ready() -> void:
	# Get the bone index once
	head_bone = skeleton.find_bone("Head")
	if head_bone == -1:
		print("Bone 'Head' not found!")

func _process(delta: float) -> void:
	#if pressed and head_bone != -1:
		# delta * 1.0 (speed) ensures smooth rotation every frame
		current_angle += delta * 1.0 
		turn(current_angle)

func _on_button_pressed() -> void:
	pressed = true
	print("press")

func turn(increment: float):
	var pitch_quat = Quaternion(Vector3.UP, increment)
	var parent_bone = skeleton.get_bone_parent(head_bone)
	var parent_global = skeleton.get_bone_global_pose(parent_bone)
	var head_rest_pos = skeleton.get_bone_rest(head_bone).origin
	var head_local_transform = Transform3D(Basis(pitch_quat), head_rest_pos)
	var final_global_pose = parent_global * head_local_transform
	skeleton.set_bone_global_pose_override(head_bone, final_global_pose, 1.0, true)
