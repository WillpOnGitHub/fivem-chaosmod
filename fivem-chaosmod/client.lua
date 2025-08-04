local chaosEnabled = false
local lastEffectTime = 0
local effectFeed = {}
local currentEffectIndex = nil
local usedEffectIndices = {}

local EFFECT_DURATION = 30000 -- 30 seconds

-- Helper to get player vehicle safely
local function GetPlayerVehicle()
    local ped = PlayerPedId()
    if ped then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and veh ~= 0 then
            return veh
        end
    end
    return 0
end

-- Reset all temporary chaos effects to normal
local function ResetEffects()
    local ped = PlayerPedId()
    local veh = GetPlayerVehicle()

    StopGameplayCamShaking(true)

    if veh ~= 0 then
        SetVehicleReduceGrip(veh, false)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleUndriveable(veh, false)
        SetEntityAlpha(veh, 255, false)
        local rot = GetEntityRotation(veh, 2)
        SetEntityRotation(veh, 0.0, 0.0, rot.z, 2, true)
    end

    if ped then
        SetEntityAlpha(ped, 255, false)
    end
end

function AddFeedEntry(text)
    table.insert(effectFeed, { text = text, timestamp = GetGameTimer() })
    if #effectFeed > 6 then
        table.remove(effectFeed, 1)
    end
end

-- Effects list
local chaosEffects = {
    {
        name = "Turbo Boost",
        fn = function()
            local veh = GetPlayerVehicle()
            if veh ~= 0 then
                Citizen.CreateThread(function()
                    local startTime = GetGameTimer()
                    while GetGameTimer() - startTime < EFFECT_DURATION do
                        if not DoesEntityExist(veh) then break end
                        local currentSpeed = GetEntitySpeed(veh)
                        SetVehicleForwardSpeed(veh, currentSpeed + 50.0)
                        Citizen.Wait(500)
                    end
                end)
            end
        end
    },

    {
        name = "Gravity Flip",
        fn = function()
            local veh = GetPlayerVehicle()
            if veh ~= 0 then
                Citizen.CreateThread(function()
                    local startTime = GetGameTimer()
                    local flipped = false
                    while GetGameTimer() - startTime < EFFECT_DURATION do
                        if not DoesEntityExist(veh) then break end
                        local rot = GetEntityRotation(veh, 2)
                        if not flipped then
                            SetEntityRotation(veh, 180.0, rot.y, rot.z, 2, true)
                        else
                            SetEntityRotation(veh, 0.0, rot.y, rot.z, 2, true)
                        end
                        flipped = not flipped
                        Citizen.Wait(1000)
                    end
                end)
            end
        end
    },

{
    name = "Tire Pops!",
    fn = function()
        local veh = GetPlayerVehicle()
        if veh ~= 0 then
            for i = 0, 5 do
                -- Try false on rim and smaller damage to test
                SetVehicleTyreBurst(veh, i, false, 100)
            end
            SetVehicleEngineHealth(veh, 200.0)
            print("Tire Pops applied!")
        else
            print("No vehicle found for Tire Pops!")
        end
    end
},
    {
        name = "Engine Failure",
        fn = function()
            local veh = GetPlayerVehicle()
            if veh ~= 0 then
                SetVehicleEngineHealth(veh, 0.0)
                SetVehicleUndriveable(veh, true)
                Citizen.CreateThread(function()
                    Citizen.Wait(EFFECT_DURATION)
                    if DoesEntityExist(veh) then
                        SetVehicleUndriveable(veh, false)
                        SetVehicleEngineHealth(veh, 400.0)
                    end
                end)
            end
        end
    },

   {
    name = "Black Hole",
    fn = function()
        local ped = PlayerPedId()
        local startPos = GetEntityCoords(ped) -- fixed black hole center
        local radius = 60.0

        Citizen.CreateThread(function()
            local startTime = GetGameTimer()
            while GetGameTimer() - startTime < EFFECT_DURATION do
                if not DoesEntityExist(ped) then break end

                local pedCoords = GetEntityCoords(ped)
                local dirToCenter = startPos - pedCoords
                local distToCenter = #(dirToCenter)
                if distToCenter > 0 and distToCenter < radius then
                    local norm = dirToCenter / distToCenter
                    -- Pull player ped toward center
                    ApplyForceToEntity(ped, 1, norm.x * 5.0, norm.y * 5.0, norm.z * 2.5, 0, 0, 0, 0, false, true, true, false, true)
                    -- Also pull vehicle if in one
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh ~= 0 and DoesEntityExist(veh) then
                        ApplyForceToEntity(veh, 1, norm.x * 10.0, norm.y * 10.0, norm.z * 5.0, 0, 0, 0, 0, true, true, true, false, true)
                    end
                end

                -- Pull all other vehicles toward center
                local vehicles = GetGamePool("CVehicle")
                for _, veh in ipairs(vehicles) do
                    if veh ~= 0 and DoesEntityExist(veh) then
                        if veh ~= GetVehiclePedIsIn(ped, false) then
                            local vehCoords = GetEntityCoords(veh)
                            local dir = startPos - vehCoords
                            local dist = #(dir)
                            if dist > 0 and dist < radius then
                                local norm = dir / dist
                                ApplyForceToEntity(veh, 1, norm.x * 10.0, norm.y * 10.0, norm.z * 5.0, 0, 0, 0, 0, true, true, true, false, true)
                            end
                        end
                    end
                end

                Citizen.Wait(300)
            end
        end)
    end
},

    {
        name = "Sudden Reverse",
        fn = function()
            local veh = GetPlayerVehicle()
            if veh ~= 0 then
                SetVehicleForwardSpeed(veh, -math.random(20, 60))
            end
        end
    },

    {
        name = "Skid Out",
        fn = function()
            local veh = GetPlayerVehicle()
            if veh ~= 0 then
                SetVehicleReduceGrip(veh, true)
                Citizen.CreateThread(function()
                    Citizen.Wait(EFFECT_DURATION)
                    if DoesEntityExist(veh) then
                        SetVehicleReduceGrip(veh, false)
                    end
                end)
            end
        end
    },

    {
        name = "Random Horn Blitz",
        fn = function()
            local veh = GetPlayerVehicle()
            if veh ~= 0 then
                Citizen.CreateThread(function()
                    local startTime = GetGameTimer()
                    while GetGameTimer() - startTime < EFFECT_DURATION do
                        if not DoesEntityExist(veh) then break end
                        StartVehicleHorn(veh, 150, GetHashKey("HELDDOWN"), false)
                        Citizen.Wait(200)
                    end
                end)
            end
        end
    },

    {
        name = "Beyblade Spinout",
        fn = function()
            local veh = GetPlayerVehicle()
            if veh ~= 0 then
                Citizen.CreateThread(function()
                    local startTime = GetGameTimer()
                    while GetGameTimer() - startTime < EFFECT_DURATION do
                        if not DoesEntityExist(veh) then break end
                        local rot = GetEntityRotation(veh, 2)
                        SetEntityRotation(veh, rot.x, rot.y, rot.z + 15.0, 2, true)
                        ApplyForceToEntity(veh, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 50.0, 0, true, true, true, false, true)
                        Citizen.Wait(100)
                    end
                end)
            end
        end
    },

    {
        name = "Drunk", -- This one is allowed to repeat
        fn = function()
            ShakeGameplayCam("DRUNK_SHAKE", 5.0)
            Citizen.CreateThread(function()
                Citizen.Wait(EFFECT_DURATION)
                StopGameplayCamShaking(true)
            end)
        end
    }
}

