"res://addons/vr-common/functions/Function_pointer.tscn"extends Spatial

var target = null
var last_collided_at = Vector3(0, 0, 0)
var laser_y = -0.00
onready var ws = ARVRServer.world_scale

func set_enabled(p_enabled):
    $Laser/RayCast.enabled = p_enabled

func _on_button_pressed(p_button):
    if p_button == 15 and $Laser/RayCast.enabled:
        if $Laser/RayCast.is_colliding():
            target = $Laser/RayCast.get_collider()
            last_collided_at = $Laser/RayCast.get_collision_point()
            if target.has_method("_on_pointer_pressed"):
                target._on_pointer_pressed(last_collided_at)

func _on_button_release(p_button):
    if p_button == 15 and target:
        # let object know button was released
        if target.has_method("_on_pointer_release"):
            target._on_pointer_release(last_collided_at)
        if target.has_method("_on_use_release"):
            target._on_use_release()

        target = null
        last_collided_at = Vector3(0, 0, 0)

func _ready():
    # Get button press feedback from our parent (should be an ARVRController)
    get_parent().connect("button_pressed", self, "_on_button_pressed")
    get_parent().connect("button_release", self, "_on_button_release")

    # apply our world scale to our laser position
    $Laser.translation.y = laser_y * ws

func _process(delta):
    var new_ws = ARVRServer.world_scale
    if (ws != new_ws):
        ws = new_ws
    $Laser.translation.y = laser_y * ws

    if $Laser/RayCast.enabled and $Laser/RayCast.is_colliding():
        var new_at = $Laser/RayCast.get_collision_point()
        var new_target = $Laser/RayCast.get_collider()
        indicate_interactable(new_target)

        if new_at == last_collided_at:
            pass
        elif target:
            # if target is set our mouse must be down, we keep sending events to our target
            if target.has_method("_on_pointer_moved"):
                target._on_pointer_moved(new_at, last_collided_at)
        else:
            if new_target.has_method("_on_pointer_moved"):
                new_target._on_pointer_moved(new_at, last_collided_at)

        var new_z = -self.global_transform.origin.distance_to(new_at) / 1.9 # Just a bit longer to keep intersecting
        $Laser.transform.origin.z = new_z
        $Laser.transform.basis.z.z = new_z / -5
        last_collided_at = new_at
    else:
        $Laser.visible = false


func indicate_interactable(target):
    if target:
        var can_point = target.has_method("_on_pointer_moved")
        var can_use = target.has_method("_on_use_pressed")
        var can_grab = target.has_method("_on_grab_pressed")
        var interactable = can_use or can_grab or can_point
        $Laser.visible = interactable

        var color = Color(0.2, 0.2, 0.2) # Dim grey
        if can_use or can_grab:
            # If both are true, the color is cyan
            if can_use:
                color.b = 1.0 # Add blue
            if can_grab:
                color.g = 1.0 # Add green
        elif can_point:
            color = Color(0.7, 0.7, 0.7) # Light grey
        else:
            color.r = 1.0 # Red if non-interactable

        var laser_mat = $Laser.mesh.material
        laser_mat.emission = color
        laser_mat.albedo_color = color

        return interactable

