extends CharacterBody3D

# Emitted when the player was hit by a mob.
# Put this at the top of the script.
signal hit
signal jump
signal squashed()

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
# rotation speed in rads/s
@export var rotation_speed = PI * 2
# Vertical impulse applied to the character upon jumping in meters per second.
@export var jump_impulse = 20
# Vertical impulse applied to the character upon bouncing over a mob in
# meters per second.
@export var bounce_impulse = 16

var target_velocity = Vector3.ZERO
var current_direction = Vector3.FORWARD
var current_pitch = 0
var last_y_velocity = 0
var alive = true
var get_multiplayer_authority_id: int
# Online Sync
var syncPos: Vector3
var syncRot: Basis

func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(get_multiplayer_authority_id)

func _physics_process(delta):
	if not $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		global_position = global_position.lerp(syncPos, 0.5)
		$Pivot.basis.x = $Pivot.basis.x.lerp(syncRot.x, 0.5)
		$Pivot.basis.y = $Pivot.basis.y.lerp(syncRot.y, 0.5)
		$Pivot.basis.z = $Pivot.basis.z.lerp(syncRot.z, 0.5)
		return
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO
	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		# Notice how we are working with the vector's x and z axes.
		# In 3D, the XZ plane is the ground plane.
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	if direction != Vector3.ZERO or target_velocity.y != last_y_velocity:
		# Get XZ rotation 
		direction = direction.normalized()
		if direction != Vector3.ZERO and direction != current_direction:
			var angle = current_direction.signed_angle_to(direction, Vector3.UP)
			var current_rotation = angle if abs(angle) <= rotation_speed * delta else rotation_speed * delta * sign(angle)
			current_direction = current_direction.rotated(Vector3.UP, current_rotation)
			$AnimationPlayer.speed_scale = 4
		else:
			$AnimationPlayer.speed_scale = 1
		if target_velocity.y != last_y_velocity:
			current_pitch = atan(target_velocity.y / jump_impulse)
			last_y_velocity = position.y
		# Setting the basis property will affect the rotation of the node.
		$Pivot.basis = Basis.looking_at(current_direction.rotated(current_direction.cross(Vector3.UP), current_pitch))
	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y -= (fall_acceleration * delta)
	else:
		target_velocity.y = 0
	# Jumping
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse
		jump.emit()
	# Check Collisions
	for index in range(get_slide_collision_count()):
		var collision = get_slide_collision(index)
		if collision.get_collider() == null:
			continue
		if collision.get_collider().is_in_group("mob"):
			var mob = collision.get_collider()
			if Vector3.UP.dot(collision.get_normal()) > 0.3:
				mob.squash.rpc(bounce_impulse, multiplayer.get_unique_id())
				target_velocity.y = bounce_impulse
				break
		elif collision.get_collider().is_in_group("players"):
			var player = collision.get_collider()
			if Vector3.UP.dot(collision.get_normal()) > 0.3:
				player.squash(multiplayer.get_unique_id())
				target_velocity.y = bounce_impulse
				break
	# Moving the Character
	syncPos = global_position
	syncRot = $Pivot.basis
	velocity = target_velocity
	move_and_slide()


# And this function at the bottom.
@rpc("any_peer", "call_local")
func die():
	alive = false
	hit.emit()

func _on_mob_detector_body_entered(_body: Node3D) -> void:
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		die.rpc()

func squash(player_id):
	squashed.emit(player_id, get_multiplayer_authority_id)