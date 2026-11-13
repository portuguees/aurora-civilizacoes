extends Control
## M8–M10: um painel persistente com três janelas de estratégia.
## Controlos operacionais, alimentados exclusivamente pelo estado do jogo.

const CivicRules = preload("res://scripts/civic_rules.gd")
const VictoryRules = preload("res://scripts/victory_rules.gd")

var game: Node
var _civics: ColorRect
var _diplomacy: ColorRect
var _victory: ColorRect
var _civic_summary: Label
var _diplomacy_summary: Label
var _victory_summary: Label
var _civic_buttons: Dictionary = {}
var _government_buttons: Dictionary = {}
var _dip_buttons: Dictionary = {}
var _victory_labels: Dictionary = {}
var _capture_button: Button
var _victory_announced: bool = false


func setup(target_game: Node) -> void:
    game = target_game


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build()
    if game != null:
        game.state_changed.connect(_refresh)
        _refresh()


func _panel() -> PanelContainer:
    var panel: PanelContainer = PanelContainer.new()
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color("#102c36f2")
    style.border_color = Color("#c2a471")
    style.set_border_width_all(1)
    style.set_corner_radius_all(10)
    style.set_content_margin_all(11)
    panel.add_theme_stylebox_override("panel", style)
    return panel


func _label(message: String, font_size: int = 13, accent: bool = false) -> Label:
    var item: Label = Label.new()
    item.text = message
    item.add_theme_font_size_override("font_size", font_size)
    item.add_theme_color_override("font_color", Color("#f5d59e") if accent else Color("#dce8e3"))
    item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return item


func _button(title: String, callback: Callable) -> Button:
    var item: Button = Button.new()
    item.text = title
    item.custom_minimum_size.y = 30
    item.pressed.connect(callback)
    return item


func _build() -> void:
    var bar: PanelContainer = _panel()
    bar.name = "PainelImperio"
    bar.offset_left = 18.0
    bar.offset_right = 423.0
    bar.offset_top = 166.0
    bar.offset_bottom = 254.0
    add_child(bar)
    var bar_column: VBoxContainer = VBoxContainer.new()
    bar.add_child(bar_column)
    bar_column.add_child(_label("O IMPÉRIO  ·  CULTURA  /  DIPLOMACIA  /  VITÓRIA", 13, true))
    var actions: HBoxContainer = HBoxContainer.new()
    actions.add_theme_constant_override("separation", 6)
    bar_column.add_child(actions)
    actions.add_child(_button("CULTURA [C]", open_civics))
    actions.add_child(_button("DIPLOMACIA [D]", open_diplomacy))
    actions.add_child(_button("VITÓRIAS [V]", open_victory))

    _civics = _overlay("CivilizacoesCivicas")
    _diplomacy = _overlay("DiplomaciaComercio")
    _victory = _overlay("ObjetivosVitoria")
    _build_civics()
    _build_diplomacy()
    _build_victory()
    close_all()


func _overlay(overlay_name: String) -> ColorRect:
    var shade: ColorRect = ColorRect.new()
    shade.name = overlay_name
    shade.color = Color("#071923db")
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)
    var sheet: PanelContainer = _panel()
    sheet.name = "Conteudo"
    sheet.anchor_left = 0.5
    sheet.anchor_right = 0.5
    sheet.anchor_top = 0.5
    sheet.anchor_bottom = 0.5
    sheet.offset_left = -355.0
    sheet.offset_right = 355.0
    sheet.offset_top = -276.0
    sheet.offset_bottom = 276.0
    shade.add_child(sheet)
    var contents: VBoxContainer = VBoxContainer.new()
    contents.name = "Coluna"
    contents.add_theme_constant_override("separation", 9)
    sheet.add_child(contents)
    return shade


func _column(overlay: ColorRect) -> VBoxContainer:
    return overlay.get_node("Conteudo/Coluna") as VBoxContainer


