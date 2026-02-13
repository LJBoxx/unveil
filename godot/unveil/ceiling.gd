extends MeshInstance3D

@export_enum("Steady", "Flicker", "Off") var light_on : int = 0
@onready var spotlight = $"OmniLight3D"
@export var flicker : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var material = get_active_material(0)
	var rng = randf()
	if flicker:
		if rng < 0.9:
			#material.set_shader_parameter(light_on, true)
			spotlight.show()
		else:
			#material.set_shader_parameter(light_on, false)
			spotlight.hide()
	else:
		spotlight.show()
