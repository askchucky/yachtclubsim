class_name SimPolitics
extends RefCounted

## Board seats and flag-officer advisors.

var board: Dictionary = {
	"slip_hawk": 60,
	"social": 55,
	"penny": 50,
	"racer": 50,
	"old_guard": 58,
}
var advisors: Dictionary = {
	"commodore": 60,
	"vice": 55,
	"rear": 50,
}
var warnings: Array = []


func recompute(economy: SimEconomy, demand: SimDemand, grid: HarborGrid, channel_open: bool) -> void:
	warnings.clear()
	var reserve_ok := economy.cash >= SimCatalog.RESERVE_TARGET / 3
	board["slip_hawk"] = clampf(40.0 + demand.slips * 0.5 + grid.filled_slips() * 0.4, 0, 100)
	board["social"] = clampf(35.0 + demand.bar * 0.4 + float(economy.budget["social"]) * 0.25, 0, 100)
	board["penny"] = clampf(70.0 - float(economy.loan) / 10000.0 - (10.0 if economy.last_ledger.get("net", 0) < 0 else 0.0), 0, 100)
	board["racer"] = clampf(30.0 + demand.racing * 0.5 + float(economy.budget["racing"]) * 0.2, 0, 100)
	board["old_guard"] = clampf(45.0 + (15.0 if reserve_ok else -10.0) + grid.average_dock_condition() * 0.2, 0, 100)

	advisors["commodore"] = clampf(float(board["penny"] + board["old_guard"]) / 2.0, 0, 100)
	advisors["vice"] = clampf(50.0 + grid.average_dock_condition() * 0.3 + (15.0 if channel_open else -25.0), 0, 100)
	advisors["rear"] = clampf(float(board["racer"]), 0, 100)

	if economy.cash < 30000:
		warnings.append({"who": "commodore", "text": "The reserve is thin. Watch the books."})
	if not channel_open:
		warnings.append({"who": "vice", "text": "The channel is closed. Slips earn nothing."})
	if float(economy.budget["dredging"]) < 60:
		warnings.append({"who": "vice", "text": "Underfunded dredging will silt us in."})
	if demand.racing < 35:
		warnings.append({"who": "rear", "text": "Racing is going quiet. Fund the program."})
	if int(board["penny"]) < 40 and economy.loan > SimCatalog.LOAN_STEP:
		warnings.append({"who": "commodore", "text": "The board hates this loan."})


func seats_over(threshold: int = 50) -> int:
	var n := 0
	for k in board.keys():
		if int(board[k]) > threshold:
			n += 1
	return n


func can_approve_big_move() -> bool:
	return seats_over(50) >= 3


func try_big_move(kind: String, economy: SimEconomy) -> Dictionary:
	## special_assessment, dues_hike, big_loan, sell_yard
	if not can_approve_big_move():
		return {"ok": false, "text": "The board voted it down."}
	match kind:
		"special_assessment":
			economy.cash += 40000
			board["penny"] = maxf(0, float(board["penny"]) - 15)
			board["old_guard"] = maxf(0, float(board["old_guard"]) - 8)
			return {"ok": true, "text": "Special assessment passed."}
		"dues_hike":
			economy.prices["dues_regular"] = int(economy.prices["dues_regular"] * 1.1)
			economy.prices["dues_social"] = int(economy.prices["dues_social"] * 1.1)
			board["social"] = maxf(0, float(board["social"]) - 12)
			return {"ok": true, "text": "Dues hike approved."}
		"big_loan":
			economy.borrow(2)
			board["penny"] = maxf(0, float(board["penny"]) - 20)
			return {"ok": true, "text": "Loan of $100,000 approved."}
		"sell_yard":
			return {"ok": false, "text": "Selling the yard needs a yard on the map first."}
	return {"ok": false, "text": "Unknown motion."}


func to_dict() -> Dictionary:
	return {"board": board.duplicate(), "advisors": advisors.duplicate()}


func from_dict(d: Dictionary) -> void:
	board = {
		"slip_hawk": 60, "social": 55, "penny": 50, "racer": 50, "old_guard": 58,
	}
	board.merge(d.get("board", {}), true)
	advisors = {"commodore": 60, "vice": 55, "rear": 50}
	advisors.merge(d.get("advisors", {}), true)
