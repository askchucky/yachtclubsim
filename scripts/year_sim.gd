class_name YearSim
extends RefCounted

var year := 1; var season := 0; var cash := 0
var regular := 0; var social := 0; var crew := 0; var slips_filled := 0
var channel_open := true
var demand_slips := 3; var demand_bar := 3; var demand_racing := 3
var moods := {}; var employed := {}
var insurance_high := false; var dredge_cheap := false; var dredge_rolled := false
var receivables_open := 0; var receivables_ignored := false; var chased := false
var recv_summer := 0; var recv_fall := 0; var recruit_passed := false
var due_num := 1; var due_den := 1; var due_hike_pending := false
var regatta_funded := false; var regatta_last := false; var party_funded := false
var summers_without_party := 0; var did_overtime := false
var docks_deferred := false; var spring_dock_bill := 0; var bonus_paid := false
var backer := ""; var pending_slip_loss := 0; var close_queued := 0
var closed_this_year := false; var last_die := 1; var last_event := "quiet"
var speaker := "commodore"; var note := ""; var intro_pending := true
var portrait_hold := ""; var outcome := ""; var mood_deltas := {}
var quit_happened := false; var forced_rolls: Array = []
var rng := RandomNumberGenerator.new()

const _INTS := ["year", "season", "cash", "regular", "social", "crew", "slips_filled", "demand_slips", "demand_bar", "demand_racing", "receivables_open", "recv_summer", "recv_fall", "due_num", "due_den", "summers_without_party", "spring_dock_bill", "pending_slip_loss", "close_queued", "last_die"]
const _BOOLS := ["channel_open", "insurance_high", "dredge_cheap", "dredge_rolled", "receivables_ignored", "chased", "recruit_passed", "due_hike_pending", "regatta_funded", "regatta_last", "party_funded", "did_overtime", "docks_deferred", "bonus_paid", "closed_this_year", "intro_pending"]
const _STRS := ["backer", "last_event", "speaker", "note", "portrait_hold", "outcome"]


func _init() -> void:
	fresh(1)


func fresh(seed_value: int = 0) -> void:
	rng.seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system()) + randi() % 100000
	year = 1; season = SimData.WINTER; cash = SimData.OPENING_CASH
	regular = 140; social = 45; crew = 15; slips_filled = 36
	demand_slips = 3; demand_bar = 3; demand_racing = 3
	moods = {"commodore": 1, "vice": 0, "rear": 0, "helen": 1, "marco": 0, "june": 0, "pete": 0, "ruth": 1, "chris": 0, "dan": -1, "sam": 0, "penny": 0, "dockmaster": 0, "bar_manager": 0, "bookkeeper": 0, "yard_boss": 0}
	employed = {"dockmaster": true, "bar_manager": true, "bookkeeper": true, "yard_boss": true}
	for key in _BOOLS:
		set(key, key == "channel_open" or key == "intro_pending")
	receivables_open = SimData.RECEIVABLES
	recv_summer = 0; recv_fall = 0; due_num = 1; due_den = 1; summers_without_party = 0
	spring_dock_bill = 0; pending_slip_loss = 0; close_queued = 0; last_die = 1
	last_event = "quiet"; speaker = "commodore"; note = ""; portrait_hold = ""; outcome = ""
	mood_deltas = {}; quit_happened = false; forced_rolls = []


func members() -> int:
	return regular + social + crew


func season_name() -> String:
	return SimData.SEASONS[season]


func moving_count() -> int:
	return SimData.moving_count(slips_filled, season, channel_open)


func empty_jobs() -> Array:
	var out: Array = []
	for role in SimData.STAFF:
		if not bool(employed[role]):
			out.append(role)
	return out


func prepare_season() -> void:
	if pending_slip_loss > 0:
		slips_filled = maxi(0, slips_filled - pending_slip_loss)
		pending_slip_loss = 0
	if close_queued > 0:
		channel_open = false
		close_queued -= 1
		closed_this_year = true
	else:
		channel_open = true
	if season != SimData.SPRING:
		return
	for role in SimData.STAFF:
		if not bool(employed[role]):
			employed[role] = true
			moods[role] = 0


