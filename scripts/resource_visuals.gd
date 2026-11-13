extends RefCounted
## M11: iconografia 3D de recursos usando apenas cinco instâncias MultiMesh.

const TYPES: Array[String] = ["wheat", "iron", "horses", "timber", "fish"]
const COLORS: Dictionary = {
    "wheat": Color("#e6c27c"), "iron": Color("#a9b5ba"),
    "horses": Color("#bb9063"), "timber": Color("#68ae7b"), "fish": Color("#73c7d1")
}


static func make(tiles: Dictionary) -> Node3D:
    var root: Node3D = Node3D.new()
    root.name = "Recursos"
    for kind in TYPES:
        var positions: Array[Vector3] = []
        for cell in tiles:
            var tile: Dictionary = tiles[cell]
            if str(tile.get("resource", "")) == kind:
                positions.append(tile["position"] + Vector3(0.0, 0.43, 0.0))
        if positions.is_empty():
            continue
        var prism: CylinderMesh = CylinderMesh.new()
        prism.top_radius = 0.0 if kind in ["wheat", "timber"] else 0.16
        prism.bottom_radius = 0.18 if kind in ["wheat", "timber"] else 0.15
        prism.height = 0.47
        prism.radial_segments = 6
        var batch: MultiMesh = MultiMesh.new()
        batch.transform_format = MultiMesh.TRANSFORM_3D
        batch.mesh = prism
        batch.instance_count = positions.size()
        for i in range(positions.size()):
            batch.set_instance_transform(i, Transform3D(Basis(), positions[i]))
        var visual: MultiMeshInstance3D = MultiMeshInstance3D.new()
        visual.name = "Deposito_%s" % kind
        visual.multimesh = batch
        var mat: StandardMaterial3D = StandardMaterial3D.new()
        mat.albedo_color = COLORS[kind]
        mat.roughness = 0.72
        visual.material_override = mat
        visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        root.add_child(visual)
    return root
