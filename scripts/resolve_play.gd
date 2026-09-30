class_name ResolvePlay
extends Node

signal finished

var playing := false
var steps: Array = []
var index := -1
var wait := 0.0
var portrait: PortraitBox
var hud: HarborHud
var harbor: HarborView
var sim: YearSim


func start(host_portrait: PortraitBox, host_hud: HarborHud, host_harbor: HarborView, host_sim: YearSim, before_cash: int, spend: String, politics: String) -> void:
	portrait = host_portrait
	hud = host_hud
	harbor = host_harbor
	sim = host_sim
	steps = _steps(before_cash, spend, politics)
	index = -1
	playing = true
	advance()


func advance() -> void:
	if not playing:
		return
	index += 1
	if index >= steps.size():
		playing = false
		portrait.set_die(-1)
		finished.emit()
		return
	_run(steps[index])
	wait = 1.7 if str(steps[index].get("act", "")) == "die" else 1.15


func _process(delta: float) -> void:
	if not playing:
		return
	wait -= delta
	if wait <= 0.0:
		advance()


func _run(step: Dictionary) -> void:
	portrait.show_face(str(step["face"]))
	portrait.show_line(str(step["line"]))
	var act := str(step["act"])
	if act == "die":
		_tumble(int(step["die"]))
	elif act == "cash":
		hud.animate_cash(int(step["cash"]))
		portrait.set_die(-1)
	elif act == "mood":
		harbor.apply_people(sim)
		harbor.pop_moods()
		portrait.set_die(-1)
	elif act == "boats":
		harbor.apply_world(sim)
		harbor.apply_boats(sim)
		portrait.set_die(-1)
	else:
		portrait.set_die(-1)


func _tumble(final_face: int) -> void:
	var tw := create_tween()
	for i in 8:
		tw.tween_callback(_show_die.bind((i % 6) + 1)).set_delay(0.07)
	tw.tween_callback(_show_die.bind(final_face))


func _show_die(face: int) -> void:
	if portrait:
		portrait.set_die(face)


func _steps(before_cash: int, spend: String, politics: String) -> Array:
	var cancelled := sim.note != ""
	return [
		{"act": "politics", "face": "commodore", "line": _politics_line(politics, cancelled)},
		{"act": "spend", "face": _spend_face(spend), "line": _spend_line(spend, cancelled)},
		{"act": "die", "face": "commodore", "die": sim.last_die, "line": "The die tumbles across the bar."},
		{"act": "event", "face": sim.speaker, "line": "Die %d: %s." % [sim.last_die, SimData.EVENT_TITLES[sim.last_event]]},
		{"act": "cash", "face": "bookkeeper", "cash": sim.cash, "line": "Cash moves from %s to %s." % [SimData.money(before_cash), SimData.money(sim.cash)]},
		{"act": "mood", "face": sim.speaker, "line": "Moods settle on the people who felt it."},
		{"act": "boats", "face": "dockmaster", "line": "The boats take their places for %s." % sim.season_name()},
	]


func _politics_line(id: String, cancelled: bool) -> String:
	if sim.note.find("vote failed") >= 0:
		return "The vote failed, and that choice does not happen."
	match id:
		"dues_hike":
			return "The board passed a dues hike for next year." if sim.due_hike_pending else "The dues hike did not pass."
		"hold_dues":
			return "The dues stay where they are."
		"cut_dues":
			return "Dues are cut, and the refund leaves the till."
		"recruit":
			return "The recruit vote passed." if sim.recruit_passed else "The recruit vote failed."
		"reshuffle":
			return "Helen and June trade a word about the slips."
		"commodore_back":
			return "The commodore will back the event."
		"racer_run":
			return "The racer's seat will run the event."
		"assessment":
			return "The assessment is levied." if not cancelled else "The assessment does not pass."
		"no_assessment":
			return "There will be no assessment."
	return "The board lets the moment pass."


func _spend_line(id: String, cancelled: bool) -> String:
	if cancelled:
		return "The spend is cancelled. %s" % sim.note
	match id:
		"full":
			return "Insurance and the dredge stay at the full rate."
		"high_deductible":
			return "The deductible goes up. Storms will cost more."
		"cheap_dredge":
			return "The dredge is done on the cheap."
		"spring_quiet":
			return "The yard stays quiet, and the tab is left alone."
		"overtime":
			return "The yard works overtime."
		"chase":
			return "Someone goes to talk to Dan about the tab."
		"regatta":
			return "The regatta is funded."
		"party":
			return "The party is booked."
		"bank":
			return "The cash stays in the bank."
		"patch":
			return "The docks are patched."
		"bonus":
			return "The staff bonus is paid."
		"defer":
			return "Dock work is pushed to spring."
	return "The club spends nothing extra."


func _spend_face(id: String) -> String:
	match id:
		"chase":
			return "dan"
		"party", "bonus":
			return "bar_manager"
		"overtime", "defer", "patch", "cheap_dredge":
			return "dockmaster"
		"regatta":
			return "marco"
	return "commodore"
