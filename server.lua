local QBCore = exports['qb-core']:GetCoreObject()

local function GenerateScannerMetadata()
    local info = {
        location = Config.locations[math.random(#Config.locations)]
    }
    return info    
end

QBCore.Commands.Add("givescanner", "Give Player Treasure Scanner (Admin Only)", {{name = "id", help = "Player ID"}}, false, function(source, args)
    local playerId = args[1] ~= '' and tonumber(args[1]) or source
    local Player = QBCore.Functions.GetPlayer(playerId)

    if Player then
        local info = GenerateScannerMetadata()
        if Player.Functions.AddItem("digiscanner", 1, nil, info) then
            QBCore.Functions.Notify(source, "Succuessfully given scanner to ".. GetPlayerName(playerId), "success")
        else
            QBCore.Functions.Notify(source, "Player Inventory Full", "error")
        end
    else
        QBCore.Functions.Notify(source, "No Player Found", "error")
    end

end, "admin")

RegisterNetEvent("glow_treasure_sv:buyScanner", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local PlyPos = GetEntityCoords(GetPlayerPed(src))
    local bankBalance = Player.PlayerData.money.bank
    if #(PlyPos - Config.PedSpawn.xyz) > 5.0 then return end
    if not Player then return end
    if Config.ScannerFee then
        if bankBalance >= Config.ScannerPrice then
            local info = GenerateScannerMetadata()
            Player.Functions.AddItem("digiscanner", 1, nil, info)
            QBCore.Functions.Notify(src, "You purchased a scanner for $"..Config.ScannerPrice, "success")
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["digiscanner"], "add")
        else
            QBCore.Functions.Notify(src, "You need $"..Config.ScannerPrice.." to purchase this.", "error")
        end
    else
        local info = GenerateScannerMetadata()
        Player.Functions.AddItem("digiscanner", 1, nil, info)
        QBCore.Functions.Notify(src, "You received a scanner.", "success")
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["digiscanner"], "add")
    end
end)

QBCore.Functions.CreateUseableItem("digiscanner", function(source, item)
    if item.info == nil or item.info.location == nil then 
        QBCore.Functions.Notify(source, "Item metadata error", "error")
        return
    end
    TriggerClientEvent("glow_treasure_cl:toggleScanner", source, item.info.location)
end)

QBCore.Functions.CreateUseableItem("shovel", function(source, item)
    TriggerClientEvent("glow_treasure_cl:digAnim", source)
end)

RegisterNetEvent("glow_treasure_sv:completeDig", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local playerCoords = GetEntityCoords(GetPlayerPed(src))

    local scanners = Player.Functions.GetItemsByName("digiscanner")
    if #scanners == 0 then return end

    for i=1, #scanners do
        if scanners[i].info and scanners[i].info.location then
            local targetCoords = scanners[i].info.location
            if #(playerCoords - vec3(targetCoords.x, targetCoords.y, targetCoords.z)) < 2.5 then
                if Player.Functions.RemoveItem("digiscanner", 1, scanners[i].slot) then
                    TriggerClientEvent("glow_treasure_cl:treasureAnim", src)
                    
                    SetTimeout(6000, function()                        
                        local rolls = math.random(Config.minRolls, Config.maxRolls)
                        for i=1, rolls do
                            local loot = Config.loot[math.random(#Config.loot)]
                            local lootAmt = math.random(loot.min, loot.max)
                            
                            Player.Functions.AddItem(loot.item, lootAmt)
                            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[loot.item], "add")
                        end
                        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["digiscanner"], "remove")
                    end)

                end
                break
            end
        end
    end
end)

exports("GenerateScannerMetadata", GenerateScannerMetadata)
