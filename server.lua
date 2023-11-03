local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('gifgat:docOnline', function(source, cb)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local xPlayers = QBCore.Functions.GetPlayers()
    local doctor = Config.OnlineDoctor
    local canpay = false

    if Ply.PlayerData.money["cash"] >= Config.Price then
        canpay = true
    else
        if Ply.PlayerData.money["bank"] >= Config.Price then
            canpay = true
        end
    end

    for i = 1, #xPlayers, 1 do
        local xPlayer = QBCore.Functions.GetPlayer(xPlayers[i])
        if xPlayer.PlayerData.job.name == 'ambulance' then
            doctor = doctor + 1
        end
    end

    if doctor > Config.OnlineDoctor then
        cb(doctor, false) -- Send the callback with false for canpay
    else
        cb(doctor, canpay) -- Send the callback with the actual canpay value

        -- Deduct money and notify the player if canpay is true
        if canpay then
            if Ply.PlayerData.money["cash"] >= Config.Price then
                Ply.Functions.RemoveMoney("cash", Config.Price, "revived-player")
            else
                Ply.Functions.RemoveMoney("bank", Config.Price)
            end
            TriggerEvent("qb-bossmenu:server:addAccountMoney", 'ambulance', Config.Price)
            TriggerClientEvent('QBCore:Notify', src, 'You are being helped', "success")
        end
    end
end)



RegisterNetEvent('gifgat-medic:server:SendHelpCommandLog')
AddEventHandler('gifgat-medic:server:SendHelpCommandLog', function(playerName, phoneNumber)
    local webhookUrl = 'https://discord.com/api/webhooks/1117568998305956064/0P-yJHvSQcPavhN9LoJAcZLCFJuA4oMRFAIR5eTi5ukjRNw3kYS1X1JPv9nKUYv8_c-O' -- Replace with your actual webhook URL
    local Player = QBCore.Functions.GetPlayer(source)
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local phoneNumber = Player.PlayerData.charinfo.phone
    local roleMention = "<@&988085877861388328>" -- Replace YOUR_ROLE_ID with the actual ID of the role you want to mention
    local headers = { ['Content-Type'] = 'application/json' }
    local data = {
        ['content'] = roleMention, -- Mention the role
        ['embeds'] = {
            {
                ['title'] = 'Help Command Used',
                ['description'] = 'Someone has used the help command!',
                ['color'] = 65280, -- Green color code
                ['fields'] = {
                    {
                        ['name'] = 'Requested by',
                        ['value'] = playerName,
                        ['inline'] = true
                    },
                    {
                        ['name'] = 'Phone Number',
                        ['value'] = phoneNumber,
                        ['inline'] = true
                    }
                }
            }
        }
    }

    PerformHttpRequest(webhookUrl, function(statusCode, response, headers)
        -- Handle the response if needed
    end, 'POST', json.encode(data), headers)
end)

