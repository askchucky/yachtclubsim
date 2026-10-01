class_name SimEconomy
extends RefCounted

## Monthly ledger, prices, budget, loans.

var cash: int = SimCatalog.OPENING_CASH_HARBOR
var loan: int = 0
var prices: Dictionary = SimCatalog.default_prices()
var budget: Dictionary = SimCatalog.default_budget()
var last_ledger: Dictionary = {}
var history: Array = [] ## monthly snapshots


func borrow(steps: int = 1) -> bool:
	steps = maxi(1, steps)
	loan += SimCatalog.LOAN_STEP * steps
	cash += SimCatalog.LOAN_STEP * steps
	return true


func repay(amount: int) -> int:
	var pay := mini(amount, mini(loan, cash))
	cash -= pay
	loan -= pay
	return pay


func insolvent() -> bool:
	return cash < SimCatalog.LOAN_FLOOR


func month_ledger(state: Dictionary) -> Dictionary:
	## state: members, slips_filled, slips_earning, has_bar, has_fuel, has_yard, has_office,
	## season, boat_moves, dock_tiles, channel_tiles
	var regular: int = int(state.get("regular", 0))
	var social: int = int(state.get("social", 0))
	var crew: int = int(state.get("crew", 0))
	var slips_earn: int = int(state.get("slips_earning", 0))
	var season: int = int(state.get("season", 0))

	## Monthly share of annual dues — Harbor Year ≈ break-even at defaults.
	var dues := (regular * int(prices["dues_regular"]) + social * int(prices["dues_social"]) + crew * int(prices["dues_crew"])) / 12
	dues = int(dues * 0.72)
	var slip_rent := slips_earn * int(prices["slip_fee"])
	var bar_rev := 0
	if bool(state.get("has_bar", false)):
		var fb := int(prices["fb_minimum"])
		bar_rev = (regular * fb + crew * 400) / 30
		bar_rev = int(bar_rev * (0.55 + float(state.get("demand_bar", 50)) / 220.0))
	var fuel_rev := 0
	if bool(state.get("has_fuel", false)):
		fuel_rev = int(state.get("boat_moves", 0)) * 14
	var yard_rev := 0
	if bool(state.get("has_yard", false)) and season == SimCatalog.SPRING:
		yard_rev = slips_earn * 30

	var income := dues + slip_rent + bar_rev + fuel_rev + yard_rev

	var staff_base := 11000
	if bool(state.get("has_bar", false)):
		staff_base += 2800
	if bool(state.get("has_yard", false)):
		staff_base += 3000
	if bool(state.get("has_office", false)):
		staff_base += 2000
	var staff_pay := int(staff_base * float(budget["staff_pay"]) / 100.0)
	var dredge := int(2000 * float(budget["dredging"]) / 100.0)
	var docks := int(int(state.get("dock_tiles", 0)) * 11 * float(budget["dock_maint"]) / 100.0)
	var insure := int(5200 * float(budget["insurance"]) / 100.0)
	var racing := int(1800 * float(budget["racing"]) / 100.0)
	var social_ev := int(1500 * float(budget["social"]) / 100.0)
	var interest := int(ceil(float(loan) * SimCatalog.LOAN_RATE))
	var upkeep_extra: int = int(state.get("building_upkeep", 0))

	var expense := staff_pay + dredge + docks + insure + racing + social_ev + interest + upkeep_extra
	var net := income - expense
	cash += net
	if loan > 0:
		var auto := mini(loan, maxi(0, net / 4))
		repay(auto)

	last_ledger = {
		"dues": dues,
		"slip_rent": slip_rent,
		"bar": bar_rev,
		"fuel": fuel_rev,
		"yard": yard_rev,
		"income": income,
		"staff": staff_pay,
		"dredging": dredge,
		"docks": docks,
		"insurance": insure,
		"racing": racing,
		"social": social_ev,
		"interest": interest,
		"upkeep": upkeep_extra,
		"expense": expense,
		"net": net,
		"cash": cash,
		"loan": loan,
	}
	history.append({"cash": cash, "net": net, "members": regular + social + crew, "slips": slips_earn})
	if history.size() > 48:
		history.pop_front()
	return last_ledger


func building_upkeep(grid: HarborGrid) -> int:
	var total := 0
	var counts := {}
	for v in grid.cells:
		counts[v] = int(counts.get(v, 0)) + 1
	for t in SimCatalog.tools():
		var cell: int = int(t["cell"])
		if cell < 0:
			continue
		total += int(counts.get(cell, 0)) * int(t["upkeep"])
	return total


func to_dict() -> Dictionary:
	return {
		"cash": cash,
		"loan": loan,
		"prices": prices.duplicate(),
		"budget": budget.duplicate(),
		"history": history.duplicate(),
	}


func from_dict(d: Dictionary) -> void:
	cash = int(d.get("cash", cash))
	loan = int(d.get("loan", 0))
	prices = SimCatalog.default_prices()
	prices.merge(d.get("prices", {}), true)
	budget = SimCatalog.default_budget()
	budget.merge(d.get("budget", {}), true)
	history = d.get("history", [])
