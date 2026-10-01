class_name SimEvents
extends RefCounted

## Seeded seasonal monthly events.

var rng := RandomNumberGenerator.new()
var last_roll: int = 1
var last_event: String = "quiet"
var last_text: String = ""
var last_damage: int = 0


func seed_rng(seed_value: int) -> void:
	rng.seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())


func roll(season: int, grid: HarborGrid, economy: SimEconomy, channel_open: bool) -> Dictionary:
	last_roll = rng.randi_range(1, 6)
	last_damage = 0
	last_event = _pick(season, last_roll)
	last_text = _apply(last_event, grid, economy, channel_open, season)
	return {
		"roll": last_roll,
		"event": last_event,
		"title": SimCatalog.EVENT_TITLES.get(last_event, last_event),
		"text": last_text,
		"damage": last_damage,
	}


func _pick(season: int, die: int) -> String:
	if die <= 2:
		return "quiet"
	if die <= 4:
		if season == SimCatalog.SPRING:
			return "new_crew"
		if season == SimCatalog.SUMMER:
			return "good_weekend"
		if season == SimCatalog.FALL:
			return "silting"
		return "quiet"
	if die == 5:
		match season:
			SimCatalog.WINTER:
				return "audit"
			SimCatalog.SPRING:
				return "haul_out"
			SimCatalog.SUMMER:
				return "storm"
			_:
				return "party_demand"
	match season:
		SimCatalog.WINTER:
			return "warm_winter"
		SimCatalog.SPRING:
			return "quiet"
		SimCatalog.SUMMER:
			return "bad_storm"
		_:
			return "surplus"


func _apply(ev: String, grid: HarborGrid, economy: SimEconomy, channel_open: bool, season: int) -> String:
	match ev:
		"quiet":
			return "Nothing loud on the water."
		"audit":
			var bill := 8000 if float(economy.budget["insurance"]) < 80 else 2500
			economy.cash -= bill
			return "Insurance audit costs %s." % SimCatalog.money(bill)
		"warm_winter":
			economy.cash += 3000
			return "A warm winter keeps a few boats paying."
		"new_crew":
			return "Two new crew signed the book."
		"haul_out":
			economy.cash -= 5000
			return "Haul-out delay eats %s." % SimCatalog.money(5000)
		"good_weekend":
			economy.cash += 6000
			return "A good bar weekend brings %s." % SimCatalog.money(6000)
		"storm", "bad_storm":
			return _storm(ev == "bad_storm", grid, economy)
		"party_demand":
			return "Members want a party on the lawn."
		"surplus":
			economy.cash += 4000
			return "A surplus note lands for %s." % SimCatalog.money(4000)
		"silting":
			_silt(grid, 15)
			return "The channel takes on silt."
		"regatta":
			economy.cash += 5000
			return "Regatta weekend clears %s." % SimCatalog.money(5000)
	return SimCatalog.EVENT_TITLES.get(ev, ev)


func _storm(bad: bool, grid: HarborGrid, economy: SimEconomy) -> String:
	var cover := 0.0
	var n := 0
	for y in range(18, 30):
		for x in range(30, 70):
			if grid.get_cell(x, y) == SimCatalog.CELL_PIER or grid.get_cell(x, y) == SimCatalog.CELL_SLIP:
				cover += grid.breakwater_cover_at(x, y)
				n += 1
	var avg_cover := cover / float(maxi(1, n))
	var insure := float(economy.budget["insurance"]) / 100.0
	var base := 45000 if bad else 22000
	var damage := int(base * (1.0 - avg_cover * 0.55) * (1.0 - insure * 0.4))
	last_damage = damage
	economy.cash -= damage
	## wear docks
	for i in grid.cells.size():
		if grid.cells[i] == SimCatalog.CELL_PIER or grid.cells[i] == SimCatalog.CELL_SLIP:
			var hit := 20 if bad else 10
			hit = int(hit * (1.0 - avg_cover * 0.5))
			grid.condition[i] = maxi(0, grid.condition[i] - hit)
	if bad and avg_cover < 0.35:
		_silt(grid, 40)
		return "A bad storm costs %s and fouls the channel." % SimCatalog.money(damage)
	return "A storm costs %s." % SimCatalog.money(damage)


func _silt(grid: HarborGrid, amount: int) -> void:
	for i in grid.cells.size():
		if grid.cells[i] == SimCatalog.CELL_CHANNEL:
			grid.silt[i] = mini(100, grid.silt[i] + amount)


func apply_decay(grid: HarborGrid, economy: SimEconomy, employed_dockmaster: bool) -> void:
	var maint := float(economy.budget["dock_maint"]) / 100.0
	var dredge := float(economy.budget["dredging"]) / 100.0
	for i in grid.cells.size():
		if grid.cells[i] == SimCatalog.CELL_PIER or grid.cells[i] == SimCatalog.CELL_SLIP:
			var wear := 3 if maint < 0.8 else (0 if maint >= 1.0 else 1)
			if maint > 1.0:
				grid.condition[i] = mini(100, grid.condition[i] + int((maint - 1.0) * 4))
			else:
				grid.condition[i] = maxi(0, grid.condition[i] - wear)
		if grid.cells[i] == SimCatalog.CELL_CHANNEL:
			var silt_add := 0
			if dredge <= 0.0:
				silt_add = 10
			elif dredge < 0.7:
				silt_add = 6
			elif dredge < 1.0:
				silt_add = 2
			if employed_dockmaster:
				silt_add = maxi(0, silt_add - 2)
			if dredge > 1.0:
				grid.silt[i] = maxi(0, grid.silt[i] - int((dredge - 1.0) * 8 + 4))
			elif dredge >= 1.0:
				grid.silt[i] = maxi(0, grid.silt[i] - 3)
			else:
				grid.silt[i] = mini(100, grid.silt[i] + silt_add)
