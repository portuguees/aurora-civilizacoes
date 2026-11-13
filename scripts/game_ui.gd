extends CanvasLayer
## Interface de jogo M2: cidades, distritos e ações contextuais.
const DistrictRules = preload("res://scripts/district_rules.gd")
const TechnologyRules = preload("res://scripts/technology_rules.gd")
const StrategicUI = preload("res://scripts/strategic_ui.gd")

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
var _news: Label
var _district_buttons: Dictionary = {}
var _focus_buttons: Array[Button] = []
var _research_info: Label
var _research_overlay: ColorRect
var _research_buttons: Dictionary = {}


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
    ribbon.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    ribbon.position = Vector2(18, 82)
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
    actions.offset_left = -440.0
    actions.offset_right = -16.0
    actions.offset_top = -623.0
    actions.offset_bottom = -102.0
    root.add_child(actions)

    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 7)
    actions.add_child(column)
    column.add_child(_label("CIVILIZAÇÃO  ·  AURORA", 15, Color("#f3d79d")))
    _summary = _label("A preparar a primeira expedição...", 12, Color("#e9f0e3"))
    column.add_child(_summary)
    _news = _label("Explora o território.", 12, Color("#e7ca95"))
    _news.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _news.custom_minimum_size.y = 30.0
    column.add_child(_news)

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
    var save_row: HBoxContainer = HBoxContainer.new()
    save_row.add_theme_constant_override("separation", 6)
    column.add_child(save_row)
    var save_button: Button = _button("GUARDAR CAMPANHA", _on_save)
    save_row.add_child(save_button)
    var load_button: Button = _button("CONTINUAR CAMPANHA", _on_load)
    save_row.add_child(load_button)

    var controls: Label = _label("Clique esquerdo: selecionar
Clique direito: caminho ou ataque", 11, Color("#aec7c8"))
    column.add_child(controls)
    _build_research_ui(root)
    var strategy: Control = StrategicUI.new()
    strategy.name = "PaineisEstrategia"
    strategy.call("setup", _game)
    root.add_child(strategy)


func _build_research_ui(root: Control) -> void:
    var research_panel: PanelContainer = _panel()
    research_panel.name = "PainelInvestigacao"
    research_panel.anchor_left = 1.0
    research_panel.anchor_right = 1.0
    research_panel.offset_left = -415.0
    research_panel.offset_right = -16.0
    research_panel.offset_top = 85.0
    research_panel.offset_bottom = 208.0
    root.add_child(research_panel)
    var research_column: VBoxContainer = VBoxContainer.new()
    research_panel.add_child(research_column)
    research_column.add_child(_label("CONHECIMENTO  ·  ÁRVORE TECNOLÓGICA", 13, Color("#f1d599")))
    _research_info = _label("Escolhe a próxima investigação.", 12, Color("#d4e1dc"))
    research_column.add_child(_research_info)
    var open_button: Button = _button("ABRIR TECNOLOGIAS  [T]", _open_research)
    open_button.name = "AbrirTecnologias"
    research_column.add_child(open_button)

    _research_overlay = ColorRect.new()
    _research_overlay.name = "ArvoreTecnologica"
    _research_overlay.color = Color("#081b24d6")
    _research_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    _research_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(_research_overlay)
    var sheet: PanelContainer = _panel()
    sheet.anchor_left = 0.5
    sheet.anchor_right = 0.5
    sheet.anchor_top = 0.5
    sheet.anchor_bottom = 0.5
    sheet.offset_left = -310.0
    sheet.offset_right = 310.0
    sheet.offset_top = -219.0
    sheet.offset_bottom = 219.0
    _research_overlay.add_child(sheet)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    sheet.add_child(column)
    column.add_child(_label("INVESTIGAÇÃO DO IMPÉRIO", 21, Color("#f3d9aa")))
    column.add_child(_label("Escolhe uma descoberta. Pré-requisitos precisam de estar concluídos.", 12, Color("#ccd8d4")))
    for key in TechnologyRules.ORDER:
        var info: Dictionary = TechnologyRules.TECHS[key]
        var row: HBoxContainer = HBoxContainer.new()
        row.add_theme_constant_override("separation", 11)
        column.add_child(row)
        var btn: Button = _button("%s  ·  %d ciência" % [str(info["name"]), int(info["cost"])], _select_research.bind(key))
        btn.name = "Tech_%s" % key
        btn.custom_minimum_size.x = 230
        row.add_child(btn)
        _research_buttons[key] = btn
        var requirements: PackedStringArray = PackedStringArray()
        for prerequisite in info["requires"]:
            requirements.append(TechnologyRules.title(str(prerequisite)))
        var detail_text: String = str(info["description"])
        if not requirements.is_empty():
            detail_text += "  |  Requer: " + ", ".join(requirements)
        var detail: Label = _label(detail_text, 12, Color("#d9e6da"))
        detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        detail.custom_minimum_size.x = 315
        row.add_child(detail)
    var close_button: Button = _button("FECHAR  [ESC]", _close_research)
    column.add_child(close_button)
    _research_overlay.visible = false


func _open_research() -> void:
    _research_overlay.visible = true
    _refresh()


func _close_research() -> void:
    _research_overlay.visible = false


func _select_research(key: String) -> void:
    if _game.choose_technology(key):
        _close_research()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var pressed_key: InputEventKey = event
        if pressed_key.pressed and not pressed_key.echo:
            if pressed_key.keycode == KEY_T:
                _open_research()
                get_viewport().set_input_as_handled()
            elif pressed_key.keycode == KEY_ESCAPE and _research_overlay.visible:
                _close_research()
                get_viewport().set_input_as_handled()


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
    _resource.text = "OURO %d  •  CIÊNCIA %d  •  CIDADES %d  •  EXPLORADO %d/%d" % [
        int(_game.treasury), int(_game.accumulated_science), int(_game.city_count()),
        int(_game.discovered_count()), int(_game.world.tiles.size())
    ]
    var active: Dictionary = _game.get_active()
    if not active.is_empty():
        _summary.text = "%s  •  PV %d/100  •  Movimento %d/%d  •  Rota %d" % [
            "COLONO" if str(active["kind"]) == "settler" else "GUERREIROS",
            int(active.get("health", 100)), int(active.get("move_points", 0)),
            int(_game.HexNavigation.movement_capacity(str(active["kind"]))),
            active.get("route", []).size()
        ]
    elif _game.city_count() > 0:
        _summary.text = "Capital fundada! Escolhe uma produção."
    else:
        _summary.text = "Seleciona o colono para fundar a capital."
    _news.text = str(_game.last_event)
    var research: Dictionary = _game.research_status()
    if str(_game.current_technology) == "":
        _research_info.text = "%d descobertas concluídas · seleciona um projeto" % int(research["completed"])
    else:
        _research_info.text = "%s: %d / %d ciência  ·  %d concluídas" % [
            str(research["name"]), int(research["progress"]),
            int(research["cost"]), int(research["completed"])
        ]
    for key in _research_buttons:
        var button: Button = _research_buttons[key]
        button.disabled = not TechnologyRules.can_start(str(key), _game.researched)
        var title: String = str(TechnologyRules.TECHS[key]["name"])
        if _game.researched.has(str(key)):
            button.text = "%s  ✓ concluída" % title
        elif str(_game.current_technology) == str(key):
            button.text = "%s  •  a investigar" % title
        else:
            button.text = "%s · %d ciência" % [title, TechnologyRules.cost(str(key))]
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
                int(DistrictRules.COSTS.get(project, 12))
            ]
    else:
        _project.text = "Seleciona ou funda uma cidade para construir."
    if _game.placing_district != "":
        _placement.text = "COLOCAÇÃO: %s · clica numa parcela válida · ESC cancela" % _short_district_name(_game.placing_district)
    else:
        _placement.text = "Seleciona um distrito e depois uma parcela junto da cidade."



func _on_save() -> void:
    if not _game.save_game():
        _placement.text = "Não foi possível guardar a campanha."
    else:
        _placement.text = "Campanha guardada no computador."


func _on_load() -> void:
    if not _game.load_game():
        _placement.text = "Não existe uma gravação M2 válida."
    else:
        _placement.text = "Campanha retomada."
