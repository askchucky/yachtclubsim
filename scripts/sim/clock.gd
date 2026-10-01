class_name MonthClock
extends RefCounted

signal month_tick
signal season_changed(season: int)
signal year_changed(year: int)

var year: int = 1
var month: int = 0 ## 0=Jan .. 11=Dec
var speed: int = 0 ## 0=pause, 1,2,3
var accum: float = 0.0
const SECONDS_PER_MONTH := 4.0


func season() -> int:
	return SimCatalog.season_of_month(month)


func month_name() -> String:
	return SimCatalog.MONTHS[month]


func season_name() -> String:
	return SimCatalog.SEASONS[season()]


func set_speed(s: int) -> void:
	speed = clampi(s, 0, 3)


func process(delta: float) -> void:
	if speed <= 0:
		return
	accum += delta * float(speed)
	while accum >= SECONDS_PER_MONTH:
		accum -= SECONDS_PER_MONTH
		advance()


func advance() -> void:
	var prev_season := season()
	month += 1
	if month >= 12:
		month = 0
		year += 1
		year_changed.emit(year)
	if season() != prev_season:
		season_changed.emit(season())
	month_tick.emit()


func to_dict() -> Dictionary:
	return {"year": year, "month": month, "speed": speed}


func from_dict(d: Dictionary) -> void:
	year = int(d.get("year", 1))
	month = int(d.get("month", 0))
	speed = int(d.get("speed", 0))
	accum = 0.0