func resolve(spend: String, politics: String) -> void:
	mood_deltas = {}; quit_happened = false; note = ""; portrait_hold = ""
	_arm_season()
	var vote_ok := _politics(politics)
	var spend_ok := vote_ok and int(moods["commodore"]) > -2
	if int(moods["commodore"]) <= -2 and vote_ok:
		note = "the commodore cancelled the spend"
	if not vote_ok:
		note = "the vote failed and the spend was cancelled"
	if spend_ok:
		_spend(spend)
	if season == SimData.SPRING and not chased and receivables_open > 0:
		receivables_ignored = true
		receivables_open = 0
	if season == SimData.SUMMER:
		_summer_followthrough()
	_event(); _ledger(); _people(); _harbor()
	speaker = _speaker()
	intro_pending = false
	if cash < 0:
		outcome = "insolvent"
	elif season == SimData.FALL:
		_close_year()
	else:
		season += 1
		outcome = ""


func continue_next_winter() -> void:
	regatta_last = regatta_funded
	if due_hike_pending:
		due_num *= 11
		due_den *= 10
		due_hike_pending = false
	year += 1
	season = SimData.WINTER
	outcome = ""; intro_pending = false
	portrait_hold = "Commodore: winter opens, and the cash carried."
	for key in ["docks_deferred", "insurance_high", "dredge_cheap", "dredge_rolled", "bonus_paid", "recruit_passed", "chased", "receivables_ignored", "party_funded", "regatta_funded", "did_overtime", "closed_this_year"]:
		set(key, false)
	receivables_open = 0; recv_summer = 0; recv_fall = 0
	backer = ""; note = ""; speaker = "commodore"


func to_dict() -> Dictionary:
	var d := {"v": 1, "moods": moods.duplicate(), "employed": employed.duplicate(), "mood_deltas": mood_deltas.duplicate(), "rng_seed": rng.seed, "rng_state": rng.state}
	for key in _INTS + _BOOLS + _STRS:
		d[key] = get(key)
	return d


func from_dict(d: Dictionary) -> void:
	for key in _INTS:
		set(key, int(d[key]))
	for key in _BOOLS:
		set(key, bool(d[key]))
	for key in _STRS:
		set(key, str(d[key]))
	moods = {}; employed = {}; mood_deltas = {}
	for k in d["moods"].keys():
		moods[str(k)] = int(d["moods"][k])
	for k in d["employed"].keys():
		employed[str(k)] = bool(d["employed"][k])
	for k in d["mood_deltas"].keys():
		mood_deltas[str(k)] = int(d["mood_deltas"][k])
	rng.seed = int(d["rng_seed"]); rng.state = int(d["rng_state"])


func _arm_season() -> void:
	if season == SimData.WINTER:
		insurance_high = false; dredge_cheap = false; dredge_rolled = false
	elif season == SimData.SPRING:
		recruit_passed = false; chased = false; did_overtime = false; receivables_ignored = false
	elif season == SimData.SUMMER:
		regatta_funded = false; party_funded = false; backer = ""
	else:
		bonus_paid = false


func _rate(base: int) -> int:
	return base * due_num / due_den


func _demand(key: String, delta: int) -> void:
	if key == "slips":
		demand_slips = clampi(demand_slips + delta, 0, 4)
	elif key == "bar":
		demand_bar = clampi(demand_bar + delta, 0, 4)
	else:
		demand_racing = clampi(demand_racing + delta, 0, 4)


func _set_mood(id: String, value: int) -> void:
	var v := clampi(value, -2, 2)
	var prev := int(moods[id])
	moods[id] = v
	mood_deltas[id] = int(mood_deltas.get(id, 0)) + (v - prev)


func _bump(id: String, delta: int) -> void:
	_set_mood(id, int(moods[id]) + delta)


func _quit(role: String) -> bool:
	if not bool(employed.get(role, false)):
		return false
	_set_mood(role, -2)
	employed[role] = false
	quit_happened = true
	return true


func _d6() -> int:
	last_die = int(forced_rolls.pop_front()) if forced_rolls.size() > 0 else rng.randi_range(1, 6)
	return last_die


