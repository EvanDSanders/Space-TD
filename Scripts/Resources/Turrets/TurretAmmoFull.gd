extends TurretAmmoBase
class_name TurretAmmoFull



## Method will atempt to consume fuel for a system.
func checkAmmo( Store: FuelStoreBase, amt: float = -1 ) -> bool:
	return is_equal_approx(Store.fuel, Store.fuelMax) or Store.fuel >= Store.fuelMax


func consumeAmmo( Store: FuelStoreBase, amt: float = -1 ) -> bool:
	if checkAmmo(Store, amt):
		Store.pullFuel(Store.fuelMax)
		return true

	else:
		return false
