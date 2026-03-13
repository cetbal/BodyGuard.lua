dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

local bodyguards = {}

local MODELS = {
    { name = "s_m_m_security_01", label = "Security" },
    { name = "s_m_m_fiboffice_01", label = "FIB" },
    { name = "s_m_m_ciasec_01", label = "IAA / CIA Style" },
    { name = "s_m_y_swat_01", label = "SWAT" },
    { name = "s_m_y_blackops_01", label = "Black Ops" }
}

local WEAPONS = {
    { name = "WEAPON_PISTOL",        label = "Pistol",        ammo = 500  },
    { name = "WEAPON_COMBATPISTOL",  label = "Combat Pistol", ammo = 500  },
    { name = "WEAPON_SMG",           label = "SMG",           ammo = 800  },
    { name = "WEAPON_CARBINERIFLE",  label = "Carbine Rifle", ammo = 1200 },
    { name = "WEAPON_PUMPSHOTGUN",   label = "Pump Shotgun",  ammo = 300  }
}

local FORMATIONS = {
    { label = "Line"   },
    { label = "Circle" },
    { label = "Around" }
}

local currentModelIndex = 1
local currentWeaponIndex = 1
local currentFormationIndex = 1
local spawnAmount = 3

local BLIP_COLOR = 5
local BLIP_SPRITE = 1
local BLIP_SCALE = 0.85

local function info(text)
    Logger.Log(eLogColor.LIGHTGREEN, "Bodyguard Menu", text)
    GUI.AddToast("Bodyguard Menu", text, 3000, eToastPos.TOP_RIGHT)
end

local function warn(text)
    Logger.Log(eLogColor.LIGHTRED, "Bodyguard Menu", text)
    GUI.AddToast("Bodyguard Menu", text, 4000, eToastPos.TOP_RIGHT)
end

local function safe(fn)
    local ok, result = pcall(fn)
    if ok then
        return result
    end
    return nil
end

local function getFeature(hash)
    return FeatureMgr.GetFeature(hash)
end

local function isToggled(hash)
    local f = getFeature(hash)
    return f ~= nil and f:IsToggled()
end

local function currentModel()
    return MODELS[currentModelIndex]
end

local function currentWeapon()
    return WEAPONS[currentWeaponIndex]
end

local function currentFormation()
    return FORMATIONS[currentFormationIndex]
end

local function loadModel(modelHash)
    STREAMING.REQUEST_MODEL(modelHash)

    local i = 0
    while not STREAMING.HAS_MODEL_LOADED(modelHash) and i < 300 do
        SYSTEM.WAIT(0)
        i = i + 1
    end

    return STREAMING.HAS_MODEL_LOADED(modelHash)
end

local function hideBlip(blip)
    if blip == nil or blip == 0 then
        return
    end

    safe(function() HUD.SET_BLIP_DISPLAY(blip, 0) end)
    safe(function() HUD.SET_BLIP_ALPHA(blip, 0) end)
end

local function createBlip(ped)
    local blip = HUD.ADD_BLIP_FOR_ENTITY(ped)

    if blip ~= 0 then
        safe(function() HUD.SET_BLIP_AS_FRIENDLY(blip, true) end)
        safe(function() HUD.SET_BLIP_COLOUR(blip, BLIP_COLOR) end)
        safe(function() HUD.SET_BLIP_SPRITE(blip, BLIP_SPRITE) end)
        safe(function() HUD.SET_BLIP_SCALE(blip, BLIP_SCALE) end)
        safe(function() HUD.SET_BLIP_AS_SHORT_RANGE(blip, false) end)
        safe(function() HUD.SET_BLIP_DISPLAY(blip, 2) end)
        safe(function() HUD.SET_BLIP_HIGH_DETAIL(blip, true) end)
        safe(function() HUD.SHOW_HEADING_INDICATOR_ON_BLIP(blip, true) end)
    end

    return blip
end

local function cleanupBodyguards()
    local cleaned = {}

    for _, entry in pairs(bodyguards) do
        if entry and entry.ped and entry.ped ~= 0 then
            local exists = safe(function()
                return ENTITY.DOES_ENTITY_EXIST(entry.ped)
            end)

            if exists then
                table.insert(cleaned, entry)
            else
                if entry.blip then
                    hideBlip(entry.blip)
                end
            end
        end
    end

    bodyguards = cleaned
end

local function bodyguardCount()
    cleanupBodyguards()
    return #bodyguards
end

