dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

local bodyguards = {}

local settings = {
    modelIndex = 1,
    weaponIndex = 1,
    formationIndex = 1,
    aiModeIndex = 2, -- 1 Neutral / 2 Defense / 3 Offensive
    spawnAmount = 3,
    accuracy = 75,
    armour = 100,
    followDistance = 3,
    godMode = false,
    showBlips = true,
    followPlayer = true,
    protectPlayer = true,
    autoRespawn = false
}

local MODELS = {
    { label = "Security", model = "s_m_m_security_01" },
    { label = "FIB", model = "s_m_m_fiboffice_01" },
    { label = "IAA", model = "s_m_m_ciasec_01" },
    { label = "SWAT", model = "s_m_y_swat_01" },
    { label = "Black Ops", model = "s_m_y_blackops_01" }
}

local WEAPONS = {
    { label = "Pistol", weapon = "WEAPON_PISTOL", ammo = 500 },
    { label = "Combat Pistol", weapon = "WEAPON_COMBATPISTOL", ammo = 500 },
    { label = "SMG", weapon = "WEAPON_SMG", ammo = 1000 },
    { label = "Carbine Rifle", weapon = "WEAPON_CARBINERIFLE", ammo = 1500 },
    { label = "Pump Shotgun", weapon = "WEAPON_PUMPSHOTGUN", ammo = 300 }
}

local FORMATIONS = {
    "Line",
    "Circle",
    "Around",
    "Triangle"
}

local AI_MODES = {
    "Neutral",
    "Defense",
    "Offensive"
}

local HASH_MODEL_COMBO      = Utils.Joaat("BGV2_ModelCombo")
local HASH_WEAPON_COMBO     = Utils.Joaat("BGV2_WeaponCombo")
local HASH_AI_COMBO         = Utils.Joaat("BGV2_AiCombo")
local HASH_AMOUNT_SLIDER    = Utils.Joaat("BGV2_Amount")
local HASH_ACCURACY_SLIDER  = Utils.Joaat("BGV2_Accuracy")
local HASH_ARMOUR_SLIDER    = Utils.Joaat("BGV2_Armour")
local HASH_DISTANCE_SLIDER  = Utils.Joaat("BGV2_Distance")

local HASH_GODMODE          = Utils.Joaat("BGV2_GodMode")
local HASH_SHOWBLIPS        = Utils.Joaat("BGV2_ShowBlips")
local HASH_FOLLOWPLAYER     = Utils.Joaat("BGV2_FollowPlayer")
local HASH_PROTECTPLAYER    = Utils.Joaat("BGV2_ProtectPlayer")
local HASH_AUTORESPAWN      = Utils.Joaat("BGV2_AutoRespawn")

local HASH_PREVFORMATION    = Utils.Joaat("BGV2_PrevFormation")
local HASH_NEXTFORMATION    = Utils.Joaat("BGV2_NextFormation")

local HASH_SPAWNSELECTED    = Utils.Joaat("BGV2_SpawnSelected")
local HASH_SPAWN1           = Utils.Joaat("BGV2_Spawn1")
local HASH_SPAWN5           = Utils.Joaat("BGV2_Spawn5")
local HASH_SPAWN10          = Utils.Joaat("BGV2_Spawn10")

local HASH_SPAWNVEHICLE     = Utils.Joaat("BGV2_SpawnVehicle")
local HASH_ENTERVEHICLE     = Utils.Joaat("BGV2_EnterVehicle")
local HASH_EXITVEHICLE      = Utils.Joaat("BGV2_ExitVehicle")
local HASH_TPVEHICLE        = Utils.Joaat("BGV2_TpVehicle")
local HASH_ATTACKNEARBY     = Utils.Joaat("BGV2_AttackNearby")
local HASH_REVIVEMISSING    = Utils.Joaat("BGV2_ReviveMissing")
local HASH_TPTOME          = Utils.Joaat("BGV2_TpToMe")

