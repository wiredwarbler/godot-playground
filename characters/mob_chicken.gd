extends CharacterBody2D

# for help with typing:
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html

# Exposed Settings #
@export var move_speed: float = 40.00;
@export var starting_direction: Vector2 = Vector2(-1, 0); # based on the sprites
@export var idle_state_name: String = "Idle";
@export var idle_duration: float = 2.5;
@export var idle_duration_variance: float = 0.75;
@export var walk_state_name: String = "Walking";
@export var move_duration: float = 2.5;
@export var move_duration_variance: float = 1.5; # todo: use this to alter the time spent moving

# On Ready - Child Node Properties #
@onready var animation_tree: AnimationTree = $AnimationTree;
@onready var state_machine = animation_tree.get("parameters/playback");
@onready var sprite: Sprite2D = $Sprite2D;
@onready var collision = $CollisionShape2D;

# State Configuration #
enum CHICKEN_STATE { IDLE = 0, WALKING = 1, RESTING = 2 }
var states: Dictionary;
var active_state: ChickenState;
var rand_gen: RandomNumberGenerator;
var facing_options: Array[int] = [-1, 1];
var direction_options: Array[int] = [-1, 0, 1];

var active_movement: Vector2 = Vector2.ZERO;

# Helper Classes #
class ChickenState:
	# Constants #
	const BLEND_PATH_FORMAT: String = "parameters/%s/blend_position";
	# Configuration Properties #
	var id: int;
	var name: String;
	var is_active: bool = false;
	var animation_path: String;
	# Time/Movement Properties #
	var default_duration: float = 0.0;
	var duration_variance: float = 0.0;
	var variant_duration: float = 0.0;
	var duration: float = 0.0;
	var is_moving_state: bool = false;
	
	# Constructor
	func _init(i: int, n: String, dd: float, dv: float = 0.0, ims: bool = false) -> void:
		id = i;
		name = n;
		default_duration = dd;
		duration_variance = dv;
		animation_path = BLEND_PATH_FORMAT % name;
		is_moving_state = ims;
	
	# Class Functions
	func activate() -> void:
		is_active = true;
		#duration = default_duration;
		reset_duration();
	func deactivate() -> void:
		is_active = false;
		duration = 0;
	func update_duration(time_taken: float) -> float:
		# duration must never be allowed to be negative
		duration -= time_taken if time_taken < duration else duration;
		return duration;
	func set_variant_duration(vd: float) -> void:
		variant_duration = vd;
	func reset_duration() -> float:
		duration = variant_duration if variant_duration != 0 else default_duration;
		return duration;
	func duration_expired() -> bool:
		return duration == 0.0;
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

func _ready():
	# Initialize
	setup();
	update_animation_parameters(starting_direction);

func setup():
	rand_gen = RandomNumberGenerator.new();
	rand_gen.seed = hash("CHICKEN");
	
	var idle = ChickenState.new(CHICKEN_STATE.IDLE, idle_state_name, idle_duration, idle_duration_variance);
	var walking = ChickenState.new(CHICKEN_STATE.WALKING, walk_state_name, move_duration, move_duration_variance, true);
	states = { idle.id: idle, walking.id: walking };
	activate_state(idle.id);

func _process(delta: float):
	# note: delta is the number of seconds since the last _process function call
	if (active_state != null && active_state.duration_expired()):
		print("CHICKEN %s: STATE UPDATE" % get_instance_id());
		set_next_random_state();
		print(" -> SETTING TO %s" % active_state.name);
		print(" -> FOR %s (sec)" % active_state.duration);
	elif (active_state != null):
		active_state.update_duration(delta);

func _physics_process(delta):
	update_animation_parameters(active_movement);
	velocity = active_movement * move_speed;
	move_and_slide();
	set_next_animation_state();

func update_animation_parameters(move_input: Vector2) -> void:
	if (move_input != Vector2.ZERO && active_state != null):
		# manually update the x-axis (left-right) facing
		set_facing(move_input);
		animation_tree.set(active_state.animation_path, move_input);

func set_next_animation_state() -> void:
	state_machine.travel(active_state.name)

func get_state(state_id: CHICKEN_STATE) -> ChickenState:
	return states.get(state_id);
	
func activate_state(state_id: CHICKEN_STATE) -> void:
	var next_state: ChickenState = states.get(state_id);
	next_state.reset_duration();
	# Deactive previous state, if it exists
	if (active_state != null):
		active_state.deactivate();
	# Set and activate the new state
	active_state = next_state;
	active_state.activate();

func set_next_random_state() -> void:
	# (1) Pick a new state
	var next_state: ChickenState = states.get(states.keys().pick_random());
	next_state.set_variant_duration(get_random_duration(next_state.default_duration, next_state.duration_variance));
	# (2) Configure the next movement based on the new state
	active_movement = get_random_vector() if next_state.is_moving_state else Vector2.ZERO;
	activate_state(next_state.id);

func get_random_vector() -> Vector2:
	var x: int = direction_options.pick_random();
	var y: int = direction_options.pick_random();
	return Vector2(x,y);

func get_random_duration(max_duration: float, variance: float = 0) -> float:
	var duration: int = max_duration;
	if (variance != 0 && variance < max_duration && rand_gen != null):
		duration += rand_gen.randf_range(-1 * variance, variance);
	return duration;
	#ternary version:
	#return max_duration + rand_gen.randf_range(-1 * variance, variance) if (variance != 0 && rand_gen != null) else max_duration;

func set_facing(move_input: Vector2) -> void:
	# Due to how simple the chicken's spritesheet is, I'm electing to make use of
	# the sprite.flip_h to flip the sprite around instead of using the BlendSpace2D.
	if (move_input.x != 0):
		# Vector2( right - left, down - up )
		sprite.flip_h = move_input.x < 0;
