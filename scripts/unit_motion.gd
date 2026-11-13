extends Node3D
## M4: clips Walk / Idle dos personagens GLB com animação de formação e estandarte.

var marching: bool = false
var _clock: float = 0.0
var _soldiers: Array[Node3D] = []
var _banner: Node3D
var _players: Array[AnimationPlayer] = []


func _ready() -> void:
    _soldiers.clear()
    for child in get_children():
        if child is Node3D and str(child.name).begins_with("Soldado_"):
            _soldiers.append(child as Node3D)
    _banner = get_node_or_null("Estandarte") as Node3D
    _players.clear()
    for node in find_children("*", "AnimationPlayer", true, false):
        if node is AnimationPlayer:
            _players.append(node as AnimationPlayer)
    _play_clip("Idle")


func _play_clip(clip: String) -> void:
    for player in _players:
        for name in player.get_animation_list():
            if str(name).to_lower().ends_with(clip.to_lower()):
                var animation: Animation = player.get_animation(name)
                if animation != null:
                    animation.loop_mode = Animation.LOOP_LINEAR
                player.play(name)
                break


func get_imported_animator_count() -> int:
    return _players.size()


func _process(delta: float) -> void:
    _clock += delta * (13.0 if marching else 2.0)
    var energy: float = 0.10 if marching else 0.018
    for i in range(_soldiers.size()):
        var soldier: Node3D = _soldiers[i]
        soldier.position.y = sin(_clock + float(i) * 1.7) * energy
        soldier.rotation.x = sin(_clock + float(i) * 1.7) * energy * 0.50
    if _banner != null:
        _banner.rotation.z = sin(_clock * 0.67) * 0.055
        _banner.rotation.x = sin(_clock * 0.41) * 0.025


func begin_march() -> void:
    marching = true
    _play_clip("Walk")


func end_march() -> void:
    marching = false
    _play_clip("Idle")
