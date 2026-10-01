extends SceneTree

## Headless checks for Harbor Year SimCity.


func _init() -> void:
	var failed := 0
	failed += _check_placement()
	failed += _check_channel_and_slips()
	failed += _check_solvent_years()
	failed += _check_zero_dredge()
	failed += _check_slip_fee()
	failed += _check_storm_cover()
	quit(1 if failed > 0 else 0)


func _ok(name: String, cond: bool, detail: String = "") -> int:
	if cond:
		print("OK  ", name, (" — " + detail) if detail != "" else "")
		return 0
	print("FAIL ", name, (" — " + detail) if detail != "" else "")
	return 1


func _check_placement() -> int:
	var g := HarborGrid.new()
	g.load_empty_shore()
	var f := 0
	## pier cannot float in open water far from shore
	f += _ok("pier_no_float", not g.can_place("pier", 50, 45))
	## pier can attach to sand shore
	f += _ok("pier_from_shore", g.can_place("pier", 47, 23) or g.can_place("pier", 47, 22))
	## place pier then slip
	var pier_x := 47
	var pier_y := 23
	if not g.can_place("pier", pier_x, pier_y):
		pier_y = 22
	g.place("pier", pier_x, pier_y)
	f += _ok("slip_needs_pier", g.can_place("slip", pier_x + 1, pier_y))
	f += _ok("slip_no_orphan", not g.can_place("slip", 60, 40))
	return f


func _check_channel_and_slips() -> int:
	var g := HarborGrid.new()
	g.load_harbor_year()
	var reach: Dictionary = g.channel_reaches_edge()
	var f := 0
	f += _ok("harbor_channel_open", bool(reach["open"]), "reachable %s" % str(reach["reachable_slips"]))
	f += _ok("harbor_about_40_slips", g.slip_count() >= 30 and g.slip_count() <= 50, "slips=%d" % g.slip_count())
	f += _ok("harbor_has_clubhouse", g.has_building(SimCatalog.CELL_CLUBHOUSE))
	f += _ok("harbor_has_breakwater", g.count_cell(SimCatalog.CELL_BREAKWATER) > 20)
	## silt shut
	for i in g.cells.size():
		if g.cells[i] == SimCatalog.CELL_CHANNEL:
			g.silt[i] = 100
	var closed: Dictionary = g.channel_reaches_edge()
	f += _ok("silt_closes_channel", not bool(closed["open"]))
	return f


func _check_solvent_years() -> int:
	var game := HarborGame.new()
	game.new_game("harbor_year", 42)
	game.clock.speed = 0
	game.force_months(36)
	var f := 0
	f += _ok("default_solvent_3y", game.outcome == "", "cash=%s outcome=%s" % [SimCatalog.money(game.economy.cash), game.outcome])
	return f


func _check_zero_dredge() -> int:
	var game := HarborGame.new()
	game.new_game("harbor_year", 7)
	game.economy.budget["dredging"] = 0
	game.force_months(12)
	var f := 0
	f += _ok("zero_dredge_closes", not game.channel_open(), "open=%s" % str(game.channel_open()))
	return f


func _check_slip_fee() -> int:
	var game := HarborGame.new()
	game.new_game("harbor_year", 9)
	var start_fill := game.grid.filled_slips()
	game.economy.prices["slip_fee"] = int(game.economy.prices["slip_fee"]) * 2
	## flush price lag
	game.force_months(12)
	var end_fill := game.grid.filled_slips()
	var f := 0
	f += _ok("double_fee_halves_occ", end_fill <= start_fill * 0.65 + 1, "start=%d end=%d" % [start_fill, end_fill])
	return f


func _check_storm_cover() -> int:
	var a := HarborGame.new()
	a.new_game("harbor_year", 3)
	var b := HarborGame.new()
	b.new_game("harbor_year", 3)
	## strip breakwater on a
	for i in a.grid.cells.size():
		if a.grid.cells[i] == SimCatalog.CELL_BREAKWATER:
			a.grid.cells[i] = SimCatalog.CELL_WATER
	a.economy.budget["insurance"] = 50
	b.economy.budget["insurance"] = 100
	var cash_a0 := a.economy.cash
	var cash_b0 := b.economy.cash
	a.events._storm(true, a.grid, a.economy)
	b.events._storm(true, b.grid, b.economy)
	var dmg_a := cash_a0 - a.economy.cash
	var dmg_b := cash_b0 - b.economy.cash
	var f := 0
	f += _ok("storm_worse_without_cover", dmg_a > dmg_b, "no_bw+50ins=%d full=%d" % [dmg_a, dmg_b])
	return f
