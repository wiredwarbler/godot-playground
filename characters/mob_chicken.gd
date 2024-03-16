extends CharacterBody2D

# for help with typing:
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html

# Exposed Settings #
@export var move_speed: float = 75.00;
@export var starting_direction: Vector2 = Vector2(-1, 0); # based on the sprites
@export var idle_state_name: String = "Idle";
@export var move_cooldown: float = 2.5;
@export var move_cooldown_variance: float = 1.0;
@export var walk_state_name: String = "Walking";
@export var move_duration: float = 2.5;
@export var move_duration_variance: float = 1.5; # todo: use this to alter the time spent moving

# On Ready - Child Node Properties #
@onready var animation_tree: AnimationTree = $AnimationTree;
@onready var state_machine = animation_tree.get("parameters/playback");
@onready var sprite: Sprite2D = $Sprite2D;
#@onready var collision = $CollisionShape2D;

# State Configuration #
enum CHICKEN_STATE { IDLE = 0, WALKING = 1, RESTING = 2 }
var states: Dictionary;
var active_state: ChickenState;
var facing_options: Array[int] = [-1, 1];
var direction_options: Array[int] = [-1, 0, 1];

var movement_is_queued: bool = false;
var queued_movement: Vector2;

# Helper Classes #
class ChickenState:
	# Constants #
	const BLEND_PATH_FORMAT: String = "parameters/%s/blend_position";
	# Configuration Properties #
	var id: int;
	var name: String;
	var is_active: bool = false;
	var animation_path: String;
	# Time Properties #
	var max_duration: float = 0.0;
	var duration_variance: float = 0.0;
	var duration: float = 0.0;
	
	# Constructor
	func _init(i: int, n: String, md: float, dv: float = 0.0) -> void:
		id = i;
		name = n;
		max_duration = md;
		duration_variance = dv;
		animation_path = BLEND_PATH_FORMAT % name;
	
	# Class Functions
	func activate() -> void:
		is_active = true;
		duration = max_duration;
	func deactivate() -> void:
		is_active = false;
		duration = 0;
	func update_duration(time_taken: float) -> float:
		# duration must never be allowed to be negative
		duration -= time_taken if time_taken < duration else duration;
		return duration;
	func reset_duration() -> float:
		duration = max_duration;
		return duration;
	func duration_expired() -> bool:
		return duration == 0.0;
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

func _ready():
	# Initialize
	setup();
	update_animation_parameters(starting_direction);

func setup():
	var idle = ChickenState.new(CHICKEN_STATE.IDLE, idle_state_name, move_cooldown);
	var walking = ChickenState.new(CHICKEN_STATE.WALKING, walk_state_name, move_duration, move_duration_variance);
	states = { idle.id: idle, walking.id: walking };
	activate_state(idle.id);

func _process(delta: float):
	# note: delta is the number of seconds since the last _process function call
	match active_state.id:
		CHICKEN_STATE.IDLE:
			if (active_state.duration_expired()):
				print("CHICKEN: STATE UPDATE");
				var facing: int = facing_options.pick_random();
				queued_movement = Vector2(facing, 0);
				movement_is_queued = true;
				active_state.reset_duration();
			else:
				active_state.update_duration(delta);
		CHICKEN_STATE.WALKING:
			## todo: generate a new movement
			## https://docs.godotengine.org/en/stable/classes/class_array.html#class-array-method-pick-random
			#var x_movement: int = direction_options.pick_random();
			#var y_movement: int = direction_options.pick_random();
			pass;
		_:
			print("CHICKEN: _process() ERROR!");
	# todo: may be able to reverse this process' logic: check if a timer has expired FIRST, then pick a new state if it has

func _physics_process(delta):
	match active_state.id:
		CHICKEN_STATE.IDLE:
			if (movement_is_queued):
				update_animation_parameters(queued_movement);
				movement_is_queued = false;
		#CHICKEN_STATE.WALKING:
			#if (movement_is_queued && ):
				#pass;
		_:
			pass;

func update_animation_parameters(move_input: Vector2) -> void:
	if (move_input != Vector2.ZERO && active_state != null):
		# manually update the x-axis (left-right) facing
		set_facing(move_input);
		animation_tree.set(active_state.animation_path, move_input);

func activate_state(state_id: CHICKEN_STATE) -> void:
	var next_state: ChickenState = states.get(state_id);
	# Deactive previous state, if it exists
	if (active_state != null):
		active_state.deactivate();
	# Set and activate the new state
	active_state = next_state;
	active_state.activate();

# todo: use this function instead of lines 87-92 to do the following:
# (1) pick a new state and activate it
# (2) configure the next movement based on the new state
# (3) queue the movement/Vector2 to be used
#func set_next_state() -> void:
	#var next_state: ChickenState = states.get(states.keys().pick_random());
	#activate_state(next_state.id);
	#

func set_facing(move_input: Vector2) -> void:
	# Due to how simple the chicken's spritesheet is, I'm electing to make use of
	# the sprite.flip_h to flip the sprite around instead of using the BlendSpace2D.
	if (move_input.x != 0):
		# Vector2( right - left, down - up )
		sprite.flip_h = move_input.x < 0;

func get_state(state_id: CHICKEN_STATE) -> ChickenState:
	return states.get(state_id);