local HASH_SHOWCOUNT        = Utils.Joaat("BGV2_ShowCount")
local HASH_DELETEDEAD       = Utils.Joaat("BGV2_DeleteDead")
local HASH_DELETEALL        = Utils.Joaat("BGV2_DeleteAll")
local HASH_REFRESHALL       = Utils.Joaat("BGV2_Refresh")

local function info(msg)
    Logger.Log(eLogColor.LIGHTGREEN, "Bodyguard V2", msg)
    GUI.AddToast("Bodyguard V2", msg, 3000, eToastPos.TOP_RIGHT)
end

local function safe(fn)
    local ok, result = pcall(fn)
    if ok then return result end
    return nil
end

local function getModel()
    return MODELS[settings.modelIndex]
end

local function getWeapon()
    return WEAPONS[settings.weaponIndex]
end

local function getAiMode()
    return AI_MODES[settings.aiModeIndex]
end

local function getFormation()
    return FORMATIONS[settings.formationIndex]
end

local function loadModel(modelName)
    local hash = MISC.GET_HASH_KEY(modelName)
    if not STREAMING.IS_MODEL_IN_CDIMAGE(hash) or not STREAMING.IS_MODEL_VALID(hash) then
        return 0
    end

    STREAMING.REQUEST_MODEL(hash)
    local tries = 0
    while not STREAMING.HAS_MODEL_LOADED(hash) and tries < 300 do
        SYSTEM.WAIT(0)
        tries = tries + 1
    end

    if not STREAMING.HAS_MODEL_LOADED(hash) then
        return 0
    end

    return hash
end

local function cleanBodyguards()
    local newList = {}
    for _, bg in ipairs(bodyguards) do
        if bg and bg.ped and bg.ped ~= 0 and safe(function() return ENTITY.DOES_ENTITY_EXIST(bg.ped) end) then
            table.insert(newList, bg)
        else
            if bg and bg.blip and bg.blip ~= 0 then
                safe(function() HUD.SET_BLIP_DISPLAY(bg.blip, 0) end)
            end
        end
    end
    bodyguards = newList
end

local function countBodyguards()
    cleanBodyguards()
    return #bodyguards
end

local function createBlip(ped)
    local blip = HUD.ADD_BLIP_FOR_ENTITY(ped)
    if blip ~= 0 then
        safe(function() HUD.SET_BLIP_AS_FRIENDLY(blip, true) end)
        safe(function() HUD.SET_BLIP_COLOUR(blip, 5) end)
        safe(function() HUD.SET_BLIP_SPRITE(blip, 1) end)
        safe(function() HUD.SET_BLIP_SCALE(blip, 0.85) end)
        safe(function() HUD.SET_BLIP_AS_SHORT_RANGE(blip, false) end)
        if settings.showBlips then
            safe(function() HUD.SET_BLIP_DISPLAY(blip, 2) end)
        else
            safe(function() HUD.SET_BLIP_DISPLAY(blip, 0) end)
        end
    end
    return blip
end

local function applyBlip(bg)
    if not bg or not bg.blip or bg.blip == 0 then return end
    if settings.showBlips then
        safe(function() HUD.SET_BLIP_DISPLAY(bg.blip, 2) end)
        safe(function() HUD.SET_BLIP_ALPHA(bg.blip, 255) end)
    else
        safe(function() HUD.SET_BLIP_DISPLAY(bg.blip, 0) end)
        safe(function() HUD.SET_BLIP_ALPHA(bg.blip, 0) end)
    end
end

local function applyPedCombatStyle(ped)
    local mode = getAiMode()

    safe(function() PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true) end)
    safe(function() PED.SET_PED_KEEP_TASK(ped, true) end)
    safe(function() PED.SET_PED_ACCURACY(ped, settings.accuracy) end)
    safe(function() PED.SET_PED_ARMOUR(ped, settings.armour) end)
    safe(function() PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false) end)
    safe(function() PED.SET_PED_SEEING_RANGE(ped, 120.0) end)
    safe(function() PED.SET_PED_HEARING_RANGE(ped, 120.0) end)
    safe(function() PED.SET_PED_ALERTNESS(ped, 3) end)

    if settings.godMode then
        safe(function() ENTITY.SET_ENTITY_INVINCIBLE(ped, true) end)
    else
        safe(function() ENTITY.SET_ENTITY_INVINCIBLE(ped, false) end)
    end

    if mode == "Neutral" then
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 0) end)
    elseif mode == "Defense" then
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 1) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 1) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 1) end)
    else
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 2) end)
    end
