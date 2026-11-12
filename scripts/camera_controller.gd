extends Node3D
## Câmara 2.5D estável: ângulo constante independente do recentramento.

@export var pan_speed: float = 27.0
@export var zoom_min: float = 15.0
@export var zoom_max: float = 95.0

@onready var camera: Camera3D = $Camera3D
var _dragging: bool = false
var _limit_x: float = 65.0
var _limit_z: float = 55.0


func _ready() -> void:
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 27.0
    camera.far = 450.0
    camera.position = Vector3(0.0, 47.0, 34.0)
    camera.rotation_degrees = Vector3(-54.0, 0.0, 0.0)
    camera.current = true


func center_on(point: Vector3) -> void:
    position = Vector3(point.x, 0.0, point.z)
    _clamp_position()


func set_limits(width: float, depth: float) -> void:
    _limit_x = width * 0.68
    _limit_z = depth * 0.70
    center_on(Vector3.ZERO)


func _process(delta: float) -> void:
    var move_vector: Vector3 = Vector3.ZERO
    var right: Vector3 = camera.global_transform.basis.x
    var forward: Vector3 = -camera.global_transform.basis.z
    right.y = 0.0
    forward.y = 0.0
    right = right.normalized()
    forward = forward.normalized()
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        move_vector -= right
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        move_vector += right
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        move_vector += forward
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        move_vector -= forward
    if move_vector.length_squared() > 0.0:
        position += move_vector.normalized() * pan_speed * camera.size / 36.0 * delta
        _clamp_position()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event
        if mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera.size = clampf(camera.size / 1.12, zoom_min, zoom_max)
        elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera.size = clampf(camera.size * 1.12, zoom_min, zoom_max)
        elif mouse.button_index == MOUSE_BUTTON_MIDDLE:
            _dragging = mouse.pressed
    elif event is InputEventMouseMotion and _dragging:
        var motion: InputEventMouseMotion = event
        var right: Vector3 = camera.global_transform.basis.x
        var forward: Vector3 = -camera.global_transform.basis.z
        right.y = 0.0
        forward.y = 0.0
        var scale_factor: float = camera.size / maxf(1.0, get_viewport().get_visible_rect().size.y)
        position -= right.normalized() * motion.relative.x * scale_factor
        position += forward.normalized() * motion.relative.y * scale_factor
        _clamp_position()


func _clamp_position() -> void:
    position.x = clampf(position.x, -_limit_x, _limit_x)
    position.z = clampf(position.z, -_limit_z, _limit_z)
