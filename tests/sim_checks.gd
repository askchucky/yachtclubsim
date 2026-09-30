extends SceneTree

var fails: Array = []


func _init() -> void:
	_opening()
	_money()
	_boats()
	_sentences()
	var quiet := _play([1, 1, 1, 1], ["full", "spring_quiet", "bank", "patch"], ["hold_dues", "reshuffle", "commodore_back", "no_assessment"])
	_check(quiet["cash"] == 51375, "quiet cash %s expected 51375" % quiet["cash"])
	_check(absi(int(quiet["cash"]) - 51250) <= 250, "quiet cash %s is not near 51250" % quiet["cash"])
	_check(quiet["outcome"] == "solvent", "quiet outcome %s" % quiet["outcome"])
	_check(int(quiet["members"]) >= 140, "quiet members")
	_check(int(quiet["cash"]) > 0, "quiet solvent cash")
	print("QUIET cash=%s outcome=%s members=%s slips=%s" % [quiet["cash"], quiet["outcome"], quiet["members"], quiet["slips"]])

	var bust := _play([1, 1, 6], ["high_deductible", "spring_quiet", "bank"], ["hold_dues", "reshuffle", "commodore_back"])
	_check(bust["cash"] == -86845, "bust cash %s expected -86845" % bust["cash"])
	_check(int(bust["cash"]) < 0, "bust still has cash")
	_check(bust["outcome"] == "insolvent", "bust outcome %s" % bust["outcome"])
	_check(bust["insurance_high"], "bust did not keep the high deductible")
	print("BUST cash=%s outcome=%s" % [bust["cash"], bust["outcome"]])

	var live := _play([1, 1, 1, 1], ["full", "chase", "bank", "patch"], ["hold_dues", "recruit", "commodore_back", "no_assessment"])
	_check(live["cash"] == 167375, "survive cash %s expected 167375" % live["cash"])
	_check(live["outcome"] == "solvent", "survive outcome %s" % live["outcome"])
	_check(int(live["cash"]) > 0 and int(live["members"]) >= 140, "survive not solvent")
	_check(live["recruit_passed"], "recruit vote did not pass")
	_check(live["chased"], "Dan was not chased")
	_check(int(live["dan"]) == 0, "Dan mood %s" % live["dan"])
	_check(not live["dredge_cheap"], "survive used a cheap dredge")
	_check(live["channel_open"], "survive channel closed")
	_check(SimData.boats_can_move(int(live["season"]), bool(live["channel_open"])), "boats blocked on an open non-winter harbor")
	_check(int(live["moving"]) > 0, "no moving boats")
	print("SURVIVE cash=%s outcome=%s season=%s channel=%s moving=%s" % [live["cash"], live["outcome"], live["season_name"], live["channel_open"], live["moving"]])

	var zero := YearSim.new()
	zero.cash = 0
	zero.season = SimData.FALL
	zero._close_year()
	_check(zero.outcome == "zero", "zero-cash outcome %s" % zero.outcome)
	_check(SimData.outcome_line("zero").count(".") == 1, "zero line is not one sentence")
	print("ZERO outcome=%s line=%s" % [zero.outcome, SimData.outcome_line("zero")])

	print("CHECKS failed=%d" % fails.size())
	quit(1 if fails.size() > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
		print("FAIL ", msg)


func _opening() -> void:
	var sim := YearSim.new()
	sim.fresh(1)
	_check(sim.cash == 90000, "opening cash")
	_check(sim.members() == 200, "opening members")
	_check(sim.slips_filled == 36, "opening slips")
	_check(sim.season_name() == "Winter", "opening season")
	_check(sim.demand_slips == 3 and sim.demand_bar == 3 and sim.demand_racing == 3, "opening demand")
	_check(sim.channel_open and sim.intro_pending and not sim.insurance_high, "opening flags")
	_check(PortraitBox.compose(sim).find("thin reserve") >= 0, "missing thin reserve line")
	_hud(sim)
	var copy := YearSim.new()
	copy.from_dict(sim.to_dict())
	_check(copy.cash == 90000 and copy.moods["dan"] == -1 and copy.moods["commodore"] == 1, "save roundtrip")


func _money() -> void:
	_check(SimData.money(51250) == "$51,250", SimData.money(51250))
	_check(SimData.money(90000) == "$90,000", SimData.money(90000))
	_check(SimData.money(-86845) == "-$86,845", SimData.money(-86845))
	_check(SimData.money(0) == "$0", SimData.money(0))


func _boats() -> void:
	_check(not SimData.boats_can_move(SimData.WINTER, true), "winter boats moved")
	_check(not SimData.boats_can_move(SimData.SUMMER, false), "closed channel boats moved")
	_check(SimData.boats_can_move(SimData.SUMMER, true), "summer boats stayed tied")
	_check(SimData.boats_can_move(SimData.SPRING, true), "spring boats stayed tied")
	_check(SimData.boats_can_move(SimData.FALL, true), "fall boats stayed tied")
	_check(SimData.moving_count(36, SimData.WINTER, true) == 0, "winter count")
	_check(SimData.moving_count(36, SimData.SUMMER, false) == 0, "closed count")
	_check(SimData.moving_count(36, SimData.SUMMER, true) == 16, "summer count")
	_check(SimData.moving_count(36, SimData.SPRING, true) == 16, "spring count")
	_check(SimData.moving_count(10, SimData.SPRING, true) == 6, "spring scale")


func _sentences() -> void:
	for code in ["insolvent", "hollow", "zero"]:
		var line := SimData.outcome_line(code)
		_check(line.count(".") == 1, "%s sentence: %s" % [code, line])


func _hud(sim: YearSim) -> void:
	_check(HarborHud.cash_text(sim) == "Cash %s" % SimData.money(sim.cash), HarborHud.cash_text(sim))
	_check(HarborHud.members_text(sim) == "Members %d" % sim.members(), HarborHud.members_text(sim))
	_check(HarborHud.slips_text(sim) == "Slips %d/%d" % [sim.slips_filled, SimData.SLIP_CAP], HarborHud.slips_text(sim))
	_check(HarborHud.season_text(sim).begins_with("Season %s" % sim.season_name()), HarborHud.season_text(sim))
	_check(HarborHud.reserve_text() == "Reserve %s" % SimData.money(SimData.RESERVE), HarborHud.reserve_text())
	var demand: Array = HarborHud.demand_values(sim)
	_check(int(demand[0]) == sim.demand_slips and int(demand[1]) == sim.demand_bar and int(demand[2]) == sim.demand_racing, "demand pips")


func _play(rolls: Array, spends: Array, politics: Array) -> Dictionary:
	var sim := YearSim.new()
	sim.fresh(1)
	sim.forced_rolls = rolls.duplicate()
	var path: Array = []
	for i in spends.size():
		sim.resolve(str(spends[i]), str(politics[i]))
		path.append(sim.cash)
		_hud(sim)
		if i == 0:
			var line := PortraitBox.compose(sim)
			_check(line.find("Die") >= 0 and line.find(str(sim.last_die)) >= 0, "portrait missing die: %s" % line)
			_check(line.find(SimData.EVENT_TITLES[sim.last_event]) >= 0, "portrait missing event: %s" % line)
		if sim.outcome != "":
			break
		sim.prepare_season()
		_hud(sim)
	print("  path ", path, " season ", sim.season_name(), " outcome ", sim.outcome)
	return {
		"cash": sim.cash,
		"outcome": sim.outcome,
		"members": sim.members(),
		"slips": sim.slips_filled,
		"insurance_high": sim.insurance_high,
		"recruit_passed": sim.recruit_passed,
		"chased": sim.chased,
		"dan": sim.moods["dan"],
		"dredge_cheap": sim.dredge_cheap,
		"channel_open": sim.channel_open,
		"season": sim.season,
		"season_name": sim.season_name(),
		"moving": sim.moving_count(),
	}
