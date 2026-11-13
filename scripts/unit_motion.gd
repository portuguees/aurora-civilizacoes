extends Node3D
## Animação original dos pequenos grupos militares.
## Sem skeleton externo: os personagens oscilam em grupo ao marchar e o estandarte
## mexe-se suavemente mesmo quando estão parados.

var marching: bool = false
var _clock: float = 0.0
var _soldiers: Array[Node3D] = []
var _banner: Node3D


func _ready() -> void:
    _soldiers.clear()
    for child in get_children():
        if child is Node3D and str(child.name).begins_with("Soldado_"):
            _soldiers.append(child)
    _banner = get_node_or_null("Estandarte") as Node3D


func _process(delta: float) -> void:
    _clock += delta * (13.0 if marching else 2.0)
    var energy: float = 0.11 if marching else 0.021
    for i in range(_soldiers.size()):
        var soldier: Node3D = _soldiers[i]
        soldier.position.y = sin(_clock + float(i) * 1.7) * energy
        soldier.rotation.x = sin(_clock + float(i) * 1.7) * energy * 0.55
    if _banner != null:
        _banner.rotation.z = sin(_clock * 0.67) * 0.055
        _banner.rotation.x = sin(_clock * 0.41) * 0.025


func begin_march() -> void:
    marching = true


func end_march() -> void:
    marching = false
