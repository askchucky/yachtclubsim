class_name SimData
extends RefCounted

const WINTER := 0
const SPRING := 1
const SUMMER := 2
const FALL := 3
const SEASONS := ["Winter", "Spring", "Summer", "Fall"]

const SLIP_CAP := 40
const MEMBER_CAP := 200
const RESERVE := 150000
const OPENING_CASH := 90000
const RECEIVABLES := 110000

const REG_DUES := 2375
const SOC_DUES := 1385
const CREW_DUES := 550
const FB_REG := 980
const FB_CREW := 400

const STAFF := ["dockmaster", "bar_manager", "bookkeeper", "yard_boss"]
const MEMBERS := ["helen", "marco", "june", "pete", "ruth", "chris", "dan", "sam"]
const FLAGS := ["commodore", "vice", "rear"]

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
}

const BLURB := [
	"Insurance, the dredge, and the dues.",
	"The yard, the slips, and who comes through the gate.",
	"Racing, the bar, and whatever the weather does.",
	"Close the books before the year freezes.",
]


static func choices(season: int) -> Dictionary:
	match season:
		WINTER:
			return {
				"spend": [
					["full", "Full insurance and a full dredge"],
					["high_deductible", "Raise the deductible"],
					["cheap_dredge", "Dredge on the cheap"],
				],
				"politics": [
					["dues_hike", "Propose a 10% dues hike"],
					["hold_dues", "Hold the dues"],
					["cut_dues", "Cut dues 5%"],
				],
			}
		SPRING:
			return {
				"spend": [
					["spring_quiet", "Normal yard, leave the tab"],
					["overtime", "Yard overtime"],
					["chase", "Chase Dan for the tab"],
				],
				"politics": [
					["recruit", "Push a recruit class"],
					["reshuffle", "Reshuffle the slips"],
				],
			}
		SUMMER:
			return {
				"spend": [
					["regatta", "Fund the regatta"],
					["party", "Book the party"],
					["bank", "Bank the cash"],
				],
				"politics": [
					["commodore_back", "Ask the commodore to back it"],
					["racer_run", "Let the racer run it"],
				],
			}
		_:
			return {
				"spend": [
					["patch", "Patch the docks"],
					["bonus", "Pay the staff bonus"],
					["defer", "Defer the docks"],
				],
				"politics": [
					["assessment", "Call a special assessment"],
					["no_assessment", "No assessment"],
				],
			}


static func event_for(season: int, roll: int) -> String:
	if roll <= 2:
		return "quiet"
	if roll <= 4:
		if season == SPRING:
			return "new_crew"
		if season == SUMMER:
			return "good_weekend"
		return "quiet"
	if roll == 5:
		match season:
			WINTER:
				return "audit"
			SPRING:
				return "haul_out"
			SUMMER:
				return "storm"
			_:
				return "party_demand"
	match season:
		WINTER:
			return "warm_winter"
		SPRING:
			return "quiet"
		SUMMER:
			return "bad_storm"
		_:
			return "surplus"


static func quarter_share(annual: int, season_i: int) -> int:
	return annual / 4 + (1 if season_i < annual % 4 else 0)


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


static func mood_kind(mood: int) -> String:
	if mood > 0:
		return "heart"
	if mood < 0:
		return "cloud"
	return "dot"


static func mood_text(mood: int) -> String:
	if mood > 0:
		return "+%d" % mood
	return str(mood)


static func boats_can_move(season: int, channel_open: bool) -> bool:
	return channel_open and season != WINTER


static func moving_count(filled: int, season: int, channel_open: bool) -> int:
	if not boats_can_move(season, channel_open):
		return 0
	var scaled := filled if season == SUMMER else (filled * 2 / 3)
	return mini(16, maxi(0, scaled))


static func outcome_line(code: String) -> String:
	match code:
		"insolvent":
			return "The club is insolvent, and the doors close."
		"hollow":
			return "Membership is under 140, and the club is hollow."
		"zero":
			return "The year ended on exactly $0, and the club does not open again."
		"solvent":
			return "The club is solvent, and the cash carries into next winter."
	return ""


static func map_people() -> Array:
	var rows: Array = []
	for id in STAFF:
		rows.append(id)
	for id in MEMBERS:
		rows.append(id)
	return rows
