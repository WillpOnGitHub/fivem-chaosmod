local chaosEnabled = false

RegisterCommand("chaos_toggle", function(source)
    chaosEnabled = not chaosEnabled
    TriggerClientEvent("chaosmod:setChaosState", -1, chaosEnabled)

    print("^3[ChaosMod]^0 " .. (chaosEnabled and "^2ENABLED^0" or "^1DISABLED^0"))
end)
