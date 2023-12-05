-- https://discord.gg/scully
local lib = exports.loaf_lib:GetLib()

if IsDuplicityVersion() then
    local function spawnPhoneObject(source, model)
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        local object = CreateObject(model, coords.x, coords.y, coords.z, true, true)
        local timeout, entityExists = 0, true

        while not DoesEntityExist(object) do
            Wait(0)
    
            timeout += 1
    
            if timeout > 2000 then entityExists = false break end
        end

        SetEntityIgnoreRequestControlFilter(object, true)
    
        return entityExists and NetworkGetNetworkIdFromEntity(object) or false
    end

    lib.RegisterCallback('lb-phone_workaround:spawnPhone', function(source, cb, model)
        cb(spawnPhoneObject(source, model))
    end)

    RegisterNetEvent('lb-phone_workaround:deleteEntity', function(netId)
        if GetInvokingResource() then return end

        local src = source
        local entity = NetworkGetEntityFromNetworkId(netId)
        local model = GetEntityModel(entity)

        if model ~= Config.PhoneModel then
            DropPlayer(src, 'Cheating. (Attempted to delete an entity using "lb-phone_workaround:deleteEntity")')

            return
        end
        
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
                if not netId then return end

                local object = NetToObj(netId)
                local timeout, entityExists = 0, true
                
                while not DoesEntityExist(object) do
                    Wait(0)
            
                    timeout += 1
            
                    if timeout > 2000 then entityExists = false break end
                end

                if not entityExists then return end

                timeout = 0

                while true do
                    Wait(0)

                    local hasControl = NetworkGetEntityOwner(object) == playerId

                    if hasControl then 
                        break
                    else
                        NetworkRequestControlOfEntity(object) 
                    end
            
                    timeout += 1
            
                    if timeout > 2000 then entityExists = false break end
                end

                if entityExists then
                    phoneId = object
                    
                    AttachEntityToEntity(phoneId, ped, GetPedBoneIndex(ped, 28422), Config.PhoneOffset.x, Config.PhoneOffset.y, Config.PhoneOffset.z, Config.PhoneRotation.x, Config.PhoneRotation.y, Config.PhoneRotation.z, 1, 1, 0, 0, 2, 1)
                end
            end, Config.PhoneModel)
        else
            if DoesEntityExist(phoneId) then
                local netId = NetworkGetNetworkIdFromEntity(phoneId)
                
                TriggerServerEvent('lb-phone_workaround:deleteEntity', netId)
            end
        end
    end)
end