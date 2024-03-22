extends CharacterBody3D

const SPEED :float = 5.0
const JUMP_VELOCITY :float = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/defualt_gravity")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	
	var input_dir := Input.get_vector("move_left", "move_right","move_forward","move_back")
	var direction :Vector3= (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.y = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
