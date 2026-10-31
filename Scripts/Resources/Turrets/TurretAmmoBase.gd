@abstract
extends Resource
class_name TurretAmmoBase

## Method will atempt to consume fuel for a system.
@abstract func consumeAmmo( Store: FuelStoreBase, amt: float = -1 ) -> bool
@abstract func checkAmmo( Store: FuelStoreBase, amt: float = -1 ) -> bool
