extends Spatial

export var blade_color = Color(0.5, 1.0, 0.7)# setget set_blade_color

var is_held = false setget _on_grab_pressed
var is_ignited = false setget _on_activator_pressed, get_is_ignited

func _on_activator_pressed(val):
	var is_ignited_ = val if self.is_held else false
	$Hilt.activator_on = is_ignited_
	is_ignited = is_ignited_

func get_is_ignited():
	return $Hilt.activator_on

func _on_grab_pressed():
	is_held = !is_held


func _on_use_pressed():
	if self.is_held:
		if not self.is_ignited:
			self.is_ignited = true
		else:
			self.is_ignited = false
