dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

local bodyguards = {}

local MODEL_OPTIONS = {
    { label = "Security",        model = "s_m_m_security_01"  },
    { label = "FIB",             model = "s_m_m_fiboffice_01" },
    { label = "IAA / CIA Style", model = "s_m_m_ciasec_01"    },
    { label = "SWAT",            model = "s_m_y_swat_01"      },
    { label = "Black Ops",       model = "s_m_y_blackops_01"  }
}

local WEAPON_OPTIONS = {
    { label = "Pistol",        weapon = "WEAPON_PISTOL",       ammo = 500  },
    { label = "Combat Pistol", weapon = "WEAPON_COMBATPISTOL", ammo = 500  },
    { label = "SMG",           weapon = "WEAPON_SMG",          ammo = 800  },
    { label = "Carbine Rifle", weapon = "WEAPON_CARBINERIFLE", ammo = 1200 },
    { label = "Pump Shotgun",  weapon = "WEAPON_PUMPSHOTGUN",  ammo = 300  }
}

local FORMATIONS = {
    { label = "Line"     },
    { label = "Circle"   },
    { label = "Around"   },
    { label = "Triangle" }
}

local BEHAVIOUR_OPTIONS = {
    { label = "Passive"    },
    { label = "Offensive"  },
    { label = "Aggressive" }
}

local MODEL_LABELS = {}
local WEAPON_LABELS = {}
local BEHAVIOUR_LABELS = {}

for i, v in ipairs(MODEL_OPTIONS) do MODEL_LABELS[i] = v.label end
for i, v in ipairs(WEAPON_OPTIONS) do WEAPON_LABELS[i] = v.label end
for i, v in ipairs(BEHAVIOUR_OPTIONS) do BEHAVIOUR_LABELS[i] = v.label end

local currentModelIndex = 1
local currentWeaponIndex = 1
local currentFormationIndex = 1
local currentBehaviourIndex = 2
local spawnAmount = 3

local accuracy = 75
local armour = 100
local followDistance = 3
local autoRespawn = false

local BLIP_COLOR = 5
local BLIP_SPRITE = 1
local BLIP_SCALE = 0.85

local HASH_BG_MODEL_COMBO      = Utils.Joaat("BGV164_ModelCombo")
local HASH_BG_WEAPON_COMBO     = Utils.Joaat("BGV164_WeaponCombo")
local HASH_BG_BEHAVIOUR_COMBO  = Utils.Joaat("BGV164_BehaviourCombo")
local HASH_BG_AMOUNT_SLIDER    = Utils.Joaat("BGV164_AmountSlider")
local HASH_BG_ACCURACY_SLIDER  = Utils.Joaat("BGV164_AccuracySlider")
local HASH_BG_ARMOUR_SLIDER    = Utils.Joaat("BGV164_ArmourSlider")
local HASH_BG_DISTANCE_SLIDER  = Utils.Joaat("BGV164_DistanceSlider")

local HASH_BG_GODMODE          = Utils.Joaat("BGV164_GodMode")
local HASH_BG_SHOWBLIPS        = Utils.Joaat("BGV164_ShowBlips")
local HASH_BG_FOLLOWPLAYER     = Utils.Joaat("BGV164_FollowPlayer")
local HASH_BG_AUTORESPAWN      = Utils.Joaat("BGV164_AutoRespawn")

local HASH_BG_PREVFORMATION    = Utils.Joaat("BGV164_PreviousFormation")
local HASH_BG_NEXTFORMATION    = Utils.Joaat("BGV164_NextFormation")
local HASH_BG_SHOWSELECTION    = Utils.Joaat("BGV164_ShowSelection")
local HASH_BG_SHOWFORMATION    = Utils.Joaat("BGV164_ShowFormation")
local HASH_BG_SHOWAMOUNT       = Utils.Joaat("BGV164_ShowAmount")
local HASH_BG_SHOWBEHAVIOUR    = Utils.Joaat("BGV164_ShowBehaviour")

local HASH_BG_SPAWNSELECTED    = Utils.Joaat("BGV164_SpawnSelected")
local HASH_BG_SPAWN1           = Utils.Joaat("BGV164_Spawn1")
local HASH_BG_SPAWN5           = Utils.Joaat("BGV164_Spawn5")
local HASH_BG_SPAWN10          = Utils.Joaat("BGV164_Spawn10")

