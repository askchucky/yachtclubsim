class_name SimCatalog
extends RefCounted

## Tools, buildings, prices, constants. No sprite data.

const TILE := 16
const SCALE := 2
const MAP_W := 96
const MAP_H := 54

const WINTER := 0
const SPRING := 1
const SUMMER := 2
const FALL := 3
const SEASONS := ["Winter", "Spring", "Summer", "Fall"]
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

const OPENING_CASH_HARBOR := 90000
const OPENING_CASH_EMPTY := 250000
const RESERVE_TARGET := 150000
const LOAN_STEP := 50000
const LOAN_RATE := 0.005 ## monthly interest
const LOAN_FLOOR := -200000 ## insolvent below this
const MEMBER_MIN_HOLLOW := 140

const CELL_EMPTY := 0
const CELL_WATER := 1
const CELL_DEEP := 2
const CELL_SHALLOW := 3
const CELL_CHANNEL := 4
const CELL_GRASS := 5
const CELL_SAND := 6
const CELL_PIER := 10
const CELL_SLIP := 11
const CELL_BREAKWATER := 12
const CELL_CLUBHOUSE := 20
const CELL_BAR := 21
const CELL_FUEL := 22
const CELL_YARD := 23
const CELL_RACE := 24
const CELL_OFFICE := 25
const CELL_PATH := 30
const CELL_TREE := 31
const CELL_FLOWERS := 32
const CELL_LIGHTS := 33

const STAFF := ["dockmaster", "bar_manager", "bookkeeper", "yard_boss"]
const MEMBERS := ["helen", "marco", "june", "pete", "ruth", "chris", "dan", "sam"]
const FLAGS := ["commodore", "vice", "rear"]
const BOARD := ["slip_hawk", "social", "penny", "racer", "old_guard"]

const NAMES := {
	"commodore": "Commodore",
	"vice": "Vice Commodore",
	"rear": "Rear Commodore",
	"helen": "Helen",
	"marco": "Marco",
	"june": "June",
	"pete": "Pete",
	"ruth": "Ruth",
	"chris": "Chris",
	"dan": "Dan",
	"sam": "Sam",
	"penny": "Penny-pincher",
	"dockmaster": "Dockmaster",
	"bar_manager": "Bar manager",
	"bookkeeper": "Bookkeeper",
	"yard_boss": "Yard boss",
	"slip_hawk": "Slip hawk",
	"social": "Social spender",
	"racer": "Racer",
	"old_guard": "Old guard",
}

const EVENT_TITLES := {
	"quiet": "a quiet stretch",
	"audit": "an insurance audit",
	"warm_winter": "a warm winter",
	"new_crew": "two new crew",
	"haul_out": "a haul-out delay",
	"good_weekend": "a good weekend at the bar",
	"storm": "a storm",
	"bad_storm": "a bad storm",
	"party_demand": "members asking for a party",
	"surplus": "a surplus note",
	"silting": "channel silting",
	"regatta": "a regatta weekend",
}


static func tools() -> Array:
	return [
		{"id": "pier", "label": "Pier", "cost": 2500, "upkeep": 40, "cell": CELL_PIER},
		{"id": "slip", "label": "Slip", "cost": 1800, "upkeep": 25, "cell": CELL_SLIP},
		{"id": "breakwater", "label": "Breakwater", "cost": 4000, "upkeep": 30, "cell": CELL_BREAKWATER},
		{"id": "dredge", "label": "Dredge", "cost": 3000, "upkeep": 0, "cell": CELL_CHANNEL},
		{"id": "clubhouse", "label": "Clubhouse", "cost": 25000, "upkeep": 200, "cell": CELL_CLUBHOUSE},
		{"id": "bar", "label": "Bar", "cost": 12000, "upkeep": 150, "cell": CELL_BAR},
		{"id": "fuel", "label": "Fuel dock", "cost": 8000, "upkeep": 80, "cell": CELL_FUEL},
		{"id": "yard", "label": "Haul-out", "cost": 18000, "upkeep": 180, "cell": CELL_YARD},
		{"id": "race", "label": "Race hut", "cost": 9000, "upkeep": 90, "cell": CELL_RACE},
		{"id": "office", "label": "Office", "cost": 10000, "upkeep": 100, "cell": CELL_OFFICE},
		{"id": "path", "label": "Path", "cost": 200, "upkeep": 2, "cell": CELL_PATH},
		{"id": "tree", "label": "Tree", "cost": 150, "upkeep": 1, "cell": CELL_TREE},
		{"id": "flowers", "label": "Flowers", "cost": 100, "upkeep": 1, "cell": CELL_FLOWERS},
		{"id": "lights", "label": "Lights", "cost": 400, "upkeep": 8, "cell": CELL_LIGHTS},
		{"id": "bulldoze", "label": "Bulldoze", "cost": 500, "upkeep": 0, "cell": -1},
	]


static func tool_by_id(id: String) -> Dictionary:
	for t in tools():
		if t["id"] == id:
			return t
	return {}


static func default_prices() -> Dictionary:
	return {
		"dues_regular": 2375,
		"dues_social": 1385,
		"dues_crew": 550,
		"slip_fee": 420,
		"fb_minimum": 980,
		"initiation": 2500,
	}


static func default_budget() -> Dictionary:
	return {
		"dredging": 100,
		"dock_maint": 100,
		"insurance": 100,
		"staff_pay": 100,
		"racing": 100,
		"social": 100,
	}


static func is_water(cell: int) -> bool:
	return cell == CELL_WATER or cell == CELL_DEEP or cell == CELL_SHALLOW or cell == CELL_CHANNEL


static func is_land(cell: int) -> bool:
	return cell == CELL_GRASS or cell == CELL_SAND


static func is_buildable_overlay(cell: int) -> bool:
	return cell >= CELL_PIER


static func money(n: int) -> String:
	var neg := n < 0
	var digits := str(absi(n))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = digits[i] + out
		count += 1
	return ("-$" if neg else "$") + out


static func season_of_month(month: int) -> int:
	## month 0..11, Winter=Dec/Jan/Feb
	if month == 11 or month <= 1:
		return WINTER
	if month <= 4:
		return SPRING
	if month <= 7:
		return SUMMER
	return FALL


static func moving_count(filled: int, season: int, channel_open: bool) -> int:
	if not channel_open or season == WINTER:
		return 0
	var scaled := filled if season == SUMMER else (filled * 2 / 3)
	return mini(40, maxi(0, scaled))
