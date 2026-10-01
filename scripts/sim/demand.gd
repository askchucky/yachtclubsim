class_name SimDemand
extends RefCounted

## Demand meters, slip occupancy, member drift. Price lag 2-3 months.

var slips: float = 55.0
var bar: float = 50.0
var racing: float = 45.0
var members: float = 55.0
var price_lag: Array = [] ## queued price snapshots


func push_prices(prices: Dictionary) -> void:
	price_lag.append(prices.duplicate())
	if price_lag.size() > 3:
		price_lag.pop_front()


func effective_prices(current: Dictionary) -> Dictionary:
	if price_lag.is_empty():
		return current
	return price_lag[0]


func update(grid: HarborGrid, economy: SimEconomy, season: int, channel_open: bool) -> void:
	var slip_n := grid.slip_count()
	var cond := grid.average_dock_condition()
	var bw := 0.0
	var samples := 0
	for y in range(16, 30):
		for x in range(30, 70):
			bw += grid.breakwater_cover_at(x, y)
			samples += 1
	bw = bw / float(maxi(1, samples))
	var ep := effective_prices(economy.prices)
	## Neutral near opening slip fee ($420).
	var fee := float(ep["slip_fee"])
	var fee_factor := clampf(1.0 - (fee - 420.0) / 800.0, 0.3, 1.35)
	slips = clampf(40.0 + slip_n * 0.5 + cond * 0.15 + bw * 25.0 + (10.0 if channel_open else -30.0), 0.0, 100.0)
	slips *= fee_factor
	slips = clampf(slips, 0.0, 100.0)

	bar = clampf(30.0 + (25.0 if grid.has_building(SimCatalog.CELL_BAR) else 0.0) + float(economy.budget["social"]) * 0.15, 0.0, 100.0)
	racing = clampf(25.0 + (30.0 if grid.has_building(SimCatalog.CELL_RACE) else 0.0) + float(economy.budget["racing"]) * 0.2, 0.0, 100.0)
	## Neutral near opening Regular dues ($2,375); hike cools demand, cuts warm it.
	var dues := float(ep["dues_regular"])
	var dues_factor := clampf(1.0 - (dues - 2375.0) / 4000.0, 0.45, 1.25)
	members = clampf((slips + bar + racing) / 3.0 * dues_factor, 0.0, 100.0)
	if season == SimCatalog.SUMMER:
		bar = mini(100.0, bar + 5.0)
		racing = mini(100.0, racing + 5.0)
	push_prices(economy.prices)


func apply_occupancy(grid: HarborGrid, channel_open: bool) -> void:
	var target_rate := slips / 100.0
	if not channel_open:
		target_rate *= 0.35
	var slip_idxs: Array[int] = []
	for i in grid.cells.size():
		if grid.cells[i] == SimCatalog.CELL_SLIP:
			slip_idxs.append(i)
	var n := slip_idxs.size()
	if n == 0:
		return
	var want := int(round(float(n) * target_rate))
	var have := grid.filled_slips()
	if have < want:
		for i in slip_idxs:
			if grid.slip_filled[i] == 0:
				grid.slip_filled[i] = 1
				have += 1
				if have >= want:
					break
	elif have > want:
		for i in range(slip_idxs.size() - 1, -1, -1):
			var si: int = slip_idxs[i]
			if grid.slip_filled[si] == 1:
				grid.slip_filled[si] = 0
				have -= 1
				if have <= want:
					break


func drift_members(regular: int, social: int, crew: int, cap: int) -> Dictionary:
	var total := regular + social + crew
	## Map demand 0-100 onto a soft target; keep default harbor near opening roster.
	var target := int(80 + (cap - 80) * members / 100.0)
	target = clampi(target, 80, cap)
	var delta := clampi(target - total, -4, 6)
	if delta > 0:
		var add_reg := delta / 2
		var add_soc := delta / 3
		var add_crew := delta - add_reg - add_soc
		regular += add_reg
		social += add_soc
		crew += add_crew
	elif delta < 0:
		var leave := -delta
		var from_crew := mini(crew, leave / 3)
		crew -= from_crew
		leave -= from_crew
		var from_soc := mini(social, leave / 2)
		social -= from_soc
		leave -= from_soc
		regular = maxi(0, regular - leave)
	## soft caps
	while regular + social + crew > cap:
		if crew > 0:
			crew -= 1
		elif social > 0:
			social -= 1
		else:
			regular = maxi(0, regular - 1)
	return {"regular": regular, "social": social, "crew": crew}


func to_dict() -> Dictionary:
	return {"slips": slips, "bar": bar, "racing": racing, "members": members, "price_lag": price_lag.duplicate()}


func from_dict(d: Dictionary) -> void:
	slips = float(d.get("slips", 55))
	bar = float(d.get("bar", 50))
	racing = float(d.get("racing", 45))
	members = float(d.get("members", 55))
	price_lag = d.get("price_lag", [])