local HASH_BG_SPAWNVEHICLE     = Utils.Joaat("BGV164_SpawnVehicle")
local HASH_BG_ENTERVEHICLE     = Utils.Joaat("BGV164_EnterVehicle")
local HASH_BG_EXITVEHICLE      = Utils.Joaat("BGV164_ExitVehicle")
local HASH_BG_TPVEHICLE        = Utils.Joaat("BGV164_TeleportVehicle")
local HASH_BG_ATTACKNEARBY     = Utils.Joaat("BGV164_AttackNearby")
local HASH_BG_REVIVEMISSING    = Utils.Joaat("BGV164_ReviveMissing")
local HASH_BG_TPTO_ME          = Utils.Joaat("BGV164_TeleportToMe")

local HASH_BG_SHOWCOUNT        = Utils.Joaat("BGV164_ShowCount")
local HASH_BG_REFRESHALL       = Utils.Joaat("BGV164_RefreshAll")
local HASH_BG_DELETEDEAD       = Utils.Joaat("BGV164_DeleteDeadOnly")
local HASH_BG_DELETEALL        = Utils.Joaat("BGV164_DeleteAll")

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
    return MODEL_OPTIONS[currentModelIndex] or MODEL_OPTIONS[1]
end

local function currentWeapon()
    return WEAPON_OPTIONS[currentWeaponIndex] or WEAPON_OPTIONS[1]
end

local function currentFormation()
    return FORMATIONS[currentFormationIndex] or FORMATIONS[1]
end

local function currentBehaviour()
    return BEHAVIOUR_OPTIONS[currentBehaviourIndex] or BEHAVIOUR_OPTIONS[1]
end

local function syncModelIndexFromFeature(f)
    local idx = safe(function() return f:GetListIndex() end)
    if idx ~= nil then
        currentModelIndex = math.max(1, math.min(#MODEL_OPTIONS, idx + 1))
    end
end

local function syncWeaponIndexFromFeature(f)
    local idx = safe(function() return f:GetListIndex() end)
    if idx ~= nil then
        currentWeaponIndex = math.max(1, math.min(#WEAPON_OPTIONS, idx + 1))
    end
end

local function syncBehaviourIndexFromFeature(f)
    local idx = safe(function() return f:GetListIndex() end)
    if idx ~= nil then
        currentBehaviourIndex = math.max(1, math.min(#BEHAVIOUR_OPTIONS, idx + 1))
    end
end

local function syncSpawnAmountFromFeature(f)
    local value = safe(function() return f:GetIntValue() end)
    if value ~= nil then
        spawnAmount = math.max(1, math.min(20, value))
    end
end

local function syncAccuracyFromFeature(f)
    local value = safe(function() return f:GetIntValue() end)
    if value ~= nil then
        accuracy = math.max(1, math.min(100, value))
    end
end

local function syncArmourFromFeature(f)
    local value = safe(function() return f:GetIntValue() end)
    if value ~= nil then
        armour = math.max(0, math.min(100, value))
    end
end

local function syncDistanceFromFeature(f)
    local value = safe(function() return f:GetIntValue() end)
    if value ~= nil then
        followDistance = math.max(1, math.min(15, value))
    end
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

local function addBodyguardToPlayerGroup(ped)
    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed == 0 or ped == 0 then
        return
    end

    local groupIndex = safe(function()
        return PED.GET_PED_GROUP_INDEX(playerPed)
    end)

    if groupIndex and groupIndex ~= 0 then
        safe(function() PED.SET_PED_AS_GROUP_MEMBER(ped, groupIndex) end)
        safe(function() PED.SET_PED_CAN_TELEPORT_TO_GROUP_LEADER(ped, groupIndex, true) end)
        safe(function() PED.SET_PED_NEVER_LEAVES_GROUP(ped, true) end)
    end
end

local function applyBlipState(entry)
    if not entry or not entry.blip or entry.blip == 0 then
        return
    end

    if isToggled(HASH_BG_SHOWBLIPS) then
        safe(function() HUD.SET_BLIP_DISPLAY(entry.blip, 2) end)
        safe(function() HUD.SET_BLIP_ALPHA(entry.blip, 255) end)
    else
        safe(function() HUD.SET_BLIP_DISPLAY(entry.blip, 0) end)
        safe(function() HUD.SET_BLIP_ALPHA(entry.blip, 0) end)
    end
end

local function applyBehaviourToPed(ped)
    if not ped or ped == 0 then
        return
    end

    local behaviour = currentBehaviour().label

    if behaviour == "Passive" then
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 0) end)

        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 0, false) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, false) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 13, false) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, false) end)
        safe(function() PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false) end)

        safe(function() TASK.CLEAR_PED_TASKS(ped) end)

    elseif behaviour == "Offensive" then
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 2) end)

        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 0, true) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, true) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 13, true) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true) end)
        safe(function() PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false) end)

    else
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 2) end)

        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 0, true) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, true) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 13, true) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true) end)
        safe(function() PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false) end)

        safe(function()
            TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(ped, 120.0, 0)
        end)
    end
