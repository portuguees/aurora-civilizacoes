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
var _project: Label
var _placement: Label
var _district_buttons: Dictionary = {}
var _focus_buttons: Array[Button] = []


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
    actions.offset_left = -395.0
    actions.offset_right = -16.0
    actions.offset_top = -545.0
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
    _project = _label("Nenhum projeto selecionado.", 12, Color("#ecce94"))
    column.add_child(_project)
    var build_label: Label = _label("DISTRITOS E MELHORIAS  ·  CLICAR NO MAPA", 11, Color("#d7b47c"))
    column.add_child(build_label)
    var first: HBoxContainer = HBoxContainer.new()
    column.add_child(first)
    var second: HBoxContainer = HBoxContainer.new()
    column.add_child(second)
    for kind in ["campus", "market", "industrial", "barracks", "harbor", "farm", "mine"]:
        var row: HBoxContainer = first if kind in ["campus", "market", "industrial"] else second
        var btn: Button = _button(_short_district_name(kind), _game.choose_district.bind(kind))
        btn.custom_minimum_size.x = 93.0
        row.add_child(btn)
        _district_buttons[kind] = btn
    _placement = _label("Escolhe um distrito e depois um hexágono válido.", 11, Color("#cfdfdc"))
    column.add_child(_placement)
    var focus_row: HBoxContainer = HBoxContainer.new()
    column.add_child(focus_row)
    for option in ["balanced", "food", "production"]:
        var focus_button: Button = _button(_focus_name(option), _game.set_city_focus.bind(option))
        focus_row.add_child(focus_button)
        _focus_buttons.append(focus_button)
    _end = _button("TERMINAR TURNO   [E]", _game.end_turn)
    column.add_child(_end)

    var controls: Label = _label("Clique esquerdo: selecionar
Clique direito: mover 1 hexágono", 11, Color("#aec7c8"))
    column.add_child(controls)


func _short_district_name(kind: String) -> String:
    match kind:
        "campus": return "Academia"
        "market": return "Mercado"
        "industrial": return "Oficinas"
        "barracks": return "Quartel"
        "harbor": return "Porto"
        "farm": return "Quinta"
        "mine": return "Mina"
    return kind


func _focus_name(kind: String) -> String:
    match kind:
        "food": return "Alimentos"
        "production": return "Produção"
    return "Equilibrado"


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
    var city: Dictionary = _game.get_selected_city()
    _warrior.disabled = city.is_empty() or str(city.get("project", "")) != ""
    _unit.disabled = _game.player_unit_count() == 0
    for kind in _district_buttons:
        var unavailable: bool = city.is_empty() or str(city.get("project", "")) != ""
        _district_buttons[kind].disabled = unavailable
    for button in _focus_buttons:
        button.disabled = city.is_empty()
    if not city.is_empty():
        var yields: Dictionary = _game.get_city_yields(city)
        var project: String = str(city.get("project", ""))
        _project.text = "%s · pop %d · alimentos %+d · produção %d" % [
            str(city["name"]), int(city["population"]),
            int(yields["food_surplus"]), int(yields["production"])
        ]
        if project != "":
            _project.text += "\nObra: %s  %d / %d" % [
                _short_district_name(project), int(city["progress"]),
                int(_game.DistrictRules.COSTS.get(project, 12))
            ]
    else:
        _project.text = "Seleciona ou funda uma cidade para construir."
    if _game.placing_district != "":
        _placement.text = "COLOCAÇÃO: %s · clica numa parcela válida · ESC cancela" % _short_district_name(_game.placing_district)
    else:
        _placement.text = "Seleciona um distrito e depois uma parcela junto da cidade."

