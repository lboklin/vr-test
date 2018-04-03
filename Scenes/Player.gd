extends ARVROrigin

#export (NodePath) var left_hand_item = null
#export (NodePath) var right_hand_item = null

export (NodePath) var character = null
export var camera_follow_distance = 2.0
export var camera_follow_vert_offset = 0.3
export var camera_follow_speed = 2 # meters per second
export var camera_follow_smooth = true
export var camera_mode = 0 setget set_camera_mode

enum CameraMode { FREE_WALK, FREE_HOVER, FOLLOW }

func set_camera_mode(mode):
	if $HoverPlatform:
		$HoverPlatform.visible = mode == CameraMode.FREE_HOVER
	camera_mode = mode


func _ready():
	self.camera_mode = 0
	# Grab pre-equipped items
#	if left_hand_item:
#		grab(get_node(left_hand_item), $Left_Hand)
#	if right_hand_item:
#		grab(get_node(right_hand_item), $Right_Hand)

	set_process(true)

func _process(delta):
	var head = get_node(character).find_node("Head")
	var head_pos = head.global_transform.origin
	var head_back = head.global_transform.basis.z.normalized()

	var hmd = $ARVRCamera
	var hmd_pos = hmd.global_transform.origin #/ world_scale
	var hmd_back = hmd.global_transform.basis.z.normalized()

	match camera_mode:
		FREE_WALK:
			pass
		FREE_HOVER:
			var platform = $HoverPlatform
			# Rotate platform to face the player horizontal offset
			var offset = Vector3(hmd.translation.x, 0, hmd.translation.z)
			platform.rotation.y = Vector3(0,0,1).angle_to(offset)
			# Move in the direction of the player's offset
			self.global_transform.origin += offset.length() * delta * -offset * 6
		FOLLOW:
			var v_offset = Vector3(0, head_pos.y + camera_follow_vert_offset, 0)
			var h_offset = (hmd_back * Vector3(1,0,1)).normalized()
			var cam_offset = camera_follow_distance * h_offset + v_offset #/ self.world_scale
			var tgt_camera_pos = head_pos + cam_offset # Behind head

			var orig_to_hmd = hmd_pos - self.global_transform.origin

			# Move camera
			var next_pos
			if !camera_follow_smooth:
				next_pos = tgt_camera_pos
			else:
				var hmd_to_tgt = tgt_camera_pos - hmd_pos
				var dir = hmd_to_tgt.normalized()
				var dist = hmd_to_tgt.length()
				next_pos = hmd_pos + dir * min(dist, camera_follow_speed * delta)
			var new_pos = next_pos - orig_to_hmd
			self.global_transform.origin = new_pos

static func grab(item, hand):
	var function_grab = hand.find_node("Function_Grab")
	if function_grab:
		var holding_anything = function_grab.equipped_item or function_grab.grabbed_item
		if not holding_anything:
			function_grab.grabbed_item = item