func _build_civics() -> void:
    var column: VBoxContainer = _column(_civics)
    column.add_child(_label("CULTURA, LEIS E FORMAS DE GOVERNO", 21, true))
    _civic_summary = _label("Tradições e políticas em desenvolvimento.", 13)
    column.add_child(_civic_summary)
    column.add_child(_label("PRINCÍPIOS CÍVICOS  ·  escolhe uma investigação cultural", 12, true))
    for key in CivicRules.ORDER:
        var civic: Dictionary = CivicRules.CIVICS[key]
        var row: HBoxContainer = HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        column.add_child(row)
        var select: Button = _button("%s · %d" % [str(civic["name"]), int(civic["cost"])], _choose_civic.bind(key))
        select.name = "Civic_%s" % key
        select.custom_minimum_size.x = 224
        row.add_child(select)
        _civic_buttons[key] = select
        var requirements: PackedStringArray = PackedStringArray()
        for prerequisite in civic["requires"]:
            requirements.append(CivicRules.title(str(prerequisite)))
        var description: String = str(civic["effect"])
        if not requirements.is_empty():
            description += "  ·  Requer " + ", ".join(requirements)
        var info: Label = _label(description, 11)
        info.custom_minimum_size.x = 435
        row.add_child(info)
    column.add_child(_label("GOVERNO DO IMPÉRIO", 12, true))
    var governments: HBoxContainer = HBoxContainer.new()
    governments.add_theme_constant_override("separation", 9)
    column.add_child(governments)
    for key in CivicRules.GOVERNMENT_ORDER:
        var gov: Dictionary = CivicRules.GOVERNMENTS[key]
        var btn: Button = _button(str(gov["name"]), _choose_government.bind(key))
        btn.name = "Gov_%s" % key
        btn.custom_minimum_size.x = 150
        governments.add_child(btn)
        _government_buttons[key] = btn
    column.add_child(_label("Os governos modificam diretamente a cultura, ouro e ciência das cidades.", 11))
    column.add_child(_button("FECHAR  [ESC]", close_all))


func _build_diplomacy() -> void:
    var column: VBoxContainer = _column(_diplomacy)
    column.add_child(_label("DIPLOMACIA COM VALDORIA", 21, true))
    _diplomacy_summary = _label("Ainda não existe contacto com outra capital.", 14)
    _diplomacy_summary.custom_minimum_size.y = 134
    column.add_child(_diplomacy_summary)
    column.add_child(_label("ACORDOS E CARAVANAS", 12, true))
    var offers: Array[Dictionary] = [
        {"key": "gift", "label": "ENVIAR OFERTA  ·  25 OURO", "callback": Callable(self, "_gift")},
        {"key": "peace", "label": "NEGOCIAR PAZ  ·  12 OURO", "callback": Callable(self, "_peace")},
        {"key": "trade", "label": "CRIAR CARAVANA  ·  12 OURO", "callback": Callable(self, "_trade")},
        {"key": "war", "label": "DECLARAR GUERRA", "callback": Callable(self, "_war")}
    ]
    for data in offers:
        var button: Button = _button(str(data["label"]), data["callback"])
        button.name = "Acao_%s" % str(data["key"])
        column.add_child(button)
        _dip_buttons[str(data["key"])] = button
    column.add_child(_label("As caravanas dão ouro e cultura durante a paz. Um ataque quebra as negociações.", 12))
    column.add_child(_button("FECHAR  [ESC]", close_all))


func _build_victory() -> void:
    var column: VBoxContainer = _column(_victory)
    column.add_child(_label("OBJETIVOS PARA VENCER A CAMPANHA", 21, true))
    _victory_summary = _label("A campanha continua.", 14)
    column.add_child(_victory_summary)
    for key in ["science", "culture", "economic", "military"]:
        var row: VBoxContainer = VBoxContainer.new()
        column.add_child(row)
        row.add_child(_label(str(VictoryRules.TITLES[key]).to_upper(), 14, true))
        var objective: Label = _label("A acompanhar os objetivos estratégicos.", 12)
        objective.name = "Objetivo_%s" % key
        row.add_child(objective)
        _victory_labels[key] = objective
    _capture_button = _button("CAPTURAR CAPITAL DE VALDORIA", _capture_capital)
    _capture_button.name = "CapturarValdoria"
    column.add_child(_capture_button)
    column.add_child(_label("Captura: guerreiro adjacente, guarnição rival eliminada e ausência de tratado de paz.", 11))
    column.add_child(_button("FECHAR  [ESC]", close_all))


func close_all() -> void:
    _civics.visible = false
    _diplomacy.visible = false
    _victory.visible = false


func open_civics() -> void:
    close_all()
    _refresh()
    _civics.visible = true


