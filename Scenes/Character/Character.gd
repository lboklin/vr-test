extends Spatial

export (NodePath) var player = null

var player_node = null

onready var orig_scale = self.scale

func _ready():
	self.player_node = get_node(self.player)
	set_physics_process(true)

func _physics_process(delta):
	var camera = get_viewport().get_camera()
	var head = $Head

	# Rotate character's head to match the camera
	head.translation = camera.transform.origin / player_node.world_scale
	head.global_transform.basis = camera.global_transform.basis
	head.rotation.x = 0
	head.scale = self.orig_scale
