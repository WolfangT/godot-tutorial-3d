extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
# rotation speed in rads/s
@export var rotation_speed = PI*1.5
# rotation speed for pitch in rads/s
@export var pitch_speed = PI*2
# Vertical impulse applied to the character upon jumping in meters per second.
@export var jump_impulse = 20
# Vertical impulse applied to the character upon bouncing over a mob in
# meters per second.
@export var bounce_impulse = 16

var target_velocity = Vector3.ZERO
var current_direction = Vector3.FORWARD
var current_pitch = 0

func _physics_process(delta):
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

    if direction != Vector3.ZERO:
        direction = direction.normalized()
        if direction != current_direction:
            var angle = current_direction.signed_angle_to(direction, Vector3.UP)
            var current_rotation = angle if abs(angle) <= rotation_speed*delta else rotation_speed*delta*sign(angle)
            current_direction = current_direction.rotated(Vector3.UP, current_rotation)

        # Setting the basis property will affect the rotation of the node.
        $Pivot.basis = Basis.looking_at(current_direction)
    
    # Ground Velocity
    target_velocity.x = direction.x * speed
    target_velocity.z = direction.z * speed

    # Vertical Velocity
    if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
        target_velocity.y = target_velocity.y - (fall_acceleration * delta)
    
    # Jumping
    if is_on_floor() and Input.is_action_just_pressed("jump"):
        target_velocity.y = jump_impulse
    
    # Animation 
    if is_on_floor():

    
    for index in range(get_slide_collision_count()):
        var collision = get_slide_collision(index)
        if collision.get_collider() == null:
            continue
        if collision.get_collider().is_in_group("mob"):
            var mob = collision.get_collider()
            if Vector3.UP.dot(collision.get_normal()) > 0.3:
                mob.squash(bounce_impulse)
                target_velocity.y = bounce_impulse
                break


    # Moving the Character
    velocity = target_velocity
    move_and_slide()