end

local function setAsPlayerGroupMember(ped)
    local playerPed = PLAYER.PLAYER_PED_ID()
    local group = PED.GET_PED_GROUP_INDEX(playerPed)
    if group and group ~= 0 then
        safe(function() PED.SET_PED_AS_GROUP_MEMBER(ped, group) end)
        safe(function() PED.SET_PED_NEVER_LEAVES_GROUP(ped, true) end)
    end
end

local function equipBodyguard(ped)
    local weapon = getWeapon()
    local hash = MISC.GET_HASH_KEY(weapon.weapon)
    WEAPON.GIVE_WEAPON_TO_PED(ped, hash, weapon.ammo, false, true)
    setAsPlayerGroupMember(ped)
    applyPedCombatStyle(ped)
end

local function formationOffset(i, total)
    local formation = getFormation()

    if formation == "Line" then
        return (i - 1) * 1.5, -settings.followDistance, 0.0
    elseif formation == "Circle" then
        local angle = ((i - 1) / math.max(total, 1)) * 6.28318
        return math.cos(angle) * settings.followDistance, math.sin(angle) * settings.followDistance, 0.0
    elseif formation == "Triangle" then
        if i == 1 then
            return 0.0, -settings.followDistance, 0.0
        elseif i % 2 == 0 then
            return settings.followDistance, -(i * 0.35), 0.0
        else
            return -settings.followDistance, -(i * 0.35), 0.0
        end
    else
        if i % 2 == 0 then
            return settings.followDistance + i * 0.25, -1.5 - i * 0.15, 0.0
        else
            return -settings.followDistance - i * 0.25, -1.5 - i * 0.15, 0.0
        end
    end
end

local function followAll()
    if not settings.followPlayer then return end

    local playerPed = PLAYER.PLAYER_PED_ID()
    cleanBodyguards()

    for i, bg in ipairs(bodyguards) do
        if bg and bg.ped and ENTITY.DOES_ENTITY_EXIST(bg.ped) then
            local x, y, z = formationOffset(i, #bodyguards)
            safe(function()
                TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
                    bg.ped,
                    playerPed,
                    x, y, z,
                    3.0,
                    -1,
                    2.0,
                    true
                )
            end)
        end
    end
end

local function spawnOne(offsetX, offsetY, offsetZ)
    local playerPed = PLAYER.PLAYER_PED_ID()
    local coords = ENTITY.GET_ENTITY_COORDS(playerPed, true)

    local modelHash = loadModel(getModel().model)
    if modelHash == 0 then
        info("Impossible de charger le modèle")
        return 0
    end

    local ped = PED.CREATE_PED(
        4,
        modelHash,
        coords.x + offsetX,
        coords.y + offsetY,
        coords.z + offsetZ,
        ENTITY.GET_ENTITY_HEADING(playerPed),
        true,
        true
    )

    if ped == 0 then
        return 0
    end

    safe(function() ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ped, true, true) end)
    safe(function() PED.SET_PED_DIES_WHEN_INJURED(ped, false) end)
    safe(function() PED.SET_PED_SUFFERS_CRITICAL_HITS(ped, false) end)

    equipBodyguard(ped)

    local bg = {
        ped = ped,
        blip = createBlip(ped)
    }

    table.insert(bodyguards, bg)
    applyBlip(bg)

    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(modelHash)
    return ped
end

