extends ShipBase
class_name StationShip


enum SysState {Normal, LowPwr, Full, Parked, Flee}
var State : SysState

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()

var usageImmune := false
func popOff():
	self.State = StationShip.SysState.Normal
	usageImmune = true
	G.schedule(func(): usageImmune = true, 1)