func _vote(kind: String) -> bool:
	var yes := 3 if kind == "recruit" else 2
	var need := 3
	if kind == "dues":
		yes += (1 if regatta_last else 0)
		if int(moods["commodore"]) >= 2:
			need = 2
	elif kind == "assessment":
		yes += (1 if regatta_funded else 0)
	if yes >= need:
		return true
	var allies: Array = ["helen", "ruth"] if kind == "recruit" else ["june", "penny"]
	var racer_no := (kind == "dues" and not regatta_last) or (kind == "assessment" and not regatta_funded)
	if racer_no:
		allies.append("marco")
	for ally in allies:
		_bump(str(ally), 1)
	return false


func _politics(id: String) -> bool:
	if id == "commodore_back":
		backer = "commodore"
	elif id == "racer_run":
		backer = "racer"
	elif id == "cut_dues":
		var annual := regular * _rate(SimData.REG_DUES) + social * _rate(SimData.SOC_DUES) + crew * _rate(SimData.CREW_DUES)
		cash -= annual * 5 / 100
		_bump("june", 1)
	elif id == "reshuffle":
		_bump("helen", 1); _bump("june", -1)
	elif id == "dues_hike":
		if not _vote("dues"):
			return false
		due_hike_pending = true
		_set_mood("ruth", -2)
	elif id == "recruit":
		if not _vote("recruit"):
			return false
		recruit_passed = true
	elif id == "assessment":
		if not _vote("assessment"):
			return false
		cash += regular * 300 + social * 150
	return true


func _spend(id: String) -> void:
	if id == "high_deductible":
		insurance_high = true
	elif id == "cheap_dredge":
		dredge_cheap = int(moods["vice"]) > -2
	elif id == "full":
		insurance_high = false; dredge_cheap = false
	elif id == "overtime":
		did_overtime = true
		cash -= 15000
		if bool(employed["yard_boss"]) and slips_filled < SimData.SLIP_CAP:
			slips_filled += mini(2, SimData.SLIP_CAP - slips_filled)
	elif id == "chase":
		chased = true
		var amount := receivables_open * (90 if bool(employed["bookkeeper"]) else 75) / 100
		recv_summer = amount / 2
		recv_fall = amount - recv_summer
		receivables_open = 0
	elif id == "regatta":
		regatta_funded = true
		cash -= (15000 if int(moods["rear"]) >= 2 else 25000)
	elif id == "party":
		party_funded = true
		cash -= 18000
		var ok := bool(employed["bar_manager"]) and int(moods["bar_manager"]) >= 0
		cash += (30000 if ok else 8000)
	elif id == "bonus":
		bonus_paid = true
		cash -= 20000
	elif id == "defer":
		docks_deferred = true
		spring_dock_bill += 40000
		_demand("slips", -1)


func _summer_followthrough() -> void:
	if regatta_funded:
		var on_side := int(moods["marco"]) >= 1 or backer == "racer"
		if on_side:
			if int(moods["rear"]) > -2:
				_demand("racing", 1)
			cash += 1600
		if int(moods["marco"]) <= -1:
			_bump("marco", -1)
	else:
		_demand("racing", -1)
	if party_funded:
		if bool(employed["bar_manager"]):
			_demand("bar", 1)
		summers_without_party = 0
	else:
		summers_without_party += 1
		if summers_without_party >= 2:
			_demand("bar", -1)
			summers_without_party = 0


func _event() -> void:
	last_event = SimData.event_for(season, _d6())
	match last_event:
		"audit":
			if insurance_high:
				cash -= 25000
		"warm_winter":
			cash += 20000
		"new_crew":
			crew += mini(2, maxi(0, SimData.MEMBER_CAP - members()))
		"haul_out":
			if not did_overtime:
				slips_filled = maxi(0, slips_filled - 2)
		"good_weekend":
			cash += 12000
		"storm":
			cash -= (100000 if insurance_high else 60000)
			pending_slip_loss += 2
		"bad_storm":
			cash -= (180000 if insurance_high else 140000)
			close_queued += 1
			_demand("slips", -1); _demand("racing", -1)
		"party_demand":
			if not party_funded:
				_bump("june", -1)


