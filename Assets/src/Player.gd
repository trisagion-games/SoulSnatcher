extends Actor
class_name Player

export (NodePath) var player_light_object_path
export (NodePath) var player_sprite_object_path

enum ATTACK_STATE {NEUTRAL, DASHING, DASHED}

var vertical_input_strength
var horizontal_input_strength
var current_vertical_speed = Vector2(0, 0)
var current_horizontal_speed = Vector2(0, 0)
var direction
var mouse_direction
var attack_state = ATTACK_STATE.NEUTRAL
var slash_charges = 2
var time = 0

export var current_luminence = 100
export var speed:= 500
export var drag_weight:= 10
export var dash_start_time:= 0.2
export var light_scale_min:= 0
export var light_scale_max:= 3
export var luminence_reduction_rate:= 0.1
export var max_luminence:= 100
export var max_dash_charges:= 2
export var charge_time:= 2

export(Texture) var character_up
export(Texture) var character_down
export(StreamTexture) var crosshair_0
export(StreamTexture) var crosshair_1
export(StreamTexture) var crosshair_2

onready var player_light = get_node(player_light_object_path)
onready var player_sprite = get_node(player_sprite_object_path)

signal dash_signal

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	charge_dash(delta)
	cursor_udpate()
	
	

func _physics_process(delta):
	if (current_luminence >= 0):
		current_luminence -= luminence_reduction_rate
	else:
		# Game Over
		print("Game Over")
	player_light.set_texture_scale( (current_luminence/max_luminence)*light_scale_max )
	if(attack_state == ATTACK_STATE.DASHING):
		pass
	else:
		movement(delta)
	# print( get_viewport().get_mouse_position() )

func movement(delta):
	if (Input.get_action_strength("Up") > 0):
		player_sprite.set_texture(character_up)
	else:
		player_sprite.set_texture(character_down)
	vertical_input_strength = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	horizontal_input_strength = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	direction = Vector2(horizontal_input_strength, vertical_input_strength).normalized()
	velocity = velocity.linear_interpolate( direction*speed, delta*drag_weight )

func dash():
	yield(get_tree().create_timer(dash_start_time), "timeout")
	emit_signal("dash_signal")
	var radians = get_angle_to(get_global_mouse_position())
	position += Vector2(cos(radians), sin(radians)) * 400
	attack_state = ATTACK_STATE.NEUTRAL
	# position += get_angle_to(get_global_mouse_position())
	
func charge_dash(delta):
	if (slash_charges == max_dash_charges):
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
			Input.set_custom_mouse_cursor(crosshair_0)
		1:
			Input.set_custom_mouse_cursor(crosshair_1)
		2:
			Input.set_custom_mouse_cursor(crosshair_2)

func _on_DashCast_dashPressed(objectHit):
	if (attack_state != ATTACK_STATE.DASHING and slash_charges > 0):
		slash_charges -= 1
		attack_state = ATTACK_STATE.DASHING
		dash()
		if(objectHit != null): 
			print("Enemy Hit")
			objectHit.die()
			slash_charges += 1
		
