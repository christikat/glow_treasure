# Treasure Hunting Script For QBCore

Script that allows players to use a digiscanner to locate treasure.

## Key Features
- Uses digiscanner scaleform to display information about treasure's location
- When player is facing the location of the treasure, the bars on the digiscanner will turn blue
- When player is at the treausure's location, bars turn green
- Use a shovel at the location to dig up the treasure
- Treasure location is saved on the item as metadata
- Admin command `/givescanner [id]` to give digiscanner with metadata properly set

# Installation
- Drag and drop into your resources file and ensure glow_treasure in your server.cfg
- To make the player unequip the digiscanner when the item gets removed from their inventory go to `qb-inventory/client/main.lua`, find the event `inventory:client:CheckWeapon` and add the following

```lua
    RegisterNetEvent('inventory:client:CheckWeapon', function(weaponName)
    -- Start of Added Code
    if weaponName == "digiscanner" or weaponName == "metaldetector" then
        TriggerEvent("glow_treasure_cl:scannerRemoved")
        return
    end
    -- End of Added Code
    if currentWeapon ~= weaponName:lower() then return end
    local ped = PlayerPedId()
    TriggerEvent('weapons:ResetHolster')
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    RemoveAllPedWeapons(ped, true)
    currentWeapon = nil
end)
```
- If the player uses a weapon, causing the digiscanner to unequip, an event needs to be triggered to stop the loop that maintains the scaleform.
    - Go to `qb-weapons/client/main.lua`
    - Find the event `weapons:client:SetCurrentWeapon`
    - Add `TriggerEvent("glow_treasure_cl:weaponUpdated")`

```lua
RegisterNetEvent('weapons:client:SetCurrentWeapon', function(data, bool)
    if data ~= false then
        CurrentWeaponData = data
    else
        CurrentWeaponData = {}
    end
    CanShoot = bool
    -- Added event
    TriggerEvent("glow_treasure_cl:weaponUpdated")
end)
```

- Add items to `qb-core/shared/items.lua`

```lua
	["digiscanner"] 			     = {["name"] = "digiscanner", 					["label"] = "Digiscanner", 				["weight"] = 2000, 		["type"] = "item", 		["image"] = "digiscanner.png", 			["unique"] = true, 		["useable"] = true, 	["shouldClose"] = true,    ["combinable"] = nil,   ["description"] = "Used to scan for things.."},
	["shovel"] 			     		 = {["name"] = "shovel", 						["label"] = "Shovel", 					["weight"] = 3000, 		["type"] = "item", 		["image"] = "shovel.png", 				["unique"] = false, 	["useable"] = true, 	["shouldClose"] = true,    ["combinable"] = nil,   ["description"] = "A handy shovel."},
```

- Add item images to your inventory script

- When giving players a digiscanner use the export `GenerateScannerMetadata` to set the the treasure coords

```lua
 local info = exports["glow_treasure"]:GenerateScannerMetadata()
 Player.Functions.AddItem("digiscanner", 1, nil, info)
```

- If you have a thread running on your server that disables aim assist, it may interfere with the scanner. See here on how to fix it https://github.com/christikat/glow_treasure/issues/2#issuecomment-1383010029