local function applyBlipState(entry)
    if not entry or not entry.blip or entry.blip == 0 then
        return
    end

    if isToggled(Utils.Joaat("BG_ShowBlips")) then
        safe(function() HUD.SET_BLIP_DISPLAY(entry.blip, 2) end)
        safe(function() HUD.SET_BLIP_ALPHA(entry.blip, 255) end)
    else
        safe(function() HUD.SET_BLIP_DISPLAY(entry.blip, 0) end)
        safe(function() HUD.SET_BLIP_ALPHA(entry.blip, 0) end)
    end
end

local function applyCombatMode(ped)
    if not ped or ped == 0 then
        return
    end

    if isToggled(Utils.Joaat("BG_CombatMode")) then
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, true) end)
        safe(function() PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false) end)
    else
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 0) end)
    end
end

local function equipBodyguard(ped)
    local weaponInfo = currentWeapon()
    local weaponHash = MISC.GET_HASH_KEY(weaponInfo.name)

    WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, weaponInfo.ammo, false, true)

    safe(function() PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true) end)
    safe(function() PED.SET_PED_NEVER_LEAVES_GROUP(ped, true) end)
    safe(function() PED.SET_PED_CAN_SWITCH_WEAPON(ped, true) end)
    safe(function() PED.SET_PED_ACCURACY(ped, 75) end)
    safe(function() PED.SET_PED_ARMOUR(ped, 100) end)

    if isToggled(Utils.Joaat("BG_GodMode")) then
        ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
    else
        ENTITY.SET_ENTITY_INVINCIBLE(ped, false)
    end

    applyCombatMode(ped)
end

local function formationOffset(index, total)
    local formation = currentFormation().label

    if formation == "Line" then
        return (index - 1) * 1.5, -2.5, 0.0
    elseif formation == "Circle" then
        local angle = ((index - 1) / math.max(total, 1)) * 6.28318
        return math.cos(angle) * 3.0, math.sin(angle) * 3.0, 0.0
    else
        if index % 2 == 0 then
            return 2.0 + index * 0.2, -1.5 - (index * 0.15), 0.0
        else
            return -2.0 - index * 0.2, -1.5 - (index * 0.15), 0.0
        end
    end
end

local function applyFollowOne(entry, index, total)
    if not entry or not entry.ped or entry.ped == 0 then
        return
    end

    if not isToggled(Utils.Joaat("BG_FollowPlayer")) then
        return
    end

    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed == 0 then
        return
    end

    local offX, offY, offZ = formationOffset(index, total)

    safe(function()
        TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
            entry.ped,
            playerPed,
            offX,
            offY,
            offZ,
            3.0,
            -1,
            2.0,
            true
        )
    end)
end