-- Utility: pick a random unused effect, allowing "Drunk" to repeat
local function getNextEffectIndex()
    local available = {}
    for i, effect in ipairs(chaosEffects) do
        if effect.name == "Drunk" or not usedEffectIndices[i] then
            table.insert(available, i)
        end
    end

    -- Reset used effects if all non-Drunk have been used
    local allUsed = true
    for i, effect in ipairs(chaosEffects) do
        if effect.name ~= "Drunk" and not usedEffectIndices[i] then
            allUsed = false
            break
        end
    end
    if allUsed then
        usedEffectIndices = {}
    end

    -- Rebuild available after reset if needed
    available = {}
    for i, effect in ipairs(chaosEffects) do
        if effect.name == "Drunk" or not usedEffectIndices[i] then
            table.insert(available, i)
        end
    end

    local index = available[math.random(#available)]
    if chaosEffects[index].name ~= "Drunk" then
        usedEffectIndices[index] = true
    end
    return index
end

-- Main chaos loop
CreateThread(function()
    while true do
        Citizen.Wait(500)
        if chaosEnabled then
            local now = GetGameTimer()
            if currentEffectIndex == nil or now - lastEffectTime >= EFFECT_DURATION then
                ResetEffects()
                lastEffectTime = now
                currentEffectIndex = getNextEffectIndex()
                chaosEffects[currentEffectIndex].fn()
                AddFeedEntry(chaosEffects[currentEffectIndex].name)
            end
        else
            if currentEffectIndex ~= nil then
                ResetEffects()
                currentEffectIndex = nil
            end
        end
    end
end)

-- HUD feed and countdown display
CreateThread(function()
    while true do
        Citizen.Wait(0)
        if chaosEnabled then
            local now = GetGameTimer()
            local effectCountdown = math.max(0, math.ceil((EFFECT_DURATION - (now - lastEffectTime)) / 1000))

            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 0, 255)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("Next Effect In: " .. effectCountdown .. "s")
            DrawText(0.79, 0.675)

            for i, entry in ipairs(effectFeed) do
                local timeDiff = now - entry.timestamp
                if timeDiff < 6000 then
                    local alpha = 255
                    if timeDiff > 5000 then
                        alpha = 255 - ((timeDiff - 5000) / 1000) * 255
                    end
                    SetTextFont(4)
                    SetTextScale(0.42, 0.42)
                    SetTextColour(255, 255, 255, alpha)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString("~c~RACEMOD ~w~▸ " .. entry.text)
                    DrawText(0.79, 0.715 + (i * 0.02))
                end
            end
        else
            Citizen.Wait(500)
        end
    end
end)

RegisterNetEvent("chaosmod:setChaosState")
AddEventHandler("chaosmod:setChaosState", function(state)
    chaosEnabled = state
    if not state then
        ResetEffects()
        effectFeed = {}
        currentEffectIndex = nil
        usedEffectIndices = {}
    end
end)
