extends CharacterBody3D

@onready var skeleton = $"RootNode/Root Scene/RootNode/CharacterArmature/Skeleton3D"

func _ready() -> void:
	var head_bone : int = skeleton.

func turn(increment):
	var pitch_quat = Quaternion(Vector3.RIGHT, 0) * Quaternion(Vector3.UP, -increment)
	var parent_bone = skeleton.get_bone_parent(head_bone)
	var parent_global = skeleton.get_bone_global_pose(parent_bone)
	var head_rest_pos = skeleton.get_bone_rest(head_bone).origin
	var head_local_transform = Transform3D(Basis(pitch_quat), head_rest_pos)
	var final_global_pose = parent_global * head_local_transform
	skeleton.set_bone_global_pose_override(head_bone, final_global_pose, 1.0, true)
