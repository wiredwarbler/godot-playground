extends CharacterBody2D

# Visible Settings
@export var move_speed : float = 100.00;
@export var run_multiplier : float = 1.4;
@export var starting_direction: Vector2 = Vector2(0, 1); # based on the sprites

var idle_path: String = "parameters/Idle/blend_position";
var walking_path: String = "parameters/Walking/blend_position";

@onready var animation_tree = $AnimationTree; # $ references AnimationTree

func _ready():
	update_animation_parameters(starting_direction);

func _physics_process(delta):
	# movement tl;dr:
	# # # # # #
	#    -    #
	# -     + #
	#    +    #
	# # # # # #
	
	# todo: how else might movement be changed?
	# (1) check for different other kinds of input? how would you jump?
	
	# get input direction
	var input_direction = Vector2(
		# positive value = move right, negative value = move left
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		# positive value = move down, negative value = move up
		Input.get_action_strength("down") - Input.get_action_strength("up")
	);
	
	update_animation_parameters(input_direction);
	
	#print(input_direction)
	var moveModifier : float = 1 if Input.get_action_strength("ctrl") != 1 else run_multiplier;
	
	# update velocity
	velocity = input_direction * move_speed * moveModifier;
	
	# move and slide function uses velocity of character body to move on the map
	move_and_slide();
	#move_and_collide();
	

func update_animation_parameters(move_input: Vector2):
	if (move_input != Vector2.ZERO):
		animation_tree.set(walking_path, move_input);
		animation_tree.set(idle_path, move_input);
	
