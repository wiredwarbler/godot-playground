extends CharacterBody2D

# Exposed Settings
@export var move_speed: float = 75.00;
@export var starting_direction: Vector2 = Vector2(-1, 0); # based on the sprites
@export var movement_cooldown: float = 2.5;

# todo: figure an algorithm to use random numbers to figure (1) state and (2) movement, if applicable
enum CHICKEN_STATE { IDLE, WALKING, RESTING } 

var idle_state: String = "Idle";
var walk_state: String = "Walking";

var facing_array: Array[int] = [-1, 1];
var current_movement_cooldown: float = movement_cooldown;

# Resource Paths #
var blend_path_format: String = "parameters/%s/blend_position";
var idle_path: String = blend_path_format % idle_state; # -> "parameters/Idle/blend_position";
var walk_path: String = blend_path_format % walk_state # -> "parameters/Walking/blend_position";

# On Ready #
@onready var animation_tree = $AnimationTree; # $ references associated child "AnimationTree" node; name must match
@onready var state_machine = animation_tree.get("parameters/playback");
@onready var sprite = $Sprite2D;
#@onready var collision = $CollisionShape2D;

func _ready():
	# Initialize
	update_animation_parameters(starting_direction);

func _process(delta):
	# note: delta is the number of seconds since the last _process function call
	if (delta < current_movement_cooldown): 
		current_movement_cooldown -= delta;
	else:
		print("CHICKEN MOB:");
		
		# todo: generate a new movement
		# https://docs.godotengine.org/en/stable/classes/class_array.html#class-array-method-pick-random
		var facing: int = facing_array.pick_random();
		print(facing);
		var next_movement = Vector2(facing, 0);
		
		update_animation_parameters(next_movement);
		
		# then restart the timer
		current_movement_cooldown = movement_cooldown;
		#timer.start(movement_cooldown);

func update_animation_parameters(move_input: Vector2):
	# manually update the x-axis (left-right) facing
	set_facing(move_input);
	# if (move_input != Vector2.ZERO)
	animation_tree.set(idle_path, move_input);

func set_facing(move_input: Vector2):
	# Due to how simple the chicken's spritesheet is, I'm electing to make use of
	# the sprite.flip_h to flip the sprite around instead of using the BlendSpace2D.
	
	# _animated_sprite.flip_h = true # or false <- make use of this in order to flip the walking sprite
	# chicken sprites are very simple, making use of this should be a fun challenge.
	# sprite.flip_h = true;
	
	# Vector2( right - left, down - up )
	if (move_input.x != 0):
		sprite.flip_h = move_input.x < 0;
