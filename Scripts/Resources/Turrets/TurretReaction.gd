@abstract 
extends Resource
class_name TurretReaction


var Parent : TurretController


@abstract func ready() -> void
@abstract func procHasTarget(delta: float) -> void
@abstract func procNoTarget(delta: float) -> void
@abstract func procFire() -> void
@abstract func procIsReady() -> bool
