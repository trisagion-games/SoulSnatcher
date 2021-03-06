extends Actor
class_name Player

export (NodePath) var player_light_object_path
export (NodePath) var player_sprite_object_path
export (NodePath) var player_animated_sprite_object_path


enum ATTACK_STATE {NEUTRAL, DASHING, DASHED}
enum DASH_STATE {DASHING1, DASHING2, DASHING3}

var vertical_input_strength
var horizontal_input_strength
var current_vertical_speed = Vector2(0, 0)
var current_horizontal_speed = Vector2(0, 0)
var direction
var mouse_direction
var attack_state = ATTACK_STATE.NEUTRAL
var slash_charges = 2
var time = 0
var total_soul_count = 0
var frame_freeze_requested = false;

var dash_trail = load("res://Assets/src/DashTrail.tscn")
var dash_audio = load("res://Assets/src/DashAudio.tscn")
var dash_hit_audio = load("res://Assets/src/DashHitAudio.tscn")
var hit_confirm = load("res://Assets/src/HitConfirm.tscn")

export var current_luminence = 100
export var speed:= 500
export var drag_weight:= 10
export var dash_start_time:= 0.08
export var dash_hide_time := 0.2
export var light_scale_min:= 0
export var light_scale_max:= 3
export var luminence_reduction_rate:= 0.1
export var max_luminence:= 100
export var max_dash_charges:= 2
export var charge_time:= 2
export var path_to_end_game:= "res://Assets/src/DeathScreen.tscn"
export var attack_chain_count:= 0
export var attack_chain_cooldown:= 0.0
export var attack_chain_max_cooldown:= 1.0
export var attack_chain_decrease:= 0.015

export(Texture) var character_up
export(Texture) var character_down
export(StreamTexture) var crosshair_0
export(StreamTexture) var crosshair_1
export(StreamTexture) var crosshair_2

onready var player_light = get_node(player_light_object_path)
# onready var player_sprite = get_node(player_sprite_object_path)
onready var player_animated_sprite = get_node(player_animated_sprite_object_path)

signal dash_signal
signal cursor_signal
signal frame_freeze_requested


func get_current_luminence(): return current_luminence/max_luminence
func get_total_soul_count(): return total_soul_count
func get_current_attack_chain(): return attack_chain_count
func get_attack_chain_cooldown(): return attack_chain_cooldown / attack_chain_max_cooldown

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	charge_dash(delta)
	cursor_udpate()
	
	

func _physics_process(delta):
	if (Engine.time_scale > 0):
		if (current_luminence >= 0):
			current_luminence -= luminence_reduction_rate
		else:
			get_tree().change_scene(path_to_end_game)
		player_light.set_texture_scale( (current_luminence/max_luminence)*light_scale_max )
		if(attack_state != ATTACK_STATE.DASHING):
			movement(delta)
		if (attack_chain_cooldown > 0):
			attack_chain_cooldown -= attack_chain_decrease
		else:
			attack_chain_count = 0
			attack_chain_cooldown = 0
		# print( get_viewport().get_mouse_position() )

func movement(delta):
	if (Input.get_action_strength("Up") > 0):
		player_animated_sprite.play("reaper_up")
	if (Input.get_action_strength("Down") > 0):
		player_animated_sprite.play("reaper_down")
	vertical_input_strength = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	horizontal_input_strength = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	direction = Vector2(horizontal_input_strength, vertical_input_strength).normalized()
	velocity = velocity.linear_interpolate( direction*speed, delta*drag_weight )

func dash():
	var radians = get_angle_to(get_global_mouse_position())
	if (sin(radians) > 0): 
		player_animated_sprite.play("reaper_down_blade")
	else: 
		player_animated_sprite.play("reaper_up_blade")

	var dash_trail_instance = dash_trail.instance()
	var dash_audio_instance = dash_audio.instance()
	dash_trail_instance.set_rotation(radians)
	dash_trail_instance.set_position( position + Vector2(cos(radians), sin(radians)) * 200)
	dash_audio_instance.set_position( position )
	get_parent().add_child(dash_trail_instance)
	yield(get_tree().create_timer(dash_start_time), "timeout")
	get_parent().add_child(dash_audio_instance)
	# Make Player dissappear for a second
	player_animated_sprite.visible = false
	yield(get_tree().create_timer(dash_hide_time), "timeout")
	# Make Player reappear at location
	player_animated_sprite.visible = true
	# Pan camera to Player
	emit_signal("dash_signal")
	if (sin(radians) > 0): 
		player_animated_sprite.play("reaper_down")
	else: 
		player_animated_sprite.play("reaper_up")
	print(cos(radians))
	position += Vector2(cos(radians), sin(radians)) * 400
	attack_state = ATTACK_STATE.NEUTRAL
	
	frame_freeze_requested = false
	# position += get_angle_to(get_global_mouse_position())
	
func charge_dash(delta):
	if (slash_charges >= max_dash_charges):
		slash_charges = max_dash_charges
		time = 0
	else:
		time += delta
	if (slash_charges < max_dash_charges and time >= charge_time):
		print("Charged")
		slash_charges += 1
		time = 0
		
func cursor_udpate():
	match slash_charges:
		0:
			emit_signal("cursor_signal", crosshair_0)
		1:
			emit_signal("cursor_signal", crosshair_1)
		2:
			emit_signal("cursor_signal", crosshair_2)

func increase_luminence(quantity):
	total_soul_count += 1
	current_luminence += quantity
	if (current_luminence > max_luminence):
		current_luminence = max_luminence

func on_DashCast_function(objectHit):
	if (attack_state != ATTACK_STATE.DASHING and slash_charges > 0):
		slash_charges -= 1
		attack_state = ATTACK_STATE.DASHING
		dash()
	if(objectHit.size() != 0 and attack_state == ATTACK_STATE.DASHING): 
		# print("Enemy Hit")
		print(objectHit)
		var hit_played = false;
		for oh in objectHit:
			var dash_hit_audio_instance = dash_hit_audio.instance()
			var hit_confirm_instance = hit_confirm.instance()
			dash_hit_audio_instance.set_position( position )
			if (oh != null): hit_confirm_instance.set_position( oh.position )
			
			get_parent().add_child(hit_confirm_instance)
			attack_chain_count += 1
			attack_chain_cooldown = attack_chain_max_cooldown
			# legacy code do not touch magic box
			if (true):
				get_parent().add_child(dash_hit_audio_instance)
				hit_played = true
			yield(get_tree().create_timer(0.1), "timeout")
			if !frame_freeze_requested:
				print("Requested")
				emit_signal("frame_freeze_requested")
				frame_freeze_requested = true
			if (oh != null): oh.die()
		slash_charges += 1


func is_dashing():
	return attack_state == ATTACK_STATE.DASHING

func _on_DashCast_dashPressed(objectHit):
	on_DashCast_function(objectHit)