end

local function equipBodyguard(ped)
    local weaponInfo = currentWeapon()
    local weaponHash = MISC.GET_HASH_KEY(weaponInfo.weapon)

    WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, weaponInfo.ammo, false, true)
    safe(function() WEAPON.SET_CURRENT_PED_WEAPON(ped, weaponHash, true) end)

    safe(function() PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true) end)
    safe(function() PED.SET_PED_CAN_SWITCH_WEAPON(ped, true) end)
    safe(function() PED.SET_PED_NEVER_LEAVES_GROUP(ped, true) end)
    safe(function() PED.SET_PED_ACCURACY(ped, accuracy) end)
    safe(function() PED.SET_PED_ARMOUR(ped, armour) end)
    safe(function() PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false) end)
    safe(function() PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, MISC.GET_HASH_KEY("PLAYER")) end)

    if isToggled(HASH_BG_GODMODE) then
        ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
    else
        ENTITY.SET_ENTITY_INVINCIBLE(ped, false)
    end

    addBodyguardToPlayerGroup(ped)
    applyBehaviourToPed(ped)
end

local function formationOffset(index, total)
    local formation = currentFormation().label

    if formation == "Line" then
        return (index - 1) * 1.5, -followDistance, 0.0
    elseif formation == "Circle" then
        local angle = ((index - 1) / math.max(total, 1)) * 6.28318
        return math.cos(angle) * followDistance, math.sin(angle) * followDistance, 0.0
    elseif formation == "Triangle" then
        if index == 1 then
            return 0.0, -followDistance, 0.0
        elseif index % 2 == 0 then
            return followDistance, 0.0 - (index * 0.1), 0.0
        else
            return -followDistance, 0.0 - (index * 0.1), 0.0
        end
    else
        if index % 2 == 0 then
            return followDistance + index * 0.2, -1.5 - (index * 0.15), 0.0
        else
            return -followDistance - index * 0.2, -1.5 - (index * 0.15), 0.0
        end
    end
end

local function applyFollowOne(entry, index, total)
    if not entry or not entry.ped or entry.ped == 0 then
        return
    end

    if not isToggled(HASH_BG_FOLLOWPLAYER) then
        return
    end

    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed == 0 then
        return
    end

    local offX, offY, offZ = formationOffset(index, total)

    addBodyguardToPlayerGroup(entry.ped)

    if currentBehaviour().label ~= "Aggressive" then
        safe(function()
            TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
                entry.ped,
                playerPed,
                offX,
                offY,
                offZ,
                2.0,
                -1,
                3.0,
                true
            )
        end)
    end
end

