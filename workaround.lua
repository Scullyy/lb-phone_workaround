-- https://discord.gg/scully
local lib = exports.loaf_lib:GetLib()

if IsDuplicityVersion() then
    local function spawnPhoneObject(source, model)
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        local object = CreateObject(model, coords.x, coords.y, coords.z, true, true)
    
        while not DoesEntityExist(object) do Wait(50) end
    
        return NetworkGetNetworkIdFromEntity(object)
    end

    lib.RegisterCallback('lb-phone_workaround:spawnPhone', function(source, cb, model)
        cb(spawnPhoneObject(source, model))
    end)

    RegisterNetEvent('lb-phone_workaround:deleteEntity', function(netId)
        local entity = NetworkGetEntityFromNetworkId(netId)
        
        DeleteEntity(entity)
    end)
else
    local phoneId = nil
    local playerId = PlayerId()
    local serverId = GetPlayerServerId(playerId)

    AddStateBagChangeHandler('phoneOpen', ('player:%s'):format(serverId), function(bagName, key, value, _unused, replicated)
        if value then
            if DoesEntityExist(phoneId) then return end
    
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            lib.TriggerCallback('lb-phone_workaround:spawnPhone', function(netId)
                local timeout = 0
                
                while not NetworkDoesEntityExistWithNetworkId(netId) do
                    Wait(0)
            
                    timeout += 1
            
                    if timeout > 2000 then break end
                end

                phoneId = NetToObj(netId)

                AttachEntityToEntity(phoneId, ped, GetPedBoneIndex(ped, 28422), Config.PhoneOffset.x, Config.PhoneOffset.y, Config.PhoneOffset.z, Config.PhoneRotation.x, Config.PhoneRotation.y, Config.PhoneRotation.z, 1, 1, 0, 0, 2, 1)
            end, Config.PhoneModel)
        else
            if DoesEntityExist(phoneId) then
                local netId = NetworkGetNetworkIdFromEntity(phoneId)
                
                TriggerServerEvent('lb-phone_workaround:deleteEntity', netId)
            end
        end
    end)
end