local function applyFollowAll()
    cleanupBodyguards()

    for i, entry in ipairs(bodyguards) do
        applyFollowOne(entry, i, #bodyguards)
    end
end

local function refreshAll()
    cleanupBodyguards()

    for i, entry in ipairs(bodyguards) do
        if entry and entry.ped and entry.ped ~= 0 then
            local exists = safe(function()
                return ENTITY.DOES_ENTITY_EXIST(entry.ped)
            end)

            if exists then
                equipBodyguard(entry.ped)
                applyBlipState(entry)
                applyFollowOne(entry, i, #bodyguards)
            end
        end
    end

    info("Refresh terminé | Actifs: " .. tostring(bodyguardCount()))
end

local function createBodyguard(offsetX, offsetY, offsetZ)
    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed == 0 then
        warn("PLAYER_PED_ID invalide")
        return 0
    end

    local coords = ENTITY.GET_ENTITY_COORDS(playerPed, true)
    local modelInfo = currentModel()
    local weaponInfo = currentWeapon()
    local modelHash = MISC.GET_HASH_KEY(modelInfo.name)

    if not STREAMING.IS_MODEL_IN_CDIMAGE(modelHash) then
        warn("Modèle absent du jeu")
        return 0
    end

    if not STREAMING.IS_MODEL_VALID(modelHash) then
        warn("Modèle invalide")
        return 0
    end

    if not STREAMING.IS_MODEL_A_PED(modelHash) then
        warn("Le modèle n'est pas un ped")
        return 0
    end

    if not loadModel(modelHash) then
        warn("Chargement du modèle échoué")
        return 0
    end

    local ped = PED.CREATE_PED(
        4,
        modelHash,
        coords.x + offsetX,
        coords.y + offsetY,
        coords.z + offsetZ,
        0.0,
        false,
        false
    )

    if ped == 0 then
        warn("CREATE_PED a échoué")
        return 0
    end

    equipBodyguard(ped)

    local entry = {
        ped = ped,
        blip = createBlip(ped)
    }

    table.insert(bodyguards, entry)
    applyBlipState(entry)

    info("Spawn: " .. modelInfo.label .. " | " .. weaponInfo.label)
    return ped
end

local function spawnAmountCustom(amount)
    local offsets = {
        {  2.0,  2.0, 1.0 },
        { -2.0,  2.0, 1.0 },
        {  2.0, -2.0, 1.0 },
        { -2.0, -2.0, 1.0 },
        {  0.0, -3.0, 1.0 },
        {  3.0,  0.0, 1.0 },
        { -3.0,  0.0, 1.0 },
        {  4.0,  2.0, 1.0 },
        { -4.0,  2.0, 1.0 },
        {  0.0,  3.0, 1.0 },
        {  5.0, -1.0, 1.0 },
        { -5.0, -1.0, 1.0 }
    }

    for i = 1, amount do
        local o = offsets[i] or { i * 1.2, 1.0, 1.0 }
        createBodyguard(o[1], o[2], o[3])
    end

    applyFollowAll()
    info(tostring(amount) .. " bodyguards spawn")
end

local function teleportAll()
    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed == 0 then
        return
    end

    local coords = ENTITY.GET_ENTITY_COORDS(playerPed, true)
    cleanupBodyguards()

    for i, entry in ipairs(bodyguards) do
        local exists = safe(function()
            return entry and entry.ped and ENTITY.DOES_ENTITY_EXIST(entry.ped)
        end)

        if exists then
            safe(function()
                ENTITY.SET_ENTITY_COORDS(
                    entry.ped,
                    coords.x + (i * 1.2),
                    coords.y + 1.5,
                    coords.z,
                    false,
                    false,
                    false,
                    false
                )
            end)
        end
    end

    applyFollowAll()
    info("Téléportation terminée")
end

local function killBodyguard(entry)
    if not entry or not entry.ped or entry.ped == 0 then
        return false
    end

    local ped = entry.ped

    local ok = safe(function()
        if ENTITY.DOES_ENTITY_EXIST(ped) then
            ENTITY.SET_ENTITY_INVINCIBLE(ped, false)
            ENTITY.SET_ENTITY_HEALTH(ped, 0, 0, 0)
        end
        return true
    end)

    if entry.blip then
        hideBlip(entry.blip)
    end

    return ok
end

local function deleteAll()
    cleanupBodyguards()

    for i = 1, #bodyguards do
        killBodyguard(bodyguards[i])
    end

    bodyguards = {}
    info("Delete All terminé | Actifs: 0")
end

local function deleteDeadOnly()
    cleanupBodyguards()

    local cleaned = {}

    for _, entry in ipairs(bodyguards) do
        local keep = true

        if entry and entry.ped and entry.ped ~= 0 then
            local health = safe(function()
                if ENTITY.DOES_ENTITY_EXIST(entry.ped) then
                    return ENTITY.GET_ENTITY_HEALTH(entry.ped)
                end
                return 0
            end)

            if health ~= nil and health <= 0 then
                killBodyguard(entry)
                keep = false
            end
        else
            keep = false
        end

        if keep then
            table.insert(cleaned, entry)
        end
    end

    bodyguards = cleaned
    info("Delete Dead Only terminé | Actifs: " .. tostring(bodyguardCount()))
end

local function nextModel()
    currentModelIndex = currentModelIndex + 1
    if currentModelIndex > #MODELS then
        currentModelIndex = 1
    end
    info("Model: " .. currentModel().label)
end

local function previousModel()
    currentModelIndex = currentModelIndex - 1
    if currentModelIndex < 1 then
        currentModelIndex = #MODELS
    end
    info("Model: " .. currentModel().label)
end

local function nextWeapon()
    currentWeaponIndex = currentWeaponIndex + 1
    if currentWeaponIndex > #WEAPONS then
        currentWeaponIndex = 1
    end
    info("Weapon: " .. currentWeapon().label)
end

local function previousWeapon()
    currentWeaponIndex = currentWeaponIndex - 1
    if currentWeaponIndex < 1 then
        currentWeaponIndex = #WEAPONS
    end
    info("Weapon: " .. currentWeapon().label)
end

local function nextFormation()
    currentFormationIndex = currentFormationIndex + 1
    if currentFormationIndex > #FORMATIONS then
        currentFormationIndex = 1
    end
    info("Formation: " .. currentFormation().label)
    applyFollowAll()
end

local function previousFormation()
    currentFormationIndex = currentFormationIndex - 1
    if currentFormationIndex < 1 then
        currentFormationIndex = #FORMATIONS
    end
    info("Formation: " .. currentFormation().label)
    applyFollowAll()
end

local function increaseAmount()
    spawnAmount = spawnAmount + 1
    if spawnAmount > 20 then
        spawnAmount = 20
    end
    info("Spawn Amount: " .. tostring(spawnAmount))
end

local function decreaseAmount()
    spawnAmount = spawnAmount - 1
    if spawnAmount < 1 then
        spawnAmount = 1
    end
    info("Spawn Amount: " .. tostring(spawnAmount))
end

FeatureMgr.AddFeature(Utils.Joaat("BG_GodMode"), "God Mode", eFeatureType.Toggle, "Invincibilité", function(f)
    refreshAll()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_ShowBlips"), "Show Blips", eFeatureType.Toggle, "Blips carte", function(f)
    refreshAll()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_FollowPlayer"), "Follow Player", eFeatureType.Toggle, "Suivre le joueur", function(f)
    applyFollowAll()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_CombatMode"), "Combat Mode", eFeatureType.Toggle, "Mode combat", function(f)
    refreshAll()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_PreviousModel"), "Previous Model", eFeatureType.Button, "", function(f)
    previousModel()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_NextModel"), "Next Model", eFeatureType.Button, "", function(f)
    nextModel()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_PreviousWeapon"), "Previous Weapon", eFeatureType.Button, "", function(f)
    previousWeapon()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_NextWeapon"), "Next Weapon", eFeatureType.Button, "", function(f)
    nextWeapon()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_PreviousFormation"), "Previous Formation", eFeatureType.Button, "", function(f)
    previousFormation()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_NextFormation"), "Next Formation", eFeatureType.Button, "", function(f)
    nextFormation()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_AmountMinus"), "Amount -", eFeatureType.Button, "", function(f)
    decreaseAmount()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_AmountPlus"), "Amount +", eFeatureType.Button, "", function(f)
    increaseAmount()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_ShowSelection"), "Show Current Selection", eFeatureType.Button, "", function(f)
    info("Model: " .. currentModel().label .. " | Weapon: " .. currentWeapon().label)
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_ShowFormation"), "Show Formation", eFeatureType.Button, "", function(f)
    info("Formation: " .. currentFormation().label)
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_ShowAmount"), "Show Spawn Amount", eFeatureType.Button, "", function(f)
    info("Spawn Amount: " .. tostring(spawnAmount))
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_SpawnSelected"), "Spawn Selected Amount", eFeatureType.Button, "", function(f)
    spawnAmountCustom(spawnAmount)
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_Spawn1"), "Spawn 1", eFeatureType.Button, "", function(f)
    local ped = createBodyguard(2.0, 2.0, 1.0)
    if ped ~= 0 then
        applyFollowAll()
    end
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_Spawn5"), "Spawn 5", eFeatureType.Button, "", function(f)
    spawnAmountCustom(5)
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_Spawn10"), "Spawn 10", eFeatureType.Button, "", function(f)
    spawnAmountCustom(10)
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_Teleport"), "Teleport To Me", eFeatureType.Button, "", function(f)
    teleportAll()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_ShowCount"), "Show Count", eFeatureType.Button, "", function(f)
    info("Bodyguards actifs: " .. tostring(bodyguardCount()))
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_RefreshAll"), "Refresh All", eFeatureType.Button, "", function(f)
    refreshAll()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_DeleteDeadOnly"), "Delete Dead Only", eFeatureType.Button, "", function(f)
    deleteDeadOnly()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_DeleteAll"), "Delete All", eFeatureType.Button, "", function(f)
    deleteAll()
end, true)

ClickGUI.AddTab("Bodyguard Menu", function()

    if ClickGUI.BeginCustomChildWindow("Command Center") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_ShowSelection"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_ShowFormation"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_ShowCount"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_RefreshAll"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Identity") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_PreviousModel"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_NextModel"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Arsenal") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_PreviousWeapon"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_NextWeapon"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Formation & AI") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_FollowPlayer"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_CombatMode"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_PreviousFormation"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_NextFormation"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("System") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_GodMode"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_ShowBlips"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Deployment") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_AmountMinus"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_AmountPlus"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_ShowAmount"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_SpawnSelected"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Quick Actions") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_Spawn1"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_Spawn5"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_Spawn10"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_Teleport"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Cleanup") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_DeleteDeadOnly"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_DeleteAll"))
        ClickGUI.EndCustomChildWindow()
    end
end)

info("Menu Bodyguard V7 chargé")
info("Model: " .. currentModel().label)
info("Weapon: " .. currentWeapon().label)
info("Formation: " .. currentFormation().label)
info("Spawn Amount: " .. tostring(spawnAmount))
