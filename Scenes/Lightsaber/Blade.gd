extends MeshInstance

const SCALE_FACTOR = 0.5

export var fluctuation_hz = 90
export var swing_humming_intensity = 10

export (NodePath) var hilt_node = null
onready var hilt = get_node(hilt_node)

#var blade_mat = null setget ,get_blade_mat

# Determined by Hilt
var max_length = 1.1 setget ,get_max_length
var max_width = 0.024 setget ,get_max_width
var fluctuation = 0.003 setget ,get_fluct

# Blade dimensions
var length = 0 setget set_length, get_length
var width = max_width setget set_width, get_width

onready var tip_pos = tip_pos()
var tip_pos_delta = 0
var humming = false setget humm,is_humming

func _ready():
    set_blade_mat(create_blade_mat())
    set_process(true)


func _process(delta):
    if hilt:
        var retracted = self.length <= 0
        humm(not retracted)
        if not retracted:
            blade_fluct(delta)
            set_blade_color(self.get_parent().blade_color)
#            swing_humm_intensity(delta)


func create_blade_mat():
    var mat = SpatialMaterial.new()
    mat.flags_transparent = true
#    mat.flags_unshaded = true
    mat.params_diffuse_mode = SpatialMaterial.DIFFUSE_LAMBERT_WRAP
#    mat.params_specular_mode = SpatialMaterial.SPECULAR_DISABLED
    mat.params_blend_mode = SpatialMaterial.BLEND_MODE_MIX
    mat.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALWAYS
    mat.emission_enabled = true
    mat.emission_energy = 16
    mat.roughness = 1
    return mat


func set_blade_mat(mat):
    self.set_surface_material(0, mat)

func get_blade_mat():
    var mat = self.get_surface_material(0)
    return mat if mat else create_blade_mat()


func set_blade_color(color_):
    var mat = get_blade_mat()
#    var mat = create_blade_mat() # Only for debug
    mat.emission = color_
    mat.albedo_color = color_.lightened(0.6)
    set_blade_mat(mat)
    $Glow.light_color = color_


func tip_pos():
    var orig = self.global_transform.origin
    var tip_rel = self.global_transform.basis.z
    var tip = orig + tip_rel
    return tip


func swing_humm_intensity(delta):
    var swing = $AudioStream_Swing
    var humm = $AudioStream_Humm
    var bus_index = AudioServer.get_bus_index(swing.bus)
    var pitch_shift_effect = AudioServer.get_bus_effect(bus_index, 0)
    var amp_effect = AudioServer.get_bus_effect(bus_index, 1)

    var pos = tip_pos()
    var last_pos = self.tip_pos
    self.tip_pos = pos

    var pos_delta = (pos - last_pos).length()
    var last_pos_delta = self.tip_pos_delta
    self.tip_pos_delta = pos_delta

    var delta_v = pos_delta - last_pos_delta
    var pitch_scale = lerp(0, 1, 2 * pow(swing_humming_intensity, 0.5))
#    var hmm = pow(swing_humming_intensity, 0.2) * delta * 0.0001
#    var a = pos_delta * hmm * sin(deg2rad(a * 90))
    var pitch_ = pitch_scale * delta_v * 0.5
#    if abs(pitch_) > 0.1:
#        if not swing.playing:
#            swing.play()
#            humm.stop()
#    else:
#        swing.stop()
#        if not humm.playing:
#            humm.play()
#    if abs(pitch_) > 0.2: print(pitch_)

#    var new_scale = min(1, lerp(1, 3, pitch_scale))#pow(pitch_scale, 1))
#    print(pitch_scale)
#    var vol_db = min(5, pitch_scale) # max((pitch_scale * pitch_scale), 1)
#    if vol_db > 1:
#        print(vol_db)
#    print(pitch_)
#    pitch_shift_effect.pitch_scale = 1 - pitch_
#    amp_effect.volume_db = 1 - pitch_ * 2


func humm(is_play):
    var sounds = [
        $AudioStream_Humm
    #,   $AudioStream_Swing
    ]
    var playing = play_all(sounds, is_play) if (is_play != self.humming) else false
    humming = playing
    return playing

func is_humming():
    var playing = $AudioStream_Humm.playing
    return playing

func get_max_length():
    if hilt:
        return hilt.blade_length
    else:
        return max_length

func get_max_width():
    if hilt:
        return hilt.blade_width
    else:
         return max_width

func get_fluct():
    return fluctuation

func set_length(length_):
    var length__ = length_ * SCALE_FACTOR
    self.scale.y = length__

    # Adjust visibility and position of blade based on its length
    self.visible = length__ > 0
    self.translation = Vector3(0, length__, 0)

    $Glow.translation.y = length__ / 2
    length = length__

func get_length():
    return self.scale.y / SCALE_FACTOR

func set_width(width_):
    var width__ = width_ * SCALE_FACTOR
    self.scale.x = width__
    self.scale.z = width__
    width = width__

func get_width():
    return self.scale.x / SCALE_FACTOR


func _on_AudioStream_Ignite_finished():
    pass


func _on_AudioStream_Retract_finished():
    humm(false)


func ignite():
    $AudioStream_Ignite.play()
    humm(true)

func retract():
    if not $AudioStream_Retract.playing:
        $AudioStream_Retract.play()


func blade_fluct(delta):
    var roll = randf() < self.fluctuation_hz * delta
    if roll:
        var gauss = abs(gaussian())
        var inset = self.fluctuation * gauss
        var width__ = self.max_width - inset
        self.width = width__


# Position streams along the length of the blade
# and set them to play or stop playing.
func play_all(streams, is_play):
    var streams_c = streams.size()
    var not_empty = streams_c > 0
    if not_empty:
        var i = 0
        for s in streams:
            if is_play:
                var bl_len = self.scale.y
                var spacing = bl_len / streams_c
                s.translation.y = i * (spacing - (bl_len / 2))
                i += 1
            set_stream_play(s, is_play)

        humming = is_play

    return not_empty and is_play


func set_stream_play(stream, is_play):
    var playing = stream.playing
    if is_play and not playing:
        stream.play()
    elif not is_play and playing:
        stream.stop()


static func gaussian(mean=0, std_dev=1):
    var u = 0
    var v = 0
    var s = 0

    while s >= 1.0 or s == 0:
        u = 2.0 * randf() - 1.0
        v = 2.0 * randf() - 1.0
        s = u * u + v * v

    var s_ = sqrt(-2.0 * log(s) / s)
    return mean + std_dev * u * s_
