extends Node2D

## Harbor Year SimCity root — replaces the season-pick loop.

var game := HarborGame.new()
var harbor_map: HarborMap
var cursor: BuildCursor
var camera: CameraCtrl
var people: MapPeople
var boat_root := Node2D.new()
var top: TopBar
var toolbar: BuildToolbar
var prices: PricesPanel
var budget: BudgetPanel
var board: BoardPanel
var news: NewsPanel
var reports: ReportsPanel
var annual: AnnualCard
var boat_timer := 0.0
var ticker: Label


func _ready() -> void:
	DisplayServer.window_set_title("Harbor Year")
	var data := SimSave.read()
	if not data.is_empty() and str(data.get("outcome", "")) == "":
		game.from_dict(data)
	else:
		game.new_game("harbor_year", 1)
	_build_world()
	_build_ui()
	game.changed.connect(_refresh)
	game.news.connect(_on_news)
	game.game_over.connect(_on_over)
	game.annual.connect(_on_annual)
	_refresh()


func _build_world() -> void:
	harbor_map = HarborMap.new()
	harbor_map.grid = game.grid
	add_child(harbor_map)
	boat_root.z_index = 5
	add_child(boat_root)
	people = MapPeople.new()
	people.bind(game)
	add_child(people)
	cursor = BuildCursor.new()
	cursor.grid = game.grid
	cursor.place_requested.connect(_on_place)
	add_child(cursor)
	camera = CameraCtrl.new()
	add_child(camera)
	camera.make_current()
	camera.set_bounds_from_map(harbor_map.map_size_px())
	## frame the clubhouse / piers
	camera.position = Vector2(48, 22) * SimCatalog.TILE * SimCatalog.SCALE


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	top = TopBar.new()
	top.game = game
	top.speed_changed.connect(func(s): game.clock.set_speed(s))
	top.panel_requested.connect(_on_panel)
	ui.add_child(top)
	toolbar = BuildToolbar.new()
	toolbar.game = game
	toolbar.tool_selected.connect(func(id): cursor.set_tool(id))
	ui.add_child(toolbar)
	prices = PricesPanel.new()
	prices.game = game
	ui.add_child(prices)
	budget = BudgetPanel.new()
	budget.game = game
	ui.add_child(budget)
	board = BoardPanel.new()
	board.game = game
	ui.add_child(board)
	news = NewsPanel.new()
	news.game = game
	ui.add_child(news)
	reports = ReportsPanel.new()
	reports.game = game
	ui.add_child(reports)
	annual = AnnualCard.new()
	annual.closed.connect(_on_annual_closed)
	ui.add_child(annual)
	ticker = PanelSkin.label("", 24)
	ticker.set_anchors_preset(Control.PRESET_TOP_WIDE)
	ticker.offset_top = 58
	ticker.offset_left = 16
	ticker.offset_right = -16
	ticker.offset_bottom = 86
	ui.add_child(ticker)
	## title chooser for empty shore
	var map_btn := PanelSkin.button("Empty Shore")
	map_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	map_btn.offset_left = 12
	map_btn.offset_top = 620
	map_btn.offset_right = 160
	map_btn.offset_bottom = 652
	map_btn.pressed.connect(func():
		game.new_game("empty_shore", int(Time.get_unix_time_from_system()))
		harbor_map.grid = game.grid
		harbor_map.redraw()
		people.bind(game)
		_refresh()
	)
	ui.add_child(map_btn)
	var hy := PanelSkin.button("Harbor Year")
	hy.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hy.offset_left = 170
	hy.offset_top = 620
	hy.offset_right = 320
	hy.offset_bottom = 652
	hy.pressed.connect(func():
		game.new_game("harbor_year", 1)
		harbor_map.grid = game.grid
		harbor_map.redraw()
		people.bind(game)
		_refresh()
	)
	ui.add_child(hy)


func _process(delta: float) -> void:
	game.process(delta)
	_update_cursor()
	boat_timer += delta
	if boat_timer >= 2.5:
		boat_timer = 0.0
		_spawn_boats()


func _update_cursor() -> void:
	var mouse := get_global_mouse_position()
	cursor.update_from_world(mouse)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			cursor.try_click()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			game.clock.set_speed(0 if game.clock.speed > 0 else 1)
			_refresh()
		elif event.keycode == KEY_PERIOD:
			game.clock.advance()


func _on_place(tool_id: String, cell: Vector2i) -> void:
	var res := game.try_build(tool_id, cell.x, cell.y)
	if res["ok"]:
		harbor_map.redraw()
		people.bind(game)
	if toolbar.status:
		toolbar.status.text = str(res["text"])
	_refresh()


func _on_panel(name: String) -> void:
	prices.visible = false
	budget.visible = false
	board.visible = false
	news.visible = false
	reports.visible = false
	match name:
		"prices":
			prices.toggle()
		"budget":
			budget.toggle()
		"board":
			board.toggle()
		"news":
			news.toggle()
		"reports":
			reports.toggle()


func _refresh() -> void:
	top.refresh()
	prices.refresh()
	budget.refresh()
	if board.visible:
		board.refresh()
	if news.visible:
		news.refresh()
	if reports.visible:
		reports.refresh()
	harbor_map.grid = game.grid
	harbor_map.redraw()


func _on_news(line: Dictionary) -> void:
	ticker.text = str(line.get("text", ""))
	if news.visible:
		news.refresh()


func _on_over(kind: String, text: String) -> void:
	game.clock.set_speed(0)
	annual.show_ending(kind, text)


func _on_annual(report: Dictionary) -> void:
	game.clock.set_speed(0)
	annual.show_report(report)


func _on_annual_closed() -> void:
	if game.outcome != "":
		game.new_game("harbor_year", int(Time.get_unix_time_from_system()) % 100000)
		harbor_map.grid = game.grid
		people.bind(game)
		harbor_map.redraw()
	_refresh()


func _spawn_boats() -> void:
	if not game.channel_open():
		return
	var want := SimCatalog.moving_count(game.grid.filled_slips(), game.clock.season(), true)
	want = mini(want, 12)
	var existing := boat_root.get_child_count()
	if existing >= want:
		return
	## pick a filled slip
	var slips: Array[Vector2i] = []
	for y in game.grid.h:
		for x in game.grid.w:
			if game.grid.get_cell(x, y) == SimCatalog.CELL_SLIP and game.grid.slip_filled[game.grid.idx(x, y)] == 1:
				slips.append(Vector2i(x, y))
	if slips.is_empty():
		return
	var start: Vector2i = slips[randi() % slips.size()]
	var path := BoatRouter.path_to_edge(game.grid, start)
	if path.is_empty():
		return
	var b := MapBoat.new()
	var world := Vector2(start.x + 0.5, start.y + 0.5) * SimCatalog.TILE * SimCatalog.SCALE
	boat_root.add_child(b)
	b.setup(path, world)