func open_diplomacy() -> void:
    close_all()
    _refresh()
    _diplomacy.visible = true


func open_victory() -> void:
    close_all()
    _refresh()
    _victory.visible = true


func _choose_civic(key: String) -> void:
    game.choose_civic(key)


func _choose_government(key: String) -> void:
    game.choose_government(key)


func _gift() -> void:
    game.send_gift()


func _peace() -> void:
    game.negotiate_peace()


func _trade() -> void:
    game.start_trade()


func _war() -> void:
    game.declare_war()


func _capture_capital() -> void:
    game.capture_rival_capital()


func _refresh() -> void:
    if game == null or _civics == null:
        return
    var civic: Dictionary = game.civic_status()
    var status: String = str(civic["name"])
    if game.current_civic != "":
        status += "  ·  %d/%d" % [int(civic["progress"]), int(civic["cost"])]
    _civic_summary.text = "Cultura acumulada: %d  ·  Concluídos: %d/5\nGoverno: %s  ·  Investigação: %s" % [
        int(civic["culture"]), int(civic["completed"]), str(civic["government"]), status
    ]
    for key in _civic_buttons:
        var select: Button = _civic_buttons[key]
        select.disabled = not CivicRules.can_start(str(key), game.civics_completed) or game.game_over
        if game.civics_completed.has(str(key)):
            select.text = str(CivicRules.CIVICS[key]["name"]) + "  ✓"
        else:
            select.text = "%s · %d cultura" % [CivicRules.title(str(key)), CivicRules.cost(str(key))]
    for key in _government_buttons:
        var btn: Button = _government_buttons[key]
        btn.disabled = not CivicRules.government_unlocked(str(key), game.civics_completed) or game.game_over
        btn.text = str(CivicRules.GOVERNMENTS[key]["name"]) + ("  ✓" if game.government == str(key) else "")

    var state: Dictionary = game.diplomacy
    var peace: int = int(state["peace_turns"])
    var trade: int = int(state["trade_turns"])
    _diplomacy_summary.text = "Valdoria  ·  Relação: %+d  ·  %s\n\nPaz: %d turnos restantes\nCaravana: %d turnos restantes (+5 ouro e +1 cultura por turno)\nAcordos realizados: %d  ·  Objetivo rival: %s" % [
        int(state["relations"]), str(state["rival_posture"]), peace, trade,
        int(state["agreements"]), str(game.rival_goal)
    ] if game.has_contact() else "Ainda não existe contacto com outra capital.\nA rival funda a sua primeira cidade nos turnos iniciais."
    _dip_buttons["gift"].disabled = not game.can_gift()
    _dip_buttons["peace"].disabled = not game.can_peace()
    _dip_buttons["trade"].disabled = not game.can_trade()
    _dip_buttons["war"].disabled = not game.has_contact() or game.game_over

    var objectives: Dictionary = game.victory_details()
    var points: Dictionary = objectives["scores"]
    _victory_summary.text = ("%s  ·  turno %d" % [
        str(VictoryRules.TITLES.get(game.victory_type, "VITÓRIA")), game.victory_turn
    ]) if game.game_over else "Campanha em curso  ·  %d de ciência  ·  %d de cultura  ·  %d ouro" % [
        int(game.accumulated_science), int(game.accumulated_culture), int(game.treasury)
    ]
    for key in _victory_labels:
        var label: Label = _victory_labels[key]
        var score: String = "%d%%" % int(points.get(key, 0)) if key != "military" else (
            "Capital conquistada" if game.rival_founded and game.city_count(game.RIVAL) == 0 else "Capital rival por conquistar"
        )
        label.text = "%s\nProgresso: %s" % [str(objectives[key]), score]
    _capture_button.disabled = not game.can_capture_rival()
    if game.game_over and not _victory_announced:
        _victory_announced = true
        close_all()
        _victory.visible = true


func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key: InputEventKey = event
    if not key.pressed or key.echo:
        return
    if key.keycode == KEY_C:
        open_civics()
    elif key.keycode == KEY_D:
        open_diplomacy()
    elif key.keycode == KEY_V:
        open_victory()
    elif key.keycode == KEY_ESCAPE and (_civics.visible or _diplomacy.visible or _victory.visible):
        close_all()
    else:
        return
    get_viewport().set_input_as_handled()
