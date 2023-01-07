local QBCore = exports["qb-core"]:GetCoreObject()
local scannerScaleform = nil
local isDigging = false
local usingScanner = false
local beepWait = 8000
local scaleformColours = {
    red = {r = 255, g = 10, b = 10},
    yellow = {r = 255, g = 209, b = 67},
    lightblue = {r = 67, g = 200, b = 255},
    green = {r = 0, g = 255, b = 80}
}

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Wait(10)
	end
end

local function loadModel(model)
    if HasModelLoaded(model) then return end
	RequestModel(model)
	while not HasModelLoaded(model) do
		Wait(10)
	end
end

local function setScannerColour(bar, dot)
    if not scannerScaleform then return end
    BeginScaleformMovieMethod(scannerScaleform, "SET_COLOUR")
    -- Bars rgb
    PushScaleformMovieMethodParameterInt(bar.r)
    PushScaleformMovieMethodParameterInt(bar.g)
    PushScaleformMovieMethodParameterInt(bar.b)
    -- Dots rgb
    PushScaleformMovieMethodParameterInt(dot.r)
    PushScaleformMovieMethodParameterInt(dot.g) 
    PushScaleformMovieMethodParameterInt(dot.b)
    EndScaleformMovieMethod()
end

local function updateScaleformBars(dist)
    if not scannerScaleform then return end
    local scaleformDist = nil
    
    if dist > 1000 then
        scaleformDist = 30.0 -- no bars
        beepWait = 8000
    elseif dist > 500 then
        scaleformDist = 40.0 --  1 bar
        beepWait = 5000
    elseif dist > 300 then
        scaleformDist = 50.0 --  2 bars
        beepWait = 4000
    elseif dist > 150 then
        scaleformDist = 60.0 --  3 bars
        beepWait = 3000
    elseif dist > 80 then
        scaleformDist = 70.0 --  4 bars
        beepWait = 2000
    elseif dist > 40 then
        scaleformDist = 80.0 --  5 bars
        beepWait = 1500
    elseif dist > 10 then
        scaleformDist = 90.0 --  6 bars
        beepWait = 1000
    else
        scaleformDist = 100.0 --  7 bars (full)
        beepWait = 500
    end
    
    BeginScaleformMovieMethod(scannerScaleform, "SET_DISTANCE")
    PushScaleformMovieMethodParameterFloat(scaleformDist)
    EndScaleformMovieMethod()
    
    if dist < 2.0 then
        beepWait = 250
        setScannerColour(scaleformColours.green, scaleformColours.green)
    end
end

local function isPedFacingCoords(playerCoords, playerHeading, targetCoords)
    local x = targetCoords.x - playerCoords.x
    local y = targetCoords.y - playerCoords.y

    local targetHeading = GetHeadingFromVector_2d(x, y)
    return math.abs(playerHeading - targetHeading) < 20
end

local function unequipScanner()
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)
    usingScanner = false
end

RegisterNetEvent("glow_treasure_cl:toggleScanner", function(targetCoords)
    local ped = PlayerPedId()
    local _, pedWeapon = GetCurrentPedWeapon(ped)

    if pedWeapon == joaat("weapon_digiscanner") then
        unequipScanner()
        return
    end

    GiveWeaponToPed(ped, joaat("weapon_digiscanner"), 0, true, true)
    usingScanner = true
        
    scannerScaleform = RequestScaleformMovie("digiscanner")

    CreateThread(function()
        while not HasScaleformMovieLoaded(scannerScaleform) do
            Wait(0)
        end

        if not IsNamedRendertargetRegistered("digiscanner") then
            RegisterNamedRendertarget("digiscanner", 0)
        end
       
        LinkNamedRendertarget(GetWeapontypeModel(joaat("weapon_digiscanner")))
       
        local id = 0
       
        if IsNamedRendertargetRegistered("digiscanner") then
            id = GetNamedRendertargetRenderId("digiscanner")
        end

        local playerCoords = GetEntityCoords(ped)
        local playerHeading = GetEntityHeading(ped)
        local dist = #(playerCoords - vec3(targetCoords.x, targetCoords.y, targetCoords.z))

        if isPedFacingCoords(playerCoords, playerHeading, targetCoords) then
            setScannerColour(scaleformColours.lightblue, scaleformColours.yellow)
        else
            setScannerColour(scaleformColours.red, scaleformColours.red)
        end
        
        updateScaleformBars(dist)

        local timer = GetGameTimer()

        while usingScanner do
            SetTextRenderId(id)
            DrawScaleformMovie(scannerScaleform, 0.1, 0.24, 0.21, 0.51, 100, 100, 100, 255, 0)
            SetTextRenderId(1)

            if GetGameTimer() - timer > 250 then
                ped = PlayerPedId()
                
                if IsPedInAnyVehicle(ped) then
                    usingScanner = false
                    return
                end
                
                if IsPlayerFreeAiming(PlayerId()) then
                    playerCoords = GetEntityCoords(ped)
                    playerHeading = GetEntityHeading(ped)
                    
                    if isPedFacingCoords(playerCoords, playerHeading, targetCoords) then
                        setScannerColour(scaleformColours.lightblue, scaleformColours.yellow)
                    else
                        setScannerColour(scaleformColours.red, scaleformColours.red)
                    end

                    dist = #(playerCoords - vec3(targetCoords.x, targetCoords.y, targetCoords.z))

                    updateScaleformBars(dist)
                end
    
                timer = GetGameTimer()
            end
            
            Wait(0)
        end
    end)
end)