func _ledger() -> void:
	var income := regular * SimData.quarter_share(_rate(SimData.REG_DUES), season)
	income += social * SimData.quarter_share(_rate(SimData.SOC_DUES), season)
	income += crew * SimData.quarter_share(_rate(SimData.CREW_DUES), season)
	income += (regular + social) * (SimData.FB_REG / 4) + crew * (SimData.FB_CREW / 4)
	if channel_open:
		income += slips_filled * 2000
	if season == SimData.SPRING:
		income += (25000 if recruit_passed else 8000)
	elif season == SimData.SUMMER:
		income += recv_summer
	elif season == SimData.FALL:
		income += recv_fall
	var empty := 0
	for role in SimData.STAFF:
		if not bool(employed[role]):
			empty += 1
	var docks := 20000
	if season == SimData.SPRING and spring_dock_bill > 0:
		docks += spring_dock_bill
		spring_dock_bill = 0
	var costs := (35000 if insurance_high else 45000) + (22500 if dredge_cheap else 40000)
	costs += 105000 - 15000 * empty + docks + 17500 + 3750
	cash += income - costs


func _people() -> void:
	if not channel_open or docks_deferred:
		_set_mood("helen", -2)
	if season == SimData.SUMMER and not regatta_funded:
		_set_mood("marco", -2)
	if season == SimData.SUMMER and not party_funded:
		_set_mood("june", -2)
	if season == SimData.SPRING and not recruit_passed:
		_set_mood("chris", -2)
	if season == SimData.SPRING and chased:
		_set_mood("dan", 0)
	elif season == SimData.SPRING and receivables_ignored:
		_set_mood("dan", -2)
	if season == SimData.FALL:
		var step := 1 if bonus_paid else -1
		for role in SimData.STAFF:
			if bool(employed[role]):
				_bump(role, step)
		if docks_deferred:
			_quit("dockmaster")
		if not party_funded and _quit("bar_manager"):
			_demand("bar", -1)
		if receivables_ignored:
			_quit("bookkeeper")
	if season != SimData.WINTER and not did_overtime and demand_slips <= 1:
		_quit("yard_boss")
	if quit_happened:
		_set_mood("sam", -2)


func _harbor() -> void:
	if season != SimData.WINTER or not dredge_cheap or dredge_rolled:
		return
	dredge_rolled = true
	var chance := 25
	if int(moods["vice"]) >= 2:
		chance = 0
	elif bool(employed["dockmaster"]):
		chance = 10
	if chance > 0 and rng.randi() % 100 < chance:
		close_queued += 1
		_demand("slips", -1)


func _speaker() -> String:
	var best := "commodore"; var best_abs := 0; var best_mood := 0
	for id in moods.keys():
		var delta := int(mood_deltas.get(id, 0))
		var mag := absi(delta)
		if mag > best_abs or (mag == best_abs and mag > 0 and delta < best_mood):
			best = str(id); best_abs = mag; best_mood = delta
	return best


func _close_year() -> void:
	receivables_open = 0; recv_summer = 0; recv_fall = 0
	if not closed_this_year and not docks_deferred:
		_demand("slips", 1)
	if demand_slips <= 1:
		slips_filled = maxi(0, slips_filled - 6)
	elif demand_slips >= 4:
		slips_filled = SimData.SLIP_CAP
		regular += mini(3, maxi(0, SimData.MEMBER_CAP - members()))
	if demand_bar <= 1:
		social = maxi(0, social - 4)
	elif demand_bar >= 4:
		social += mini(3, maxi(0, SimData.MEMBER_CAP - members()))
	if demand_racing <= 1:
		regular = maxi(0, regular - 6)
	elif demand_racing >= 4:
		regular += mini(3, maxi(0, SimData.MEMBER_CAP - members()))
	slips_filled = clampi(slips_filled, 0, SimData.SLIP_CAP)
	if cash < 0:
		outcome = "insolvent"
	elif cash == 0:
		outcome = "zero"
	elif members() < 140:
		outcome = "hollow"
	else:
		outcome = "solvent"
