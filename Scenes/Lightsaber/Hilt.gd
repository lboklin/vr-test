extends MeshInstance

export (NodePath) var blade_node = null
var blade = null

export var length = 0.15 setget set_length, get_length
export var width = 0.014 setget set_width, get_width

export var activator_on = false setget set_active

export var ignite_time = 0.25
export var retract_time = 0.25

export var blade_length = 1.1 setget set_blade_length, get_blade_length
export var blade_width = 0.024 setget set_blade_width, get_blade_width


func _ready():
	blade = get_node(blade_node)
	readjust_collision_shape()
	set_process(true)


func _process(delta):
	if blade:
		var length_ = update_blade_length(delta)
		blade.length = length_

func readjust_collision_shape():
	var ls = self.get_parent()
	if ls:
		var cs = ls.find_node("CollisionShape")
		if cs:
			cs.global_transform = self.global_transform

func set_length(length_):
	self.scale.y = length_
	self.translation = Vector3(0, -length_ / 2, 0)
	length = length_

func get_length():
	return self.scale.y

func set_width(width_):
	var width__ = width_
	self.scale.x = width__
	self.scale.z = width__
	readjust_collision_shape()
	width = width__

func get_width():
	return self.scale.x

func set_active(is_on):
	if not blade:
		activator_on = false
		return false

	if not activator_on and is_on:
			blade.ignite()
	elif activator_on and not is_on:
			blade.retract()

	activator_on = is_on

func set_blade_length(length_):
	if blade:
		blade.max_length = length_
	blade_length = length_

func get_blade_length():
		return blade_length

func set_blade_width(width_):
	if blade:
		blade.max_width = width_
	width = width_

func get_blade_width():
	return blade_width


func update_blade_length(delta):
	if not blade:
		return 0

	var max_length = self.blade_length
	var current_length = blade.length

	var i_time = self.ignite_time
	var r_time = self.retract_time

	var is_on = self.activator_on
	var time = i_time if is_on else r_time
	var s = 1 if is_on else -1
	var change = s * (max_length / time) * delta

	return clamp(current_length + change, 0, max_length)
