extends ARVROrigin

#export (NodePath) var left_hand_item = null
#export (NodePath) var right_hand_item = null

export (NodePath) var character = null
export var camera_distance = 2.0


func _ready():
	# Grab pre-equipped items
#	if left_hand_item:
#		grab(get_node(left_hand_item), $Left_Hand)
#	if right_hand_item:
#		grab(get_node(right_hand_item), $Right_Hand)

	set_process(true)

func _process(delta):
#	platform_movement(delta)

	var head = get_node(character).find_node("Head")
	var head_pos = head.global_transform.origin
	var head_back = head.global_transform.basis.z

	var hmd = $ARVRCamera
	var hmd_pos = hmd.global_transform.origin

	var hmd_back = hmd.global_transform.basis.z.normalized()
	var cam_offset = Vector3(0, 0.5, 0) + hmd_back * camera_distance / self.world_scale
	var tgt_camera_pos = head_pos + cam_offset # Behind head

	var pos_step = hmd_pos.linear_interpolate(tgt_camera_pos, delta * 2)

	# reset our player position to center
#	ARVRServer.center_on_hmd(true, true)
	var orig_to_hmd = hmd_pos - self.global_transform.origin
	# Reposition the player's POV towards behind the character
	self.global_transform.origin = pos_step - orig_to_hmd

func platform_movement(delta):
	var hmd = $ARVRCamera
	# Rotate platform to face the player horizontal offset
	var offset = Vector3(hmd.translation.x, 0, hmd.translation.z)
	$HoverPlatform.rotation.y = Vector3(0,0,1).angle_to(offset)
	# Move in the direction of the player's offset
	self.global_transform.origin += offset.length() * delta * -offset * 6

static func grab(item, hand):
	var function_grab = hand.find_node("Function_Grab")
	if function_grab:
		var holding_anything = function_grab.equipped_item or function_grab.grabbed_item
		if not holding_anything:
			function_grab.grabbed_item = item
