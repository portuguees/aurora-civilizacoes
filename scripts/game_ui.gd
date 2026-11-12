extends CanvasLayer
## Interface de jogo M1. Independente da HUD do mapa; nunca esconde o núcleo.

var _game: Variant
var _turn: Label
var _summary: Label
var _resource: Label
var _found: Button
var _warrior: Button
var _unit: Button
var _end: Button


func _ready() -> void:
    _game = get_parent().get_node("Game")
    _create_ui()
    _game.state_changed.connect(_refresh)
    _refresh()


func _create_ui() -> void:
    var root: Control = Control.new()
    root.name = "InterfaceDeJogo"
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)

    var ribbon: PanelContainer = _panel()
    ribbon.position = Vector2(16, 83)
    ribbon.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    root.add_child(ribbon)
    var line: HBoxContainer = HBoxContainer.new()
    line.add_theme_constant_override("separation", 18)
    ribbon.add_child(line)
    _turn = _label("TURNO 1", 18, Color("#f3d79d"))
    line.add_child(_turn)
    _resource = _label("OURO  100   •   CIÊNCIA  0   •   PRODUÇÃO  3", 12, Color("#d6e5df"))
    line.add_child(_resource)

    var actions: PanelContainer = _panel()
    actions.anchor_left = 1.0
    actions.anchor_right = 1.0
    actions.anchor_top = 1.0
    actions.anchor_bottom = 1.0
    actions.offset_left = -355.0
    actions.offset_right = -16.0
    actions.offset_top = -335.0
    actions.offset_bottom = -102.0
    root.add_child(actions)

    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 7)
    actions.add_child(column)
    column.add_child(_label("CIVILIZAÇÃO  ·  AURORA", 15, Color("#f3d79d")))
    _summary = _label("A preparar a primeira expedição...", 12, Color("#e9f0e3"))
    column.add_child(_summary)

    _found = _button("FUNDAR CAPITAL   [F]", _game.found_city)
    column.add_child(_found)
    _unit = _button("PRÓXIMA UNIDADE   [J]", _game.next_player_unit)
    column.add_child(_unit)
    _warrior = _button("PRODUZIR GUERREIRO", _game.queue_warrior)
    column.add_child(_warrior)
    _end = _button("TERMINAR TURNO   [E]", _game.end_turn)
    column.add_child(_end)

    var controls: Label = _label("Clique esquerdo: selecionar
Clique direito: mover 1 hexágono", 11, Color("#aec7c8"))
    column.add_child(controls)


func _panel() -> PanelContainer:
    var panel: PanelContainer = PanelContainer.new()
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color("#122f39ed")
    style.border_color = Color("#b69b6c")
    style.set_border_width_all(1)
    style.set_corner_radius_all(8)
    style.set_content_margin_all(9)
    panel.add_theme_stylebox_override("panel", style)
    return panel


func _label(value: String, size: int, tint: Color) -> Label:
    var label: Label = Label.new()
    label.text = value
    label.add_theme_color_override("font_color", tint)
    label.add_theme_font_size_override("font_size", size)
    return label


func _button(text_value: String, callback: Callable) -> Button:
    var btn: Button = Button.new()
    btn.text = text_value
    btn.custom_minimum_size.y = 27
    btn.pressed.connect(callback)
    return btn


func _refresh() -> void:
    _turn.text = "TURNO %d" % int(_game.turns)
    _resource.text = "OURO  100   •   CIÊNCIA  %d   •   CIDADES  %d" % [
        (int(_game.turns) - 1) * 2, int(_game.city_count())
    ]
    var active: Dictionary = _game.get_active()
    if not active.is_empty():
        _summary.text = "Selecionado: %s | unidades: %d" % [
            str(active["kind"]).to_upper(), _game.player_unit_count()
        ]
    elif _game.city_count() > 0:
        _summary.text = "Capital fundada! Escolhe uma produção."
    else:
        _summary.text = "Seleciona o colono para fundar a capital."
    _found.disabled = not _game.can_found()
    _warrior.disabled = _game.city_count() == 0
    _unit.disabled = _game.player_unit_count() == 0
