extends CharacterBody2D

# Exposed Settings, modifiable outside of this script file
@export var move_speed: float = 100.00;
@export var run_multiplier: float = 1.4;
@export var starting_direction: Vector2 = Vector2(0, 1); # based on the sprites

# State Names #
enum PLAYER_STATE { IDLE, WALKING, RUNNING }; # todo: implement this
# referenced as PLAYER_STATE.IDLE, PLAYER_STATE.WALKING

var idle_state: String = "Idle";
var walk_state: String = "Walking";

# Resource Paths #
var blend_path_format: String = "parameters/%s/blend_position";
var idle_path: String = blend_path_format % idle_state; # -> "parameters/Idle/blend_position";
var walk_path: String = blend_path_format % walk_state # -> "parameters/Walking/blend_position";

# On Ready #
@onready var animation_tree = $AnimationTree; # $ references associated "AnimationTree" node (could this be named anything?)
@onready var state_machine = animation_tree.get("parameters/playback");

func _ready():
	update_animation_parameters(starting_direction);

func _physics_process(delta):
	# get input direction; note that this paradigm can be changed!
	# NOTE: Vector2 has a couple of different constants that appear to have dictated this input_direction design.
	# movement tl;dr:
	  # # # # # #
	  #    -    #    Movement UP is treated as NEGATIVE (DOWN - UP)
	  # -     + #    Movement LEFT is NEGATIVE, Movement RIGHT is POSITIVE (RIGHT - LEFT) 
	  #    +    #    Movement DOWN is treated as POSITIVE (DOWN - UP)
	  # # # # # #
	var input_direction = Vector2(
		# positive value = move right, negative value = move left
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		# positive value = move down, negative value = move up
		Input.get_action_strength("down") - Input.get_action_strength("up")
	);
	# todo: how else might movement be changed?
	# (1) how might jumping be accounted for? would it be similar to sprinting? 
	# the animation tree would have to be updated, and it would likely need a new state
	
	# this multiplies movement speed by the run_multiplier to speed up movement if CTRL is held:
	# todo: find a way to update the animation to move to a sprint state; 
	var moveModifier: float = 1.0 if Input.get_action_strength("ctrl") != 1 else run_multiplier;
	
	# set the animation tree's direction based on the input direction:
	update_animation_parameters(input_direction);
	
	# update velocity: direction  * movement speed (as percent) * movement modifier
	velocity = input_direction * move_speed * moveModifier;
	
	# move and slide function uses velocity of character body to move on the map
	move_and_slide();
	#move_and_collide();
	
	# update the animation state based on the updated velocity
	set_next_animation_state();

func update_animation_parameters(move_input: Vector2):
	# todo: other params will need to be used to handle different inputs
	if (move_input != Vector2.ZERO):
		animation_tree.set(walk_path, move_input);
		animation_tree.set(idle_path, move_input);

func set_next_animation_state():
	# https://docs.godotengine.org/en/latest/tutorials/scripting/gdscript/gdscript_basics.html#match
	# use the `match` statement to switch states
	if (velocity != Vector2.ZERO): state_machine.travel(walk_state); # will this always work? what happens if travel isn't allowed?
	else: state_machine.travel(idle_state);
	# state_machine.travel(walk_state if velocity != Vector2.ZERO else idle_state); # would work if there were only ever 2 states