RegisterNetEvent("glow_treasure_cl:digAnim", function()
    local ped = PlayerPedId()
    
    if IsPedInAnyVehicle(ped) then return end
    if isDigging then return end


    local shovelHash = joaat("prop_tool_shovel")
    local coords = GetEntityCoords(ped)
    
    ClearPedTasksImmediately(ped)

    loadAnimDict("random@burial")
    loadModel(shovelHash)
    
    if usingScanner then
        unequipScanner()
        TriggerEvent('weapons:ResetHolster')
    end
    
    if IsPedArmed(PlayerPedId(), 7) then
        local weapon = GetSelectedPedWeapon(ped)
        TriggerEvent('inventory:client:CheckWeapon', QBCore.Shared.Weapons[weapon]["name"])
    end

    local shovelProp = CreateObject(shovelHash, coords.x, coords.y, coords.z + 0.2, true, false, false)
    AttachEntityToEntity(shovelProp, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.24, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    TaskPlayAnim(ped, "random@burial", "a_burial", 1.0, 1.0, -1, 1, 0.0, false, false, true)
    isDigging = true
    QBCore.Functions.Progressbar("digging_treasure", "Digging something up..", 8000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        StopAnimTask(ped, "random@burial", "a_burial", 1.0)
        DetachEntity(shovelProp, true, true)
        DeleteObject(shovelProp)
        isDigging = false

        TriggerServerEvent("glow_treasure_sv:completeDig")
    end, function() -- Cancel
        StopAnimTask(ped, "random@burial", "a_burial", 1.0)
        DetachEntity(shovelProp, true, true)
        DeleteObject(shovelProp)
        isDigging = false
        QBCore.Functions.Notify("Cancelled", "error")
    end)

    CreateThread(function()
        Wait(1500)
        if isDigging then
            PlaySoundFrontend(-1, "Collect_Pickup", "DLC_IE_PL_Player_Sounds", 1)
        end
        Wait(3000)
        if isDigging then
            PlaySoundFrontend(-1, "Collect_Pickup", "DLC_IE_PL_Player_Sounds", 1)
        end
        Wait(3500)
        if isDigging then
            PlaySoundFrontend(-1, "Collect_Pickup", "DLC_IE_PL_Player_Sounds", 1)
        end
    end)

    RemoveAnimDict("random@burial")
end)


RegisterNetEvent("glow_treasure_cl:treasureAnim", function()
    local ped = PlayerPedId()
    local chestHash = joaat("xm_prop_x17_chest_closed")
    loadAnimDict("anim@treasurehunt@hatchet@action")
    loadModel(chestHash)

    local x, y, z = table.unpack(GetEntityCoords(ped) + GetEntityForwardVector(ped) * 0.75)
    local chestProp = CreateObject("xm_prop_x17_chest_closed", x, y, z, true, false, false)
    PlaceObjectOnGroundProperly(chestProp)
    SetEntityRotation(chestProp, 0.0, 0.0, GetEntityHeading(ped) + 10.0)
    
    Wait(500)
    
    TaskPlayAnim(ped, "anim@treasurehunt@hatchet@action", "hatchet_pickup", 8.0, -8.0, -1, 1, 31, true, true, true)
    PlayEntityAnim(chestProp, "hatchet_pickup_chest", "anim@treasurehunt@hatchet@action", 1000.0, false, true, 0, 0.0, 0)
    Citizen.Wait(5000)
    StopAnimTask(ped, "anim@treasurehunt@hatchet@action", "hatchet_pickup", 1.0)

    RemoveAnimDict("anim@treasurehunt@hatchet@action")
    DeleteEntity(chestProp)
end)

RegisterNetEvent("glow_treasure_cl:weaponUpdated", function()
    if usingScanner then
        usingScanner = false
    end
end)

RegisterNetEvent("glow_treasure_cl:scannerRemoved", function()
    if usingScanner then
        unequipScanner()
        TriggerEvent('weapons:ResetHolster')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if usingScanner then
        usingScanner = false
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    local ped = PlayerPedId()
    local _, pedWeapon = GetCurrentPedWeapon(ped)

    if usingScanner and pedWeapon == joaat("weapon_digiscanner") then
        unequipScanner()
        return
    end
end)

CreateThread(function()
    local sleep = 5000
    while true do
        if usingScanner then            
            if IsPlayerFreeAiming(PlayerId()) then
                PlaySoundFrontend(-1, "IDLE_BEEP", "epsilonism_04_soundset", 1)
            end
            Wait(beepWait)
            sleep = 0
        else
            sleep = 5000
        end
        
        Wait(sleep)
    end
end)