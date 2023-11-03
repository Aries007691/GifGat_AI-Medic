local QBCore = exports['qb-core']:GetCoreObject()

local Active = false
local medics = {}

function SpawnMedic(coords)
    spam = false
	local pedModel = "s_m_m_doctor_01" -- Medic model
	RequestModel(pedModel)
	while not HasModelLoaded(pedModel) do
		Wait(1)
	end
    local heading = GetEntityHeading(PlayerPedId())
    local ped = CreatePed(26, GetHashKey(pedModel), coords.x, coords.y, coords.z, heading, true, false)
    local modelHash = GetHashKey(pedModel)
    print("Model Hash:", modelHash)
    print("uhhhh", ped)

    RequestAnimDict("mini@cpr@char_a@cpr_str")
    while not HasAnimDictLoaded("mini@cpr@char_a@cpr_str") do
        Citizen.Wait(1000)
    end
    TaskPlayAnim(ped, "mini@cpr@char_a@cpr_str", "cpr_pumpchest", 1.0, 1.0, -1, 9, 1.0, 0, 0, 0)
    Citizen.Wait(18000) -- Wait for the medic to arrive and start treating the player (increased to 18 seconds)

    TriggerEvent('hospital:client:Revive')
    Citizen.Wait(2000) -- Wait 2 seconds before deleting the ped
    DeletePed(ped)
    print("Medic deleted")

    Citizen.Wait(10000) -- Wait for the medic to finish treating the player (increased to 20 seconds)

    -- Clean up
    RemoveBlip(medicBlip)
    medicBlip = nil
    Active = false
end

RegisterCommand(Config.HelpCommand, function(source, args, raw)
    local playerName = GetPlayerName(PlayerId())
    local phoneNumber = "123-456-7890" -- Replace with actual phone number

    TriggerServerEvent('gifgat-medic:server:SendHelpCommandLog', playerName, phoneNumber)

    if (QBCore.Functions.GetPlayerData().metadata["isdead"] or QBCore.Functions.GetPlayerData().metadata["inlaststand"]) and not Active then
        QBCore.Functions.TriggerCallback('gifgat:docOnline', function(EMSOnline, hasEnoughMoney)
            if EMSOnline > Config.OnlineDoctor then
                QBCore.Functions.Notify("There are too many medics online", "error", Config.NotifyShowTime)
            else
                if EMSOnline <= Config.OnlineDoctor and hasEnoughMoney then
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    QBCore.Functions.Notify("Medic is arriving", "primary", Config.NotifyShowTime)
                    SpawnMedic(playerCoords)
                    TriggerServerEvent('gifgat:charge')
                    TriggerServerEvent('gifgat-medic:server:SendHelpCommandLog', playerName, phoneNumber)
                elseif not hasEnoughMoney then
                    QBCore.Functions.Notify("Not Enough Money", "error", Config.NotifyShowTime)
                else
                    QBCore.Functions.Notify("Wait for a medic to arrive", "primary", Config.NotifyShowTime)
                    TriggerServerEvent('gifgat-medic:server:SendHelpCommandLog', playerName, phoneNumber)
                end
            end
        end)
    else
        QBCore.Functions.Notify("This command can only be used when dead or downed", "error", Config.NotifyShowTime)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(200)
        if Active then
            local loc = GetEntityCoords(GetPlayerPed(-1))
            for _, medic in pairs(medics) do
                local medicCoords = GetEntityCoords(medic)
                local dist = Vdist(loc.x, loc.y, loc.z, medicCoords.x, medicCoords.y, medicCoords.z)
                if dist <= 10 then
                    if Active then
                        TaskGoToCoordAnyMeans(medic, loc.x, loc.y, loc.z, 1.0, 0, 0, 786603, 0xbf800000)
                    end
                    if dist <= 1 then
                        Active = false
                        ClearPedTasksImmediately(medic)
                        DoctorNPC()
                    end
                end
            end
        end
    end
end)




function Notify(msg, state)
    QBCore.Functions.Notify(msg, state)
end




RegisterNetEvent('hospital:client:UseIfaks', function()
    local ped = PlayerPedId()
    QBCore.Functions.Progressbar("use_bandage", "Using iFaks", 3000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
		disableMouse = false,
		disableCombat = true,
    }, {
		animDict = "mp_suicide",
		anim = "pill",
		flags = 49,
    }, {}, {}, function() -- Done
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        TriggerServerEvent("hospital:server:removeIfaks")
        TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["ifaks"], "remove")
        TriggerServerEvent('hud:server:RelieveStress', math.random(12, 24))
        SetEntityHealth(ped, GetEntityHealth(ped) + 10)
        if painkillerAmount < 3 then
            painkillerAmount = painkillerAmount + 1
        end
        PainKillerLoop()
        if math.random(1, 100) < 50 then
            RemoveBleed(1)
        end
    end, function() -- Cancel
        StopAnimTask(ped, "mp_suicide", "pill", 1.0)
        QBCore.Functions.Notify("Action canceled.", "error")
    end)
end)