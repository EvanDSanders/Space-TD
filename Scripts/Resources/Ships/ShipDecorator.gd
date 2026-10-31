@abstract
extends Resource
class_name ShipDecorator


var Parent : RigidBody3D
var Nav : ShipNavigator

class PropLerp:
	var targ : NodePath
	var curr : NodePath
	var rate : float
	
	static func excAll(lerpers, node):
		for l in lerpers: l.exc(node)
	
	func _init(_targ, _curr, _rate) -> void:
		targ = _targ
		curr = _curr
		rate = abs(_rate)

	func exc(this:RefCounted):
		var delta : float
		var c = this.get_indexed(curr)
		var t = this.get_indexed(targ)
		
		delta = clamp( c - t, -rate, rate )
		this.set_indexed(curr, c - delta)


@abstract func ready() -> void
@abstract func proc(choice: ShipControllerBase.AIChoice) -> void