local function applyFollowAll()
    cleanupBodyguards()

    for i, entry in ipairs(bodyguards) do
        applyFollowOne(entry, i, #bodyguards)
    end
end

local function behaviourTick()
    local behaviour = currentBehaviour().label
    local playerPed = PLAYER.PLAYER_PED_ID()

    if playerPed == 0 then
        return
    end

    cleanupBodyguards()

    if behaviour == "Passive" then
        return
    end

    if behaviour == "Offensive" then
        local playerInCombat = safe(function()
            return PED.IS_PED_IN_COMBAT(playerPed, 0)
        end)

        if not playerInCombat then
            return
        end

        for _, entry in ipairs(bodyguards) do
            if entry and entry.ped and ENTITY.DOES_ENTITY_EXIST(entry.ped) then
                addBodyguardToPlayerGroup(entry.ped)

                safe(function()
                    TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(entry.ped, 120.0, 0)
                end)
            end
        end
    else
        for _, entry in ipairs(bodyguards) do
            if entry and entry.ped and ENTITY.DOES_ENTITY_EXIST(entry.ped) then
                safe(function()
                    TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(entry.ped, 120.0, 0)
                end)
            end
        end
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
    local modelHash = MISC.GET_HASH_KEY(modelInfo.model)

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
    addBodyguardToPlayerGroup(ped)

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

local function teleportToVehicle()
    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed == 0 then
        return
    end

    if not PED.IS_PED_IN_ANY_VEHICLE(playerPed, false) then
        warn("Tu n'es pas dans un véhicule")
        return
    end

    local veh = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
    local coords = ENTITY.GET_ENTITY_COORDS(veh, true)

    cleanupBodyguards()

    for i, entry in ipairs(bodyguards) do
        local exists = safe(function()
            return entry and entry.ped and ENTITY.DOES_ENTITY_EXIST(entry.ped)
        end)

        if exists then
            safe(function()
                ENTITY.SET_ENTITY_COORDS(
                    entry.ped,
                    coords.x + (i * 1.0),
                    coords.y + 2.0,
                    coords.z,
                    false,
                    false,
                    false,
                    false
                )
            end)
        end
    end

    info("Téléportation au véhicule terminée")
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

local function attackNearby()
    cleanupBodyguards()

    for _, entry in ipairs(bodyguards) do
        if entry and entry.ped and ENTITY.DOES_ENTITY_EXIST(entry.ped) then
            safe(function()
                TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(entry.ped, 120.0, 0)
            end)
        end
    end

    info("Attaque des ennemis proches")
end

local function spawnInMyVehicle()
    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed == 0 then
        return
    end

    if not PED.IS_PED_IN_ANY_VEHICLE(playerPed, false) then
        warn("Tu n'es pas dans un véhicule")
        return
    end

    local veh = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
    local ped = createBodyguard(1.5, 1.5, 1.0)

    if ped ~= 0 then
        safe(function()
            PED.SET_PED_INTO_VEHICLE(ped, veh, 0)
        end)
        info("Spawn dans ton véhicule")
    end
end

local function putAllInMyVehicle()
    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed == 0 then
        return
    end

    if not PED.IS_PED_IN_ANY_VEHICLE(playerPed, false) then
        warn("Tu n'es pas dans un véhicule")
        return
    end

    local veh = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
    local seat = 0

    cleanupBodyguards()

    for _, entry in ipairs(bodyguards) do
        if entry and entry.ped and ENTITY.DOES_ENTITY_EXIST(entry.ped) then
            safe(function()
                PED.SET_PED_INTO_VEHICLE(entry.ped, veh, seat)
            end)
            seat = seat + 1
        end
    end

    info("Bodyguards placés dans ton véhicule")
end

local function exitVehicleAll()
    cleanupBodyguards()

    for _, entry in ipairs(bodyguards) do
        if entry and entry.ped and ENTITY.DOES_ENTITY_EXIST(entry.ped) then
            local inVeh = safe(function()
                return PED.IS_PED_IN_ANY_VEHICLE(entry.ped, false)
            end)

            if inVeh then
                safe(function()
                    TASK.TASK_LEAVE_VEHICLE(entry.ped, PED.GET_VEHICLE_PED_IS_IN(entry.ped, false), 0)
                end)
            end
        end
    end

    info("Les bodyguards sortent du véhicule")
end

local function reviveMissing()
    local missing = spawnAmount - bodyguardCount()
    if missing <= 0 then
        info("Aucun revive nécessaire")
        return
    end

    spawnAmountCustom(missing)
    info("Revive de " .. tostring(missing) .. " bodyguards")
end

FeatureMgr.AddFeature(HASH_BG_MODEL_COMBO, "V164 Agent Model", eFeatureType.Combo, "Choisir le modèle du garde", function(f)
    syncModelIndexFromFeature(f)
    info("Model: " .. currentModel().label)
end, true)

FeatureMgr.AddFeature(HASH_BG_WEAPON_COMBO, "V164 Primary Weapon", eFeatureType.Combo, "Choisir l'arme du garde", function(f)
    syncWeaponIndexFromFeature(f)
    info("Weapon: " .. currentWeapon().label)
end, true)

FeatureMgr.AddFeature(HASH_BG_BEHAVIOUR_COMBO, "V164 Behaviour", eFeatureType.Combo, "Passive / Offensive / Aggressive", function(f)
    syncBehaviourIndexFromFeature(f)
    refreshAll()
    info("Behaviour: " .. currentBehaviour().label)
end, true)

FeatureMgr.AddFeature(HASH_BG_AMOUNT_SLIDER, "V164 Spawn Amount", eFeatureType.SliderInt, "Nombre de gardes à spawn", function(f)
    syncSpawnAmountFromFeature(f)
    info("Spawn Amount: " .. tostring(spawnAmount))
end, true)

FeatureMgr.AddFeature(HASH_BG_ACCURACY_SLIDER, "V164 Accuracy", eFeatureType.SliderInt, "Précision", function(f)
    syncAccuracyFromFeature(f)
    refreshAll()
end, true)

FeatureMgr.AddFeature(HASH_BG_ARMOUR_SLIDER, "V164 Armour", eFeatureType.SliderInt, "Armure", function(f)
    syncArmourFromFeature(f)
    refreshAll()
end, true)

FeatureMgr.AddFeature(HASH_BG_DISTANCE_SLIDER, "V164 Follow Distance", eFeatureType.SliderInt, "Distance", function(f)
    syncDistanceFromFeature(f)
    applyFollowAll()
end, true)

FeatureMgr.AddFeature(HASH_BG_GODMODE, "V164 God Mode", eFeatureType.Toggle, "Invincibilité", function(f)
    refreshAll()
end, true)

FeatureMgr.AddFeature(HASH_BG_SHOWBLIPS, "V164 Show Blips", eFeatureType.Toggle, "Blips carte", function(f)
    refreshAll()
end, true)

FeatureMgr.AddFeature(HASH_BG_FOLLOWPLAYER, "V164 Follow Player", eFeatureType.Toggle, "Suivre le joueur", function(f)
    applyFollowAll()
end, true)

FeatureMgr.AddFeature(HASH_BG_AUTORESPAWN, "V164 Auto Respawn", eFeatureType.Toggle, "Respawn auto", function(f)
    autoRespawn = f:IsToggled()
    info("Auto Respawn: " .. (autoRespawn and "ON" or "OFF"))
end, true)

FeatureMgr.AddFeature(HASH_BG_PREVFORMATION, "V164 Previous Formation", eFeatureType.Button, "", function(f)
    previousFormation()
end, true)

FeatureMgr.AddFeature(HASH_BG_NEXTFORMATION, "V164 Next Formation", eFeatureType.Button, "", function(f)
    nextFormation()
end, true)

FeatureMgr.AddFeature(HASH_BG_SHOWSELECTION, "V164 Show Current Selection", eFeatureType.Button, "", function(f)
    info("Model: " .. currentModel().label .. " | Weapon: " .. currentWeapon().label)
end, true)

FeatureMgr.AddFeature(HASH_BG_SHOWFORMATION, "V164 Show Formation", eFeatureType.Button, "", function(f)
    info("Formation: " .. currentFormation().label)
end, true)

FeatureMgr.AddFeature(HASH_BG_SHOWAMOUNT, "V164 Show Spawn Amount", eFeatureType.Button, "", function(f)
    info("Spawn Amount: " .. tostring(spawnAmount))
end, true)

FeatureMgr.AddFeature(HASH_BG_SHOWBEHAVIOUR, "V164 Show Behaviour", eFeatureType.Button, "", function(f)
    info("Behaviour: " .. currentBehaviour().label)
end, true)

FeatureMgr.AddFeature(HASH_BG_SPAWNSELECTED, "V164 Spawn Selected Amount", eFeatureType.Button, "", function(f)
    spawnAmountCustom(spawnAmount)
end, true)

FeatureMgr.AddFeature(HASH_BG_SPAWN1, "V164 Spawn 1", eFeatureType.Button, "", function(f)
    local ped = createBodyguard(2.0, 2.0, 1.0)
    if ped ~= 0 then
        applyFollowAll()
    end
end, true)

FeatureMgr.AddFeature(HASH_BG_SPAWN5, "V164 Spawn 5", eFeatureType.Button, "", function(f)
    spawnAmountCustom(5)
end, true)

FeatureMgr.AddFeature(HASH_BG_SPAWN10, "V164 Spawn 10", eFeatureType.Button, "", function(f)
    spawnAmountCustom(10)
end, true)

FeatureMgr.AddFeature(HASH_BG_SPAWNVEHICLE, "V164 Spawn In My Vehicle", eFeatureType.Button, "", function(f)
    spawnInMyVehicle()
end, true)

FeatureMgr.AddFeature(HASH_BG_ENTERVEHICLE, "V164 Enter My Vehicle", eFeatureType.Button, "", function(f)
    putAllInMyVehicle()
end, true)

FeatureMgr.AddFeature(HASH_BG_EXITVEHICLE, "V164 Exit Vehicle", eFeatureType.Button, "", function(f)
    exitVehicleAll()
end, true)

FeatureMgr.AddFeature(HASH_BG_TPVEHICLE, "V164 Teleport To Vehicle", eFeatureType.Button, "", function(f)
    teleportToVehicle()
end, true)

FeatureMgr.AddFeature(HASH_BG_ATTACKNEARBY, "V164 Attack Nearby", eFeatureType.Button, "", function(f)
    attackNearby()
end, true)

FeatureMgr.AddFeature(HASH_BG_REVIVEMISSING, "V164 Revive Missing", eFeatureType.Button, "", function(f)
    reviveMissing()
end, true)

FeatureMgr.AddFeature(HASH_BG_TPTO_ME, "V164 Teleport To Me", eFeatureType.Button, "", function(f)
    teleportAll()
end, true)

FeatureMgr.AddFeature(HASH_BG_SHOWCOUNT, "V164 Show Count", eFeatureType.Button, "", function(f)
    if autoRespawn and bodyguardCount() < spawnAmount then
        reviveMissing()
    else
        info("Bodyguards actifs: " .. tostring(bodyguardCount()))
    end
end, true)

FeatureMgr.AddFeature(HASH_BG_REFRESHALL, "V164 Refresh All", eFeatureType.Button, "", function(f)
    if autoRespawn and bodyguardCount() < spawnAmount then
        reviveMissing()
    end
    refreshAll()
end, true)

FeatureMgr.AddFeature(HASH_BG_DELETEDEAD, "V164 Delete Dead Only", eFeatureType.Button, "", function(f)
    deleteDeadOnly()
end, true)

FeatureMgr.AddFeature(HASH_BG_DELETEALL, "V164 Delete All", eFeatureType.Button, "", function(f)
    deleteAll()
end, true)

local modelCombo = getFeature(HASH_BG_MODEL_COMBO)
if modelCombo then
    modelCombo:SetList(MODEL_LABELS)
    modelCombo:SetListIndex(0)
end

local weaponCombo = getFeature(HASH_BG_WEAPON_COMBO)
if weaponCombo then
    weaponCombo:SetList(WEAPON_LABELS)
    weaponCombo:SetListIndex(0)
end

local behaviourCombo = getFeature(HASH_BG_BEHAVIOUR_COMBO)
if behaviourCombo then
    behaviourCombo:SetList(BEHAVIOUR_LABELS)
    behaviourCombo:SetListIndex(1)
end

local amountSlider = getFeature(HASH_BG_AMOUNT_SLIDER)
if amountSlider then
    amountSlider:SetLimitValues(1, 20)
    amountSlider:SetStepSize(1)
    amountSlider:SetFormat("%d")
    amountSlider:SetIntValue(3)
end

local accuracySlider = getFeature(HASH_BG_ACCURACY_SLIDER)
if accuracySlider then
    accuracySlider:SetLimitValues(1, 100)
    accuracySlider:SetStepSize(1)
    accuracySlider:SetFormat("%d")
    accuracySlider:SetIntValue(75)
end

local armourSlider = getFeature(HASH_BG_ARMOUR_SLIDER)
if armourSlider then
    armourSlider:SetLimitValues(0, 100)
    armourSlider:SetStepSize(1)
    armourSlider:SetFormat("%d")
    armourSlider:SetIntValue(100)
end

local distanceSlider = getFeature(HASH_BG_DISTANCE_SLIDER)
if distanceSlider then
    distanceSlider:SetLimitValues(1, 15)
    distanceSlider:SetStepSize(1)
    distanceSlider:SetFormat("%d")
    distanceSlider:SetIntValue(3)
end

ClickGUI.AddTab("Bodyguard Menu V164", function()

    behaviourTick()

    if ClickGUI.BeginCustomChildWindow("Command Center") then
        ClickGUI.RenderFeature(HASH_BG_SHOWSELECTION)
        ClickGUI.RenderFeature(HASH_BG_SHOWFORMATION)
        ClickGUI.RenderFeature(HASH_BG_SHOWBEHAVIOUR)
        ClickGUI.RenderFeature(HASH_BG_SHOWCOUNT)
        ClickGUI.RenderFeature(HASH_BG_REFRESHALL)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Identity") then
        ClickGUI.RenderFeature(HASH_BG_MODEL_COMBO)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Arsenal") then
        ClickGUI.RenderFeature(HASH_BG_WEAPON_COMBO)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Behaviour & Formation") then
        ClickGUI.RenderFeature(HASH_BG_BEHAVIOUR_COMBO)
        ClickGUI.RenderFeature(HASH_BG_FOLLOWPLAYER)
        ClickGUI.RenderFeature(HASH_BG_PREVFORMATION)
        ClickGUI.RenderFeature(HASH_BG_NEXTFORMATION)
        ClickGUI.RenderFeature(HASH_BG_DISTANCE_SLIDER)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Combat Stats") then
        ClickGUI.RenderFeature(HASH_BG_ACCURACY_SLIDER)
        ClickGUI.RenderFeature(HASH_BG_ARMOUR_SLIDER)
        ClickGUI.RenderFeature(HASH_BG_ATTACKNEARBY)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("System") then
        ClickGUI.RenderFeature(HASH_BG_GODMODE)
        ClickGUI.RenderFeature(HASH_BG_SHOWBLIPS)
        ClickGUI.RenderFeature(HASH_BG_AUTORESPAWN)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Deployment") then
        ClickGUI.RenderFeature(HASH_BG_AMOUNT_SLIDER)
        ClickGUI.RenderFeature(HASH_BG_SHOWAMOUNT)
        ClickGUI.RenderFeature(HASH_BG_SPAWNSELECTED)
        ClickGUI.RenderFeature(HASH_BG_SPAWN1)
        ClickGUI.RenderFeature(HASH_BG_SPAWN5)
        ClickGUI.RenderFeature(HASH_BG_SPAWN10)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Vehicle Support") then
        ClickGUI.RenderFeature(HASH_BG_SPAWNVEHICLE)
        ClickGUI.RenderFeature(HASH_BG_ENTERVEHICLE)
        ClickGUI.RenderFeature(HASH_BG_EXITVEHICLE)
        ClickGUI.RenderFeature(HASH_BG_TPVEHICLE)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Quick Actions") then
        ClickGUI.RenderFeature(HASH_BG_TPTO_ME)
        ClickGUI.RenderFeature(HASH_BG_REVIVEMISSING)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Cleanup") then
        ClickGUI.RenderFeature(HASH_BG_DELETEDEAD)
        ClickGUI.RenderFeature(HASH_BG_DELETEALL)
        ClickGUI.EndCustomChildWindow()
    end
end)

info("Menu Bodyguard V164 chargé")
info("Model: " .. currentModel().label)
info("Weapon: " .. currentWeapon().label)
info("Behaviour: " .. currentBehaviour().label)
info("Formation: " .. currentFormation().label)
info("Spawn Amount: " .. tostring(spawnAmount))
