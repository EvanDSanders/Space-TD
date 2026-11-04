extends Node
class_name StarShipBuilder

var ship: TheStarShip

var _proxiesCreated := false


func setup(p_ship: TheStarShip) -> void:
	ship = p_ship
	set_physics_process(false)


func activate() -> void:
	ship.linear_velocity = Vector3.ZERO
	ship.angular_velocity = Vector3.ZERO
	ship.SpeedForward = 0.
	ship.SpeedStrafe = 0.
	ship.SpeedYaw = 0.
	ship.SpeedVert = 0.
	ship.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	ship.freeze = true
	_createProxies()


func deactivate() -> void:
	ship.freeze = false


func _createProxies() -> void:
	if _proxiesCreated: return
	_proxiesCreated = true
	for prox in ship.proxies.get_children():
		var proxy := ManaProxy.new()
		proxy.manaStore = ship.mana
		proxy.MaxLinks = 4
		prox.add_child(proxy)
		Linker.ConnectDirect(proxy, ship.mana, false)
