-- List of whitelisted vehicle models
local whitelistedModels = {
    [""] = true,
    -- Add other vehicle model names here, lowercase
}

-- Radar configuration
local radarConeAngle = 45
local radarDistance = 80.0
local frontRadarLocked = false
local rearRadarLocked = false
local frontLockedVehicle = nil
local rearLockedVehicle = nil
local lastFrontVehicleName = nil
local lastRearVehicleName = nil

-- Function to get the display name of the vehicle
function getVehicleName(vehicle)
    return GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
end

-- Function to check if the player's vehicle model is whitelisted
function isPlayerInWhitelistedModel()
    local playerVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if playerVehicle ~= 0 then
        local model = GetEntityModel(playerVehicle)
        return whitelistedModels[GetDisplayNameFromVehicleModel(model):lower()] or false
    end
    return false
end

-- Draw Radar UI Function
function drawRadarTextWithBackground(frontText, rearText, x, y, textColor, bgColor, labelScale, nameScale, frontLocked, rearLocked)
    local boxWidth = 0.15
    local boxHeight = 0.15
    local lineSpacing = 0.025

    DrawRect(x, y + 0.015, boxWidth, boxHeight, bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    local function drawText(text, posX, posY, color, scale)
        SetTextFont(0)
        SetTextProportional(0)
        SetTextScale(scale, scale)
        SetTextColour(color[1], color[2], color[3], color[4])
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString(text or "")
        DrawText(posX, posY)
    end

    local frontLabel = frontLocked and "Front Radar - Locked" or "Front Radar"
    local rearLabel = rearLocked and "Rear Radar - Locked" or "Rear Radar"
    local labelColor = {255, 255, 0, 255}

    drawText(frontLabel, x, y - lineSpacing, labelColor, labelScale)
    drawText(frontText, x, y, textColor, nameScale)
    drawText(rearLabel, x, y + lineSpacing, labelColor, labelScale)
    drawText(rearText, x, y + (2 * lineSpacing), textColor, nameScale)
end

-- Main Radar Display (Non-flashing)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isPlayerInWhitelistedModel() then
            local baseX = 0.5
            local baseY = 0.87
            drawRadarTextWithBackground(
                lastFrontVehicleName, lastRearVehicleName,
                baseX, baseY,
                {255, 255, 255, 255},
                {0, 0, 0, 150},
                0.3,
                0.25,
                frontRadarLocked,
                rearRadarLocked
            )
        end
    end
end)

-- Update Radar Every 200ms
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300)
        if isPlayerInWhitelistedModel() then
            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)

            if frontRadarLocked and frontLockedVehicle then
                lastFrontVehicleName = getVehicleName(frontLockedVehicle)
            else
                local frontPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, radarDistance, 0.0)
                local frontRayHandle = StartShapeTestCapsule(playerPos.x, playerPos.y, playerPos.z, frontPos.x, frontPos.y, frontPos.z, 5.0, 10, playerPed, 7)
                local _, frontHit, _, _, frontEntity = GetShapeTestResult(frontRayHandle)
                if frontHit == 1 and IsEntityAVehicle(frontEntity) then
                    lastFrontVehicleName = getVehicleName(frontEntity)
                end
            end

            if rearRadarLocked and rearLockedVehicle then
                lastRearVehicleName = getVehicleName(rearLockedVehicle)
            else
                local rearPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -radarDistance, 0.0)
                local rearRayHandle = StartShapeTestCapsule(playerPos.x, playerPos.y, playerPos.z, rearPos.x, rearPos.y, rearPos.z, 5.0, 10, playerPed, 7)
                local _, rearHit, _, _, rearEntity = GetShapeTestResult(rearRayHandle)
                if rearHit == 1 and IsEntityAVehicle(rearEntity) then
                    lastRearVehicleName = getVehicleName(rearEntity)
                end
            end
        end
    end
end)

-- Front Radar Lock Command
RegisterCommand("lockFrontRadar", function()
    frontRadarLocked = not frontRadarLocked
    if frontRadarLocked then
        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)
        local frontPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, radarDistance, 0.0)
        local frontRayHandle = StartShapeTestCapsule(playerPos.x, playerPos.y, playerPos.z, frontPos.x, frontPos.y, frontPos.z, 5.0, 10, playerPed, 7)
        local _, frontHit, _, _, frontEntity = GetShapeTestResult(frontRayHandle)
        if frontHit == 1 and IsEntityAVehicle(frontEntity) then
            frontLockedVehicle = frontEntity
            lastFrontVehicleName = getVehicleName(frontEntity)
        else
            frontRadarLocked = false
        end
    else
        frontLockedVehicle = nil
    end
end, false)

-- Rear Radar Lock Command
RegisterCommand("lockRearRadar", function()
    rearRadarLocked = not rearRadarLocked
    if rearRadarLocked then
        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)
        local rearPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -radarDistance, 0.0)
        local rearRayHandle = StartShapeTestCapsule(playerPos.x, playerPos.y, playerPos.z, rearPos.x, rearPos.y, rearPos.z, 5.0, 10, playerPed, 7)
        local _, rearHit, _, _, rearEntity = GetShapeTestResult(rearRayHandle)
        if rearHit == 1 and IsEntityAVehicle(rearEntity) then
            rearLockedVehicle = rearEntity
            lastRearVehicleName = getVehicleName(rearEntity)
        else
            rearRadarLocked = false
        end
    else
        rearLockedVehicle = nil
    end
end, false)

-- Bind `6` and `7` to commands
RegisterKeyMapping("lockFrontRadar", "Toggle Front Radar Lock", "keyboard", "6")
RegisterKeyMapping("lockRearRadar", "Toggle Rear Radar Lock", "keyboard", "7")
