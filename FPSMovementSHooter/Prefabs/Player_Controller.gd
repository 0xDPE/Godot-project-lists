extends CharacterBody3D

#game time
var time :float

#Speed variables
var speed_current :float = 5.0
const speed_walking :float = 5.0
const speed_sprinting :float = 8.0
const speed_crouch :float = 2.0

#states
var walking :bool = false
var sprinting :bool = false
var crouching :bool = false
var sliding :bool = false
var free_looking :bool = false
var wall_running :bool = false
var wall_jumping :bool = false
var double_jumping :bool = false

#double jump vars#
var can_double_jump :bool = false

#slide vars
var slide_vector :Vector2 = Vector2.ZERO
var slide_speed :float = 10.0

#wall run vars
var camera_rotated :bool = false
var player_hight_limit :float = 2.5

#wall jump vars
var wall_jump_push_back :float = 100
var wall_jump_vector :Vector3 = Vector3.ZERO

#last collision wall
var wall

#Timers
var slide_timer :float = 0.0
var slide_timer_max :float = 1.5
var wall_jump_timer :float = 0.0
var wall_jump_timer_max :float = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#movement vars
var crouching_depth = -0.5
var lerp_speed :float = 10.0
const velocity_jump = 4.5

#input vars
var direction :Vector3 = Vector3.ZERO
var mouse_sens :float = 0.25

#export vars
@export var accel :float = 2000.0

#Player Nodes
@onready var head := $Neck/Head
@onready var standing_collision_shape := $standing_collision_shape
@onready var crouching_collision_shape := $crouching_collision_shape
@onready var check_roof := $check_roof
@onready var neck := $Neck
@onready var camera_3d := $Neck/Head/Camera3D

#headbob vars

const head_bobbing_sprinting_speed :float = 22.0
const head_bobbing_walking_speed :float = 14.0
const head_bobbing_crouching_speed :float = 10.0

const head_bobbing_sprinting_intensity :float = 0.2
const head_bobbing_walking_intensity :float = 0.1
const head_bobbing_crouching_intensity :float = 0.05

var head_bobbing_vector :Vector2 = Vector2.ZERO
var head_bobbing_index :float = 0.0
var head_bobbing_current_intensity :float = 0.0

#On first frame
func _ready():
	#Takes control of mommy mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#on input
func _input(event):
	#mommy mouse inputs only
	if event is InputEventMouseMotion:
		#if free_looking:
		#	neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		#	neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-60), deg_to_rad(60))
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func get_sine():
	return sin(time * 1) * 1

func wall_run() -> String:
	if is_on_wall():
		if Input.is_action_pressed("sprint"):
			if Input.is_action_pressed("move_right"):
				wall = get_slide_collision(0)
				if position.y >= player_hight_limit:
					velocity.y = 0
					direction = -wall.get_normal() * speed_current
					if camera_rotated == false:
						camera_3d.rotate_z(deg_to_rad(20))
						camera_rotated = true
					wall_running = true
					return "right"
				else:
					camera_3d.rotation.z = 0
					camera_rotated = false
					return "not high enough"
			elif Input.is_action_pressed("move_left"):
				wall = get_slide_collision(0)
				if position.y >= player_hight_limit:
					velocity.y = 0
					direction = -wall.get_normal() * speed_current
					if camera_rotated == false:
						camera_3d.rotate_z(deg_to_rad(-20))
						camera_rotated = true
					wall_running = true
					return "left"
				else:
					camera_3d.rotation.z = 0
					camera_rotated = 0
					return "not high enough"
			else:
				return "no input key"
		else:
			camera_3d.rotation.z = 0
			camera_rotated = false
			wall_running = false
			return "not sprinting"
	camera_3d.rotation.z = 0
	camera_rotated = false
	wall_running = false
	return "not on wall"
#wall jumping
func wall_jump() -> String:
	if wall_running && Input.is_action_pressed("move_jump"):
		if wall_jumping == false:
			velocity = (get_wall_normal() * wall_jump_push_back)
			velocity.y = velocity_jump * 0.5
			wall_jumping = true
	if wall_jump_timer <= 0:
		wall_jumping = false
	return "wall_jumped"
#on new frame
func _physics_process(delta):
	#incriment game time
	time  += delta
	
	#get movement input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	#inputs
	if Input.is_action_pressed("crouch")  || sliding:
		if not wall_running:
			speed_current = speed_crouch
			#lerp makes movement smoother
			#moves camera down by crouching depth
			head.position.y = lerp(head.position.y,0.0 + crouching_depth, delta*lerp_speed)
			#Changes collision detection from standing hitbox to crouched hitbox
			standing_collision_shape.disabled = true
			crouching_collision_shape.disabled = false
			
			#Slide begin
			if sprinting and input_dir != Vector2.ZERO:
				sliding = true
				slide_timer = slide_timer_max
				slide_vector = input_dir
				print("slide timer begin")
			
			walking = false
			sprinting = false
			crouching = true
			
	#make sure you dont bump your head
	elif !check_roof.is_colliding():
		#smooth shit and moves camera back up
		head.position.y = lerp(head.position.y, 0.0, delta*lerp_speed)
		#changes collision detection from crouched hit box to standing
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		#very advanced sprinting logic
		#Ill accept my intern-ship at nasa now
		# get it ;) ;)
		if Input.is_action_pressed("sprint"):
			speed_current = speed_sprinting
			walking = false
			sprinting = true
			crouching = false
		else:
			speed_current = speed_walking
			walking = true
			sprinting = false
			crouching = false
			
	#Freelooking Logic
	#if Input.is_action_pressed("free_look"):
	#	free_looking = true
	#else:
	#	neck.rotation.y = lerp(neck.rotation.y, 0.0, lerp_speed*delta)
	#	free_looking = false
	
	#for some reason if this is in the function wall_jump it just fucking kills it self. why? \_(*_*)_/
	if is_on_floor():
		wall_jumping = false
		can_double_jump = false
		double_jumping = false
	wall_run()
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	if can_double_jump == false and is_on_floor():
		can_double_jump = true
	# Handle jump.
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = velocity_jump
		sliding = false
	if Input.is_action_pressed("move_jump") and can_double_jump:
		velocity.y = velocity_jump
		double_jumping = true
		can_double_jump = false
	print(wall_jumping)
	#Handle sliding
	#Also somehow handles air dashes. Was gonna implement that feature later anyways so... Guess I dont have to do that now!!
	#might change later if I want to add a level up system for dashing or something
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			print("slide timer end")
	if wall_jumping:
		wall_jump_timer -= delta
		if wall_jump_timer <= 0:
			wall_jumping = false

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerp_speed)
	
	print(wall_jump())
	
	if wall_jumping:
		direction = (transform.basis * Vector3(wall_jump_vector.x, 0, wall_jump_vector.y)).normalized()
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		
	#head bobbing logic
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
	
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed_current, accel * delta)
		velocity.z = move_toward(velocity.x, direction.z * speed_current, accel * delta)
		
		if wall_jumping:
			velocity.z = 0
		
		if sliding:
			velocity.x = direction.x * slide_timer * slide_speed
			velocity.z = direction.z * slide_timer * slide_speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed_current)
		velocity.z = move_toward(velocity.z, 0, speed_current)

	move_and_slide()
