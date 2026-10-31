extends TurretAmmoBase
class_name TurretAmmoContinuous

@export var amount : float

## Method will check if fuel is matched for a system.
func checkAmmo( Store: FuelStoreBase, amt: float = -1 ) -> bool:
	var useAmount : float = amount
	if amt > 0:
		useAmount = amt

	return is_equal_approx(Store.fuel, useAmount) or Store.fuel >= useAmount


## Method will atempt to consume fuel for a system.
func consumeAmmo( Store: FuelStoreBase, amt: float = -1 ) -> bool:
	if checkAmmo(Store, amt):
		var useAmount : float = amount
		if amt > 0:
			useAmount = amt
		Store.pullFuel(useAmount)
		return true

	else:
		return false