local function spawnMany(amount)
    local offsets = {
        { 2.0, 2.0, 1.0 },
        { -2.0, 2.0, 1.0 },
        { 0.0, 3.0, 1.0 },
        { 4.0, -1.0, 1.0 },
        { -4.0, -1.0, 1.0 }
    }

    for i = 1, amount do
        local o = offsets[i] or { i * 1.2, 1.0, 1.0 }
        spawnOne(o[1], o[2], o[3])
    end

    followAll()
    info(tostring(amount) .. " bodyguards spawn")
end

local function refreshAll()
    cleanBodyguards()
    for _, bg in ipairs(bodyguards) do
        if bg and bg.ped and ENTITY.DOES_ENTITY_EXIST(bg.ped) then
            equipBodyguard(bg.ped)
            applyBlip(bg)
        end
    end
    followAll()
end

local function teleportAllToMe()
    local playerPed = PLAYER.PLAYER_PED_ID()
    local coords = ENTITY.GET_ENTITY_COORDS(playerPed, true)

    cleanBodyguards()
    for i, bg in ipairs(bodyguards) do
        if bg and bg.ped and ENTITY.DOES_ENTITY_EXIST(bg.ped) then
            local x, y, _ = formationOffset(i, #bodyguards)
            safe(function()
                ENTITY.SET_ENTITY_COORDS(bg.ped, coords.x + x, coords.y + y, coords.z, false, false, false, false)
            end)
        end
    end

    followAll()
end

local function deleteDeadOnly()
    cleanBodyguards()
    local newList = {}

    for _, bg in ipairs(bodyguards) do
        local keep = true
        if bg and bg.ped and ENTITY.DOES_ENTITY_EXIST(bg.ped) then
            local hp = ENTITY.GET_ENTITY_HEALTH(bg.ped)
            if hp <= 0 then
                safe(function() PED.DELETE_PED(bg.ped) end)
                keep = false
            end
        else
            keep = false
        end

        if keep then
            table.insert(newList, bg)
        end
    end

    bodyguards = newList
end

local function deleteAll()
    cleanBodyguards()
    for _, bg in ipairs(bodyguards) do
        if bg and bg.ped and ENTITY.DOES_ENTITY_EXIST(bg.ped) then
            safe(function() PED.DELETE_PED(bg.ped) end)
        end
    end
    bodyguards = {}
    info("Tous les bodyguards supprimés")
end

local function reviveMissing()
    local missing = settings.spawnAmount - countBodyguards()
    if missing > 0 then
        spawnMany(missing)
    end
end

local function attackNearby()
    cleanBodyguards()
    for _, bg in ipairs(bodyguards) do
        if bg and bg.ped and ENTITY.DOES_ENTITY_EXIST(bg.ped) then
            safe(function()
                TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(bg.ped, 80.0, 0)
            end)
        end
    end
end

local function putAllInMyVehicle()
    local playerPed = PLAYER.PLAYER_PED_ID()
    if not PED.IS_PED_IN_ANY_VEHICLE(playerPed, false) then
        info("Tu n'es pas dans un véhicule")
        return
    end

    local veh = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
    local seat = 0

    cleanBodyguards()
    for _, bg in ipairs(bodyguards) do
        if bg and bg.ped and ENTITY.DOES_ENTITY_EXIST(bg.ped) then
            safe(function() PED.SET_PED_INTO_VEHICLE(bg.ped, veh, seat) end)
            seat = seat + 1
        end
    end
end

local function exitVehicleAll()
    cleanBodyguards()
    for _, bg in ipairs(bodyguards) do
        if bg and bg.ped and ENTITY.DOES_ENTITY_EXIST(bg.ped) then
            if PED.IS_PED_IN_ANY_VEHICLE(bg.ped, false) then
                safe(function()
                    TASK.TASK_LEAVE_VEHICLE(bg.ped, PED.GET_VEHICLE_PED_IS_IN(bg.ped, false), 0)
                end)
            end
        end
    end
end

local function spawnInMyVehicle()
    local playerPed = PLAYER.PLAYER_PED_ID()
    if not PED.IS_PED_IN_ANY_VEHICLE(playerPed, false) then
        info("Tu n'es pas dans un véhicule")
        return
    end

    local veh = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
    local ped = spawnOne(1.0, 1.0, 1.0)
    if ped ~= 0 then
        safe(function() PED.SET_PED_INTO_VEHICLE(ped, veh, 0) end)
    end
end

local function tpToVehicle()
    local playerPed = PLAYER.PLAYER_PED_ID()
    if not PED.IS_PED_IN_ANY_VEHICLE(playerPed, false) then
        info("Tu n'es pas dans un véhicule")
        return
    end

    local veh = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
    local coords = ENTITY.GET_ENTITY_COORDS(veh, true)

    cleanBodyguards()
    for i, bg in ipairs(bodyguards) do
        if bg and bg.ped and ENTITY.DOES_ENTITY_EXIST(bg.ped) then
            safe(function()
                ENTITY.SET_ENTITY_COORDS(bg.ped, coords.x + i, coords.y + 2.0, coords.z, false, false, false, false)
            end)
        end
    end
end

Script.RegisterLooped("BodyguardV2_AI", function()
    cleanBodyguards()

    if settings.followPlayer then
        followAll()
    end

    local playerPed = PLAYER.PLAYER_PED_ID()
    local playerInCombat = PED.IS_PED_IN_COMBAT(playerPed, 0)
    local mode = getAiMode()

    for _, bg in ipairs(bodyguards) do
        if bg and bg.ped and ENTITY.DOES_ENTITY_EXIST(bg.ped) then
            applyPedCombatStyle(bg.ped)
            applyBlip(bg)

            if settings.protectPlayer then
                if mode == "Offensive" then
                    safe(function()
                        TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(bg.ped, 120.0, 0)
                    end)
                elseif mode == "Defense" and playerInCombat then
                    safe(function()
                        TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(bg.ped, 90.0, 0)
                    end)
                end
            end
        end
    end

    if settings.autoRespawn and countBodyguards() < settings.spawnAmount then
        reviveMissing()
    end

    SYSTEM.WAIT(1000)
end)

FeatureMgr.AddFeature(HASH_MODEL_COMBO, "Agent Model", eFeatureType.Combo, "", function(f)
    settings.modelIndex = f:GetListIndex() + 1
    info("Model: " .. getModel().label)
end, true)

FeatureMgr.AddFeature(HASH_WEAPON_COMBO, "Primary Weapon", eFeatureType.Combo, "", function(f)
    settings.weaponIndex = f:GetListIndex() + 1
    refreshAll()
end, true)

FeatureMgr.AddFeature(HASH_AI_COMBO, "AI Mode", eFeatureType.Combo, "", function(f)
    settings.aiModeIndex = f:GetListIndex() + 1
    refreshAll()
    info("AI Mode: " .. getAiMode())
end, true)

FeatureMgr.AddFeature(HASH_AMOUNT_SLIDER, "Spawn Amount", eFeatureType.SliderInt, "", function(f)
    settings.spawnAmount = f:GetIntValue()
end, true)

FeatureMgr.AddFeature(HASH_ACCURACY_SLIDER, "Accuracy", eFeatureType.SliderInt, "", function(f)
    settings.accuracy = f:GetIntValue()
    refreshAll()
end, true)

FeatureMgr.AddFeature(HASH_ARMOUR_SLIDER, "Armour", eFeatureType.SliderInt, "", function(f)
    settings.armour = f:GetIntValue()
    refreshAll()
end, true)

FeatureMgr.AddFeature(HASH_DISTANCE_SLIDER, "Follow Distance", eFeatureType.SliderInt, "", function(f)
    settings.followDistance = f:GetIntValue()
    followAll()
end, true)

FeatureMgr.AddFeature(HASH_GODMODE, "God Mode", eFeatureType.Toggle, "", function(f)
    settings.godMode = f:IsToggled()
    refreshAll()
end, true)

FeatureMgr.AddFeature(HASH_SHOWBLIPS, "Show Blips", eFeatureType.Toggle, "", function(f)
    settings.showBlips = f:IsToggled()
    refreshAll()
end, true)

FeatureMgr.AddFeature(HASH_FOLLOWPLAYER, "Follow Player", eFeatureType.Toggle, "", function(f)
    settings.followPlayer = f:IsToggled()
    followAll()
end, true)

FeatureMgr.AddFeature(HASH_PROTECTPLAYER, "Protect Player", eFeatureType.Toggle, "", function(f)
    settings.protectPlayer = f:IsToggled()
end, true)

FeatureMgr.AddFeature(HASH_AUTORESPAWN, "Auto Respawn", eFeatureType.Toggle, "", function(f)
    settings.autoRespawn = f:IsToggled()
end, true)

FeatureMgr.AddFeature(HASH_PREVFORMATION, "Previous Formation", eFeatureType.Button, "", function()
    settings.formationIndex = settings.formationIndex - 1
    if settings.formationIndex < 1 then
        settings.formationIndex = #FORMATIONS
    end
    info("Formation: " .. getFormation())
    followAll()
end, true)

FeatureMgr.AddFeature(HASH_NEXTFORMATION, "Next Formation", eFeatureType.Button, "", function()
    settings.formationIndex = settings.formationIndex + 1
    if settings.formationIndex > #FORMATIONS then
        settings.formationIndex = 1
    end
    info("Formation: " .. getFormation())
    followAll()
end, true)

FeatureMgr.AddFeature(HASH_SPAWNSELECTED, "Spawn Selected Amount", eFeatureType.Button, "", function()
    spawnMany(settings.spawnAmount)
end, true)

FeatureMgr.AddFeature(HASH_SPAWN1, "Spawn 1", eFeatureType.Button, "", function()
    spawnMany(1)
end, true)

FeatureMgr.AddFeature(HASH_SPAWN5, "Spawn 5", eFeatureType.Button, "", function()
    spawnMany(5)
end, true)

FeatureMgr.AddFeature(HASH_SPAWN10, "Spawn 10", eFeatureType.Button, "", function()
    spawnMany(10)
end, true)

FeatureMgr.AddFeature(HASH_SPAWNVEHICLE, "Spawn In My Vehicle", eFeatureType.Button, "", function()
    spawnInMyVehicle()
end, true)

FeatureMgr.AddFeature(HASH_ENTERVEHICLE, "Enter My Vehicle", eFeatureType.Button, "", function()
    putAllInMyVehicle()
end, true)

FeatureMgr.AddFeature(HASH_EXITVEHICLE, "Exit Vehicle", eFeatureType.Button, "", function()
    exitVehicleAll()
end, true)

FeatureMgr.AddFeature(HASH_TPVEHICLE, "Teleport To Vehicle", eFeatureType.Button, "", function()
    tpToVehicle()
end, true)

FeatureMgr.AddFeature(HASH_ATTACKNEARBY, "Attack Nearby", eFeatureType.Button, "", function()
    attackNearby()
end, true)

FeatureMgr.AddFeature(HASH_REVIVEMISSING, "Revive Missing", eFeatureType.Button, "", function()
    reviveMissing()
end, true)

FeatureMgr.AddFeature(HASH_TPTOME, "Teleport To Me", eFeatureType.Button, "", function()
    teleportAllToMe()
end, true)

FeatureMgr.AddFeature(HASH_SHOWCOUNT, "Show Count", eFeatureType.Button, "", function()
    info("Actifs: " .. tostring(countBodyguards()))
end, true)

FeatureMgr.AddFeature(HASH_DELETEDEAD, "Delete Dead Only", eFeatureType.Button, "", function()
    deleteDeadOnly()
end, true)

FeatureMgr.AddFeature(HASH_DELETEALL, "Delete All", eFeatureType.Button, "", function()
    deleteAll()
end, true)

FeatureMgr.AddFeature(HASH_REFRESHALL, "Refresh All", eFeatureType.Button, "", function()
    refreshAll()
    info("Refresh OK")
end, true)

local modelLabels = {}
local weaponLabels = {}
local aiLabels = {}

for i, v in ipairs(MODELS) do modelLabels[i] = v.label end
for i, v in ipairs(WEAPONS) do weaponLabels[i] = v.label end
for i, v in ipairs(AI_MODES) do aiLabels[i] = v end

local f = FeatureMgr.GetFeature(HASH_MODEL_COMBO)
if f then f:SetList(modelLabels) f:SetListIndex(0) end

f = FeatureMgr.GetFeature(HASH_WEAPON_COMBO)
if f then f:SetList(weaponLabels) f:SetListIndex(0) end

f = FeatureMgr.GetFeature(HASH_AI_COMBO)
if f then f:SetList(aiLabels) f:SetListIndex(1) end

f = FeatureMgr.GetFeature(HASH_AMOUNT_SLIDER)
if f then f:SetLimitValues(1, 20) f:SetStepSize(1) f:SetIntValue(3) end

f = FeatureMgr.GetFeature(HASH_ACCURACY_SLIDER)
if f then f:SetLimitValues(1, 100) f:SetStepSize(1) f:SetIntValue(75) end

f = FeatureMgr.GetFeature(HASH_ARMOUR_SLIDER)
if f then f:SetLimitValues(0, 100) f:SetStepSize(1) f:SetIntValue(100) end

f = FeatureMgr.GetFeature(HASH_DISTANCE_SLIDER)
if f then f:SetLimitValues(1, 15) f:SetStepSize(1) f:SetIntValue(3) end

ClickGUI.AddTab("Bodyguard Menu V2", function()
    if ClickGUI.BeginCustomChildWindow("Identity") then
        ClickGUI.RenderFeature(HASH_MODEL_COMBO)
        ClickGUI.RenderFeature(HASH_WEAPON_COMBO)
        ClickGUI.RenderFeature(HASH_AI_COMBO)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Formation & Follow") then
        ClickGUI.RenderFeature(HASH_FOLLOWPLAYER)
        ClickGUI.RenderFeature(HASH_PROTECTPLAYER)
        ClickGUI.RenderFeature(HASH_PREVFORMATION)
        ClickGUI.RenderFeature(HASH_NEXTFORMATION)
        ClickGUI.RenderFeature(HASH_DISTANCE_SLIDER)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Stats") then
        ClickGUI.RenderFeature(HASH_ACCURACY_SLIDER)
        ClickGUI.RenderFeature(HASH_ARMOUR_SLIDER)
        ClickGUI.RenderFeature(HASH_GODMODE)
        ClickGUI.RenderFeature(HASH_SHOWBLIPS)
        ClickGUI.RenderFeature(HASH_AUTORESPAWN)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Spawn") then
        ClickGUI.RenderFeature(HASH_AMOUNT_SLIDER)
        ClickGUI.RenderFeature(HASH_SPAWNSELECTED)
        ClickGUI.RenderFeature(HASH_SPAWN1)
        ClickGUI.RenderFeature(HASH_SPAWN5)
        ClickGUI.RenderFeature(HASH_SPAWN10)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Vehicle") then
        ClickGUI.RenderFeature(HASH_SPAWNVEHICLE)
        ClickGUI.RenderFeature(HASH_ENTERVEHICLE)
        ClickGUI.RenderFeature(HASH_EXITVEHICLE)
        ClickGUI.RenderFeature(HASH_TPVEHICLE)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Actions") then
        ClickGUI.RenderFeature(HASH_ATTACKNEARBY)
        ClickGUI.RenderFeature(HASH_REVIVEMISSING)
        ClickGUI.RenderFeature(HASH_TPTOME)
        ClickGUI.RenderFeature(HASH_SHOWCOUNT)
        ClickGUI.RenderFeature(HASH_REFRESHALL)
        ClickGUI.RenderFeature(HASH_DELETEDEAD)
        ClickGUI.RenderFeature(HASH_DELETEALL)
        ClickGUI.EndCustomChildWindow()
    end
end)

info("Bodyguard Menu V2 chargé")
