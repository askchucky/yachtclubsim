class_name HarborGame
extends RefCounted

signal changed
signal news(line: Dictionary)
signal game_over(kind: String, text: String)
signal annual(report: Dictionary)

var clock := MonthClock.new()
var grid := HarborGrid.new()
var economy := SimEconomy.new()
var demand := SimDemand.new()
var politics := SimPolitics.new()
var events := SimEvents.new()

var map_id: String = "harbor_year"
var regular: int = 140
var social: int = 45
var crew: int = 15
var employed: Dictionary = {
	"dockmaster": true, "bar_manager": true, "bookkeeper": true, "yard_boss": true,
}
var staff_morale: Dictionary = {
	"dockmaster": 70, "bar_manager": 70, "bookkeeper": 70, "yard_boss": 70,
}
var news_feed: Array = []
var milestones: Dictionary = {}
var outcome: String = ""
var hollow_streak: int = 0
var start_seed: int = 1


func _init() -> void:
	clock.month_tick.connect(_on_month)


func new_game(which: String = "harbor_year", seed_value: int = 1) -> void:
	map_id = which
	start_seed = seed_value
	events.seed_rng(seed_value)
	clock.year = 1
	clock.month = 0
	clock.speed = 0
	clock.accum = 0
	outcome = ""
	hollow_streak = 0
	milestones.clear()
	news_feed.clear()
	if which == "empty_shore":
		grid.load_empty_shore()
		economy.cash = SimCatalog.OPENING_CASH_EMPTY
		economy.loan = 0
		regular = 40
		social = 10
		crew = 5
	else:
		grid.load_harbor_year()
		economy.cash = SimCatalog.OPENING_CASH_HARBOR
		economy.loan = 0
		regular = 140
		social = 45
		crew = 15
	economy.prices = SimCatalog.default_prices()
	economy.budget = SimCatalog.default_budget()
	economy.history.clear()
	demand = SimDemand.new()
	politics = SimPolitics.new()
	employed = {"dockmaster": true, "bar_manager": true, "bookkeeper": true, "yard_boss": true}
	staff_morale = {"dockmaster": 70, "bar_manager": 70, "bookkeeper": 70, "yard_boss": 70}
	_hire_from_buildings()
	_post("commodore", "Welcome to Harbor Year. Keep the club solvent.")
	changed.emit()


func members() -> int:
	return regular + social + crew


func channel_open() -> bool:
	return bool(grid.channel_reaches_edge()["open"])


func process(delta: float) -> void:
	if outcome != "":
		return
	clock.process(delta)


func _on_month() -> void:
	_month_tick()


func _month_tick() -> void:
	_hire_from_buildings()
	var ch := channel_open()
	demand.update(grid, economy, clock.season(), ch)
	demand.apply_occupancy(grid, ch)
	var drifted := demand.drift_members(regular, social, crew, grid.member_cap())
	regular = drifted["regular"]
	social = drifted["social"]
	crew = drifted["crew"]

	var reach: Dictionary = grid.channel_reaches_edge()
	var mask: PackedByteArray = reach["mask"]
	var slips_earning := grid.earning_slip_count(mask) if ch else 0
	var boat_moves := SimCatalog.moving_count(grid.filled_slips(), clock.season(), ch)
	var state := {
		"regular": regular,
		"social": social,
		"crew": crew,
		"slips_earning": slips_earning,
		"has_bar": grid.has_building(SimCatalog.CELL_BAR) and bool(employed.get("bar_manager", false)),
		"has_fuel": grid.has_building(SimCatalog.CELL_FUEL),
		"has_yard": grid.has_building(SimCatalog.CELL_YARD) and bool(employed.get("yard_boss", false)),
		"has_office": grid.has_building(SimCatalog.CELL_OFFICE) and bool(employed.get("bookkeeper", false)),
		"season": clock.season(),
		"boat_moves": boat_moves,
		"dock_tiles": grid.count_cell(SimCatalog.CELL_PIER) + grid.count_cell(SimCatalog.CELL_SLIP),
		"building_upkeep": economy.building_upkeep(grid),
		"demand_bar": demand.bar,
	}
	economy.month_ledger(state)
	events.apply_decay(grid, economy, bool(employed.get("dockmaster", false)))
	var ev := events.roll(clock.season(), grid, economy, ch)
	_post_event(ev)
	## staff morale from pay
	var pay := float(economy.budget["staff_pay"])
	for role in SimCatalog.STAFF:
		if not bool(employed.get(role, false)):
			continue
		var m: float = float(staff_morale[role])
		m += (pay - 100.0) * 0.15
		if pay < 70:
			m -= 4
		staff_morale[role] = clampf(m, 0, 100)
		if staff_morale[role] <= 0:
			employed[role] = false
			_post(role, "%s walked out." % SimCatalog.NAMES[role])
	politics.recompute(economy, demand, grid, channel_open())
	for w in politics.warnings:
		_post(str(w["who"]), str(w["text"]))
	_named_people_lines()
	_check_milestones()
	if economy.insolvent():
		outcome = "insolvent"
		game_over.emit("insolvent", SimCatalog.money(economy.cash) + " — the club is insolvent.")
	elif clock.month == 11:
		if members() < SimCatalog.MEMBER_MIN_HOLLOW:
			hollow_streak += 1
		else:
			hollow_streak = 0
		if hollow_streak >= 2:
			outcome = "hollow"
			game_over.emit("hollow", "Membership stayed under 140 two Decembers. The club is hollow.")
		annual.emit(_annual_report())
	SimSave.write(self)
	changed.emit()


