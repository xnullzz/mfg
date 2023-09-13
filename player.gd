extends CharacterBody3D

#start load_game_objects
@onready var head = $head
@onready var standing_colision_shape = $standing_colision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var ray_cast_3d = $RayCast3D
#end load_game_objects

#start player_vars
var current_speed : float = 5.0
var walking_speed : float = 5.0
var sprint_speed : float = 8.0
var crouch_speed : float = 3.0
const jump_velocity : float = 4.5
const mouse_sens : float = 0.15
var lerp_speed : float = 10.0
var direction : Vector3 = Vector3.ZERO
var crouching_depth : float = 0.5
var is_running : bool = false
var is_crouching : bool = false
#end player_vars

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _is_colliding() -> bool:
	return ray_cast_3d.is_colliding()

func _physics_process(delta: float) -> void:
	_crouch(delta)
	_sprint()
	_move(delta)
	_jump(delta)
	
func _crouch(delta: float) -> void:
	if Input.is_action_pressed("crouch") && is_on_floor():
		current_speed = crouch_speed
		head.position.y = lerp(head.position.y, 1.8 - crouching_depth, delta * lerp_speed)
		standing_colision_shape.disabled = true
		crouching_collision_shape.disabled = false
		is_crouching = true
	elif !Input.is_action_pressed("crouch") and !_is_colliding():
		current_speed = walking_speed
		standing_colision_shape.disabled = false
		crouching_collision_shape.disabled = true
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		is_crouching = false

func _sprint() -> void:
	if Input.is_action_pressed("sprint") && !is_crouching:
		current_speed = sprint_speed

# Handle Jump.
func _jump(delta: float) -> void:
	# Add gravity.
	if !is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("ui_accept") && !_is_colliding() && !is_crouching:
		velocity.y = jump_velocity

# Get the input direction and handle movement/deceleration.
func _move(delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)

	match direction:
		direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		_:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
