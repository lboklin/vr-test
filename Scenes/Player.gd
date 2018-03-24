extends ARVROrigin

export (NodePath) var left_hand_item = null
export (NodePath) var right_hand_item = null


func _ready():
    if left_hand_item:
        grab(get_node(left_hand_item), $Left_Hand)
    if right_hand_item:
        grab(get_node(right_hand_item), $Right_Hand)

func grab(item, hand):
    var function_grab = hand.find_node("Function_Grab")
    if function_grab:
        var holding_anything = function_grab.equipped_item or function_grab.grabbed_item
        if not holding_anything:
            function_grab.grabbed_item = item