func try_build(tool_id: String, x: int, y: int) -> Dictionary:
	if outcome != "":
		return {"ok": false, "text": "Game over."}
	var tool := SimCatalog.tool_by_id(tool_id)
	if tool.is_empty():
		return {"ok": false, "text": "Unknown tool."}
	var cost: int = int(tool["cost"])
	if tool_id != "bulldoze" and economy.cash < cost:
		return {"ok": false, "text": "Not enough cash."}
	if tool_id == "bulldoze" and economy.cash < cost:
		return {"ok": false, "text": "Not enough cash."}
	if not grid.can_place(tool_id, x, y):
		return {"ok": false, "text": "Can't place here."}
	## big clubhouse needs board if upgrading — first place is fine
	if not grid.place(tool_id, x, y):
		return {"ok": false, "text": "Placement failed."}
	economy.cash -= cost
	_hire_from_buildings()
	_post("dockmaster" if tool_id in ["pier", "slip", "dredge", "breakwater"] else "commodore", "Built %s for %s." % [tool["label"], SimCatalog.money(cost)])
	changed.emit()
	SimSave.write(self)
	return {"ok": true, "text": "Placed."}


func _hire_from_buildings() -> void:
	if grid.has_building(SimCatalog.CELL_BAR) and not bool(employed["bar_manager"]):
		employed["bar_manager"] = true
		staff_morale["bar_manager"] = 60
	if grid.has_building(SimCatalog.CELL_YARD) and not bool(employed["yard_boss"]):
		employed["yard_boss"] = true
		staff_morale["yard_boss"] = 60
	if grid.has_building(SimCatalog.CELL_OFFICE) and not bool(employed["bookkeeper"]):
		employed["bookkeeper"] = true
		staff_morale["bookkeeper"] = 60
	if grid.has_building(SimCatalog.CELL_CLUBHOUSE) and not bool(employed["dockmaster"]):
		employed["dockmaster"] = true
		staff_morale["dockmaster"] = 60


func _named_people_lines() -> void:
	if demand.slips > 70 and clock.month % 3 == 0:
		_post("helen", "Helen: the waiting list for slips is real.")
	if demand.bar < 40:
		_post("marco", "Marco: the bar feels empty.")
	if demand.racing > 65 and clock.month % 4 == 1:
		_post("june", "June: put me on the race committee.")
	if economy.last_ledger.get("net", 0) < 0:
		_post("ruth", "Ruth: another red month.")
	if not channel_open():
		_post("pete", "Pete: I can't get out of the harbor.")


func _check_milestones() -> void:
	var slips := grid.slip_count()
	for n in [60, 100, 160]:
		var key := "slips_%d" % n
		if slips >= n and not bool(milestones.get(key, false)):
			milestones[key] = true
			_post("commodore", "Milestone: %d slips." % n)
	var m := members()
	for n in [300, 400]:
		var key := "members_%d" % n
		if m >= n and not bool(milestones.get(key, false)):
			milestones[key] = true
			_post("commodore", "Milestone: %d members." % n)
	if clock.year >= 10 and outcome == "":
		var key := "decade"
		if not bool(milestones.get(key, false)):
			milestones[key] = true
			_post("commodore", "A decade solvent.")


func _post(who: String, text: String) -> void:
	var line := {"who": who, "text": text, "month": clock.month, "year": clock.year}
	news_feed.push_front(line)
	if news_feed.size() > 40:
		news_feed.pop_back()
	news.emit(line)


func _post_event(ev: Dictionary) -> void:
	_post("commodore", "Rolled %d — %s. %s" % [ev["roll"], ev["title"], ev["text"]])


func _annual_report() -> Dictionary:
	return {
		"year": clock.year,
		"cash": economy.cash,
		"loan": economy.loan,
		"ledger": economy.last_ledger.duplicate(),
		"members": {"regular": regular, "social": social, "crew": crew, "total": members()},
		"slips": {"total": grid.slip_count(), "filled": grid.filled_slips()},
		"demand": {"slips": demand.slips, "bar": demand.bar, "racing": demand.racing, "members": demand.members},
		"approval": politics.board.duplicate(),
		"milestones": milestones.keys(),
	}


func force_months(n: int) -> void:
	for i in n:
		if outcome != "":
			return
		clock.advance()


func to_dict() -> Dictionary:
	return {
		"map_id": map_id,
		"start_seed": start_seed,
		"regular": regular,
		"social": social,
		"crew": crew,
		"employed": employed.duplicate(),
		"staff_morale": staff_morale.duplicate(),
		"news_feed": news_feed.duplicate(),
		"milestones": milestones.duplicate(),
		"outcome": outcome,
		"hollow_streak": hollow_streak,
		"clock": clock.to_dict(),
		"grid": grid.to_dict(),
		"economy": economy.to_dict(),
		"demand": demand.to_dict(),
		"politics": politics.to_dict(),
	}


func from_dict(d: Dictionary) -> void:
	map_id = str(d.get("map_id", "harbor_year"))
	start_seed = int(d.get("start_seed", 1))
	regular = int(d.get("regular", 140))
	social = int(d.get("social", 45))
	crew = int(d.get("crew", 15))
	employed = d.get("employed", employed)
	staff_morale = d.get("staff_morale", staff_morale)
	news_feed = d.get("news_feed", [])
	milestones = d.get("milestones", {})
	outcome = str(d.get("outcome", ""))
	hollow_streak = int(d.get("hollow_streak", 0))
	clock.from_dict(d.get("clock", {}))
	grid.from_dict(d.get("grid", {}))
	economy.from_dict(d.get("economy", {}))
	demand.from_dict(d.get("demand", {}))
	politics.from_dict(d.get("politics", {}))
	events.seed_rng(start_seed + clock.year * 12 + clock.month)
