@abstract
extends Node
class_name FuelStoreBase

var fuel
var fuelMax

@abstract func pullFuel(charge: float) -> float
@abstract func pushFuel(amt: float)
@abstract func isFull() -> bool
