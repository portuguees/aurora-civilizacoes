extends CanvasLayer
## HUD do marco M0: sempre presente, independente das unidades de M1.

@onready var world: Node3D = get_parent()
var _mini: TextureRect
var _selection: Label
var _map_label: Label


func _ready() -> void:
    _create_ui()


func _create_ui() -> void:
    var root: Control = Control.new()
    root.name = "HUD_Root"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    var header: PanelContainer = _panel(Color("#142e36ee"))
    header.anchor_right = 1.0
    header.offset_left = 16.0
    header.offset_right = -16.0
    header.offset_top = 12.0
    header.offset_bottom = 73.0
    root.add_child(header)

    var top_row: HBoxContainer = HBoxContainer.new()
    top_row.add_theme_constant_override("separation", 16)
    header.add_child(top_row)
    var name: Label = _label("A U R O R A", 23, Color("#f2d6a1"))
    top_row.add_child(name)
    top_row.add_child(_label("CIVILIZAÇÕES  ·  PRÉ-ALFA 3D", 12, Color("#c6e0dc")))
    var stretch: Control = Control.new()
    stretch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_row.add_child(stretch)
    top_row.add_child(_label("MUNDO  ·  ESTRATÉGIA  ·  EVOLUÇÃO", 12, Color("#abc6c8")))
    var new_button: Button = Button.new()
    new_button.text = "NOVO MUNDO [R]"
    new_button.pressed.connect(_new_map)
    top_row.add_child(new_button)
    var center_button: Button = Button.new()
    center_button.text = "CENTRAR"
    center_button.pressed.connect(_center)
    top_row.add_child(center_button)

    var bottom: PanelContainer = _panel(Color("#142e36ee"))
    bottom.anchor_top = 1.0
    bottom.anchor_bottom = 1.0
    bottom.offset_left = 18.0
    bottom.offset_top = -206.0
    bottom.offset_right = 292.0
    bottom.offset_bottom = -17.0
    root.add_child(bottom)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 7)
    bottom.add_child(column)
    column.add_child(_label("TERRITÓRIO EXPLORADO", 12, Color("#e9c78a")))
    _mini = TextureRect.new()
    _mini.custom_minimum_size = Vector2(250, 123)
    _mini.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _mini.stretch_mode = TextureRect.STRETCH_SCALE
    column.add_child(_mini)
    _map_label = _label("Gerando mundo...", 11, Color("#d3e0db"))
    column.add_child(_map_label)

    var selection_panel: PanelContainer = _panel(Color("#142e36ee"))
    selection_panel.anchor_left = 0.5
    selection_panel.anchor_right = 0.5
    selection_panel.anchor_top = 1.0
    selection_panel.anchor_bottom = 1.0
    selection_panel.offset_left = -270.0
    selection_panel.offset_right = 270.0
    selection_panel.offset_top = -76.0
    selection_panel.offset_bottom = -17.0
    root.add_child(selection_panel)
    var action_column: VBoxContainer = VBoxContainer.new()
    selection_panel.add_child(action_column)
    _selection = _label("Clica num hexágono para inspecionar.", 14, Color("#f0e9d8"))
    action_column.add_child(_selection)
    action_column.add_child(_label("WASD: câmara  ·  Roda: zoom  ·  Botão do meio: arrastar", 11, Color("#a9c9c9")))



func _panel(tint: Color) -> PanelContainer:
    var panel: PanelContainer = PanelContainer.new()
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = tint
    style.border_color = Color("#957b52")
    style.set_border_width_all(1)
    style.set_corner_radius_all(9)
    style.set_content_margin_all(10)
    panel.add_theme_stylebox_override("panel", style)
    return panel


func _label(value: String, size: int, tint: Color) -> Label:
    var result: Label = Label.new()
    result.text = value
    result.add_theme_color_override("font_color", tint)
    result.add_theme_font_size_override("font_size", size)
    return result


func refresh_map(source: Dictionary, width: int, height: int) -> void:
    var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
    for cell in source:
        var data: Dictionary = source[cell]
        image.set_pixel(cell.x, cell.y, data["color"])
    var texture: ImageTexture = ImageTexture.create_from_image(image)
    _mini.texture = texture
    var land: int = 0
    for cell in source:
        if not bool(source[cell]["water"]):
            land += 1
    _map_label.text = "%d hexágonos  ·  %d terra" % [source.size(), land]


func set_selection(cell: Vector2i, biome: String) -> void:
    _selection.text = "HEXÁGONO %d, %d    •    %s" % [cell.x + 1, cell.y + 1, biome.to_upper()]


func _new_map() -> void:
    world.new_map()


func _center() -> void:
    world.focus_center()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key: InputEventKey = event
        if key.pressed and not key.echo and key.keycode == KEY_R:
            _new_map()
