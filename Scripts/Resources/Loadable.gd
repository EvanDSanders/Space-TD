@abstract extends Resource
class_name LoadableResource


## May return an [Array] of [LoadableResource]s. [br]
## This list is used to capture all scenes that will be thread loaded.
@abstract func PreLoad() -> Array[LoadableResource]

## Returns any to-load scene paths that this resource refrences 
@abstract func Resources() -> Array[StringName]

## Returns a loaded Node* ready to be attaed to scene.
## Called in squence.
@abstract func Load() -> Binder

## Binds a loaded Node* and returns it.
## Called in squence.
@abstract func Bound(_child:Node) -> Node

## Queue item to bind an object to a scene tree object.
class Binder:
	var _parent : Node
	var _child  : Node
	var _caller : LoadableResource
	
	func _init(parent:Node, child:Node) -> void:
		self._parent = parent
		self._child  = child

	func Bind() -> Node:
		_parent.add_child(_child)
		return _child
