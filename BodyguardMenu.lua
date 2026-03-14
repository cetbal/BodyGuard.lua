dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

local bodyguards = {}
local playerGroup = 0

------------------------------------------------
-- CONFIG
------------------------------------------------

local MODEL_OPTIONS = {
    { label = "Security",  model = "s_m_m_security_01"  },
    { label = "FIB",       model = "s_m_m_fiboffice_01" },
    { label = "CIA",       model = "s_m_m_ciasec_01"    },
    { label = "SWAT",      model = "s_m_y_swat_01"      },
    { label = "Black Ops", model = "s_m_y_blackops_01"  }
}

local WEAPON_OPTIONS = {
    { label = "Pistol",         weapon = "WEAPON_PISTOL",       ammo = 500  },
    { label = "Combat Pistol",  weapon = "WEAPON_COMBATPISTOL", ammo = 500  },
    { label = "SMG",            weapon = "WEAPON_SMG",          ammo = 800  },
    { label = "Carbine Rifle",  weapon = "WEAPON_CARBINERIFLE", ammo = 1200 },
    { label = "Pump Shotgun",   weapon = "WEAPON_PUMPSHOTGUN",  ammo = 300  }
}

local FORMATION_OPTIONS = {
    { label = "Line"    },
    { label = "Circle"  },
    { label = "Diamond" },
    { label = "Around"  }
}

local BEHAVIOUR_OPTIONS = {
    { label = "Passive"    },
    { label = "Protect"    },
    { label = "Aggressive" }
}

local MODEL_LABELS = {}
local WEAPON_LABELS = {}
local FORMATION_LABELS = {}
local BEHAVIOUR_LABELS = {}

for i, v in ipairs(MODEL_OPTIONS) do MODEL_LABELS[i] = v.label end
for i, v in ipairs(WEAPON_OPTIONS) do WEAPON_LABELS[i] = v.label end
for i, v in ipairs(FORMATION_OPTIONS) do FORMATION_LABELS[i] = v.label end
for i, v in ipairs(BEHAVIOUR_OPTIONS) do BEHAVIOUR_LABELS[i] = v.label end

local currentModelIndex = 1
local currentWeaponIndex = 4
local currentFormationIndex = 1
local currentBehaviourIndex = 2

local spawnAmount = 3
local followDistance = 3
local accuracyValue = 80
local armourValue = 100

local BLIP_COLOR = 5
local BLIP_SPRITE = 1
local BLIP_SCALE = 0.85

local autoRespawnDelay = 1500

------------------------------------------------
-- LOG / SAFE
------------------------------------------------

local function info(text)
    Logger.Log(eLogColor.LIGHTGREEN, "Bodyguard", text)
    GUI.AddToast("Bodyguard", text, 3000, eToastPos.TOP_RIGHT)
end

local function warn(text)
    Logger.Log(eLogColor.LIGHTRED, "Bodyguard", text)
    GUI.AddToast("Bodyguard", text, 4000, eToastPos.TOP_RIGHT)
end

local function safe(fn)
    local ok, result = pcall(fn)
    if ok then
        return result
    end
    return nil
end

------------------------------------------------
-- HELPERS
------------------------------------------------

local function player_ped()
    return PLAYER.PLAYER_PED_ID()
end

local function player_coords()
    local ped = player_ped()
    if ped == 0 then
        return nil
    end
    return ENTITY.GET_ENTITY_COORDS(ped, true)
end

local function player_vehicle()
    local ped = player_ped()
    if ped == 0 then
        return 0
    end

    local veh = safe(function()
        return PED.GET_VEHICLE_PED_IS_IN(ped, false)
    end)

    return veh or 0
end

local function get_current_model()
    return MODEL_OPTIONS[currentModelIndex] or MODEL_OPTIONS[1]
end

local function get_current_weapon()
    return WEAPON_OPTIONS[currentWeaponIndex] or WEAPON_OPTIONS[1]
end

local function get_current_formation()
    return FORMATION_OPTIONS[currentFormationIndex] or FORMATION_OPTIONS[1]
end

local function get_current_behaviour()
    return BEHAVIOUR_OPTIONS[currentBehaviourIndex] or BEHAVIOUR_OPTIONS[1]
end

local function load_model(modelHash)
    STREAMING.REQUEST_MODEL(modelHash)

    local i = 0
    while not STREAMING.HAS_MODEL_LOADED(modelHash) and i < 300 do
        SYSTEM.WAIT(0)
        i = i + 1
    end

    return STREAMING.HAS_MODEL_LOADED(modelHash)
end

------------------------------------------------
-- GROUP
------------------------------------------------

local function ensure_group()
    if playerGroup ~= 0 then
        return
    end

    local pPed = player_ped()
    if pPed == 0 then
        return
    end

    playerGroup = PED.CREATE_GROUP(0)

    PED.SET_PED_AS_GROUP_LEADER(pPed, playerGroup)
    PED.SET_GROUP_SEPARATION_RANGE(playerGroup, 9999.0)
end

local function add_guard_to_group(ped)
    ensure_group()

    if playerGroup == 0 or ped == 0 then
        return
    end

    PED.SET_PED_AS_GROUP_MEMBER(ped, playerGroup)
    PED.SET_PED_CAN_TELEPORT_TO_GROUP_LEADER(ped, playerGroup, true)
end

------------------------------------------------
-- BODYGUARD STATE
------------------------------------------------

local function bodyguard_exists(entry)
    if not entry or not entry.ped or entry.ped == 0 then
        return false
    end

    return safe(function()
        return ENTITY.DOES_ENTITY_EXIST(entry.ped)
    end) or false
end

local function bodyguard_health(entry)
    if not bodyguard_exists(entry) then
        return 0
    end

    local health = safe(function()
        return ENTITY.GET_ENTITY_HEALTH(entry.ped)
    end)

    return health or 0
end

local function bodyguard_dead(entry)
    return bodyguard_health(entry) <= 0
end

local function hide_blip(blip)
    if blip == nil or blip == 0 then
        return
    end

    safe(function() HUD.SET_BLIP_DISPLAY(blip, 0) end)
    safe(function() HUD.SET_BLIP_ALPHA(blip, 0) end)
end

local function create_blip(ped)
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

local function apply_blip_state(entry, showBlips)
    if not entry or not entry.blip or entry.blip == 0 then
        return
    end

    if showBlips then
        safe(function() HUD.SET_BLIP_DISPLAY(entry.blip, 2) end)
        safe(function() HUD.SET_BLIP_ALPHA(entry.blip, 255) end)
    else
        safe(function() HUD.SET_BLIP_DISPLAY(entry.blip, 0) end)
        safe(function() HUD.SET_BLIP_ALPHA(entry.blip, 0) end)
    end
end

local function cleanup_bodyguards()
    local cleaned = {}

    for _, entry in ipairs(bodyguards) do
        if bodyguard_exists(entry) then
            table.insert(cleaned, entry)
        else
            if entry and entry.blip then
                hide_blip(entry.blip)
            end
        end
    end

    bodyguards = cleaned
end

local function bodyguard_count()
    cleanup_bodyguards()
    return #bodyguards
end

------------------------------------------------
-- FEATURES STATE HELPERS
------------------------------------------------

local function is_toggled(feature)
    if not feature then
        return false
    end

    return feature:IsToggled()
end

local function sync_combo_index(feature, maxValue, currentValue)
    local idx = safe(function()
        return feature:GetListIndex()
    end)

    if idx == nil then
        return currentValue
    end

    idx = idx + 1
    if idx < 1 then idx = 1 end
    if idx > maxValue then idx = maxValue end
    return idx
end

local function sync_slider_value(feature, minValue, maxValue, currentValue)
    local value = safe(function()
        return feature:GetIntValue()
    end)

    if value == nil then
        return currentValue
    end

    if value < minValue then value = minValue end
    if value > maxValue then value = maxValue end
    return value
end

------------------------------------------------
-- AI
------------------------------------------------

local function clear_guard_tasks(ped)
    if ped == 0 then
        return
    end

    safe(function() TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped) end)
end

local function apply_behaviour(entry)
    if not entry or not entry.ped or entry.ped == 0 then
        return
    end

    local ped = entry.ped
    local behaviour = get_current_behaviour().label

    if behaviour == "Passive" then
        clear_guard_tasks(ped)
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 0) end)

    elseif behaviour == "Protect" then
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 1) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 1) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 1) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true) end)
        add_guard_to_group(ped)

    else
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, true) end)
        safe(function() PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false) end)
        add_guard_to_group(ped)
    end
end

local function equip_guard(entry, godModeEnabled, showBlipsEnabled)
    if not entry or not entry.ped or entry.ped == 0 then
        return
    end

    local ped = entry.ped
    local weaponInfo = WEAPON_OPTIONS[entry.weaponIndex] or WEAPON_OPTIONS[1]
    local weaponHash = MISC.GET_HASH_KEY(weaponInfo.weapon)

    WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, weaponInfo.ammo, false, true)

    safe(function() PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true) end)
    safe(function() PED.SET_PED_NEVER_LEAVES_GROUP(ped, true) end)
    safe(function() PED.SET_PED_CAN_SWITCH_WEAPON(ped, true) end)
    safe(function() PED.SET_PED_ACCURACY(ped, accuracyValue) end)
    safe(function() PED.SET_PED_ARMOUR(ped, armourValue) end)

    if godModeEnabled then
        ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
    else
        ENTITY.SET_ENTITY_INVINCIBLE(ped, false)
    end

    apply_behaviour(entry)
    add_guard_to_group(ped)
    apply_blip_state(entry, showBlipsEnabled)
end

local function formation_offset(index, total)
    local formation = get_current_formation().label

    if formation == "Line" then
        return (index - 1) * 1.5, -(followDistance + 1.0), 0.0
    elseif formation == "Circle" then
        local angle = ((index - 1) / math.max(total, 1)) * 6.28318
        return math.cos(angle) * followDistance, math.sin(angle) * followDistance, 0.0
    elseif formation == "Diamond" then
        local map = {
            { 0.0, -followDistance, 0.0 },
            { followDistance, 0.0, 0.0 },
            { 0.0, followDistance, 0.0 },
            { -followDistance, 0.0, 0.0 }
        }
        local item = map[((index - 1) % #map) + 1]
        return item[1], item[2], item[3]
    else
        if index % 2 == 0 then
            return followDistance + (index * 0.2), -(followDistance * 0.7) - (index * 0.1), 0.0
        else
            return -(followDistance + (index * 0.2)), -(followDistance * 0.7) - (index * 0.1), 0.0
        end
    end
end

local function apply_follow_one(entry, index, total)
    if not entry or not entry.ped or entry.ped == 0 then
        return
    end

    local pPed = player_ped()
    if pPed == 0 then
        return
    end

    local offX, offY, offZ = formation_offset(index, total)

    safe(function()
        TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
            entry.ped,
            pPed,
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

local function order_guards_by_behaviour(followEnabled)
    cleanup_bodyguards()

    local behaviour = get_current_behaviour().label

    for i, entry in ipairs(bodyguards) do
        if bodyguard_exists(entry) then
            if behaviour == "Passive" then
                clear_guard_tasks(entry.ped)

            elseif behaviour == "Protect" then
                if followEnabled then
                    apply_follow_one(entry, i, #bodyguards)
                end

            else
                safe(function()
                    TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(entry.ped, 100.0, 0)
                end)

                if followEnabled then
                    apply_follow_one(entry, i, #bodyguards)
                end
            end
        end
    end
end

------------------------------------------------
-- SPAWN
------------------------------------------------

local function create_guard_with_loadout(modelIndex, weaponIndex, offsetX, offsetY, offsetZ, godModeEnabled, showBlipsEnabled)
    local coords = player_coords()
    if not coords then
        warn("Impossible de récupérer la position du joueur")
        return nil
    end

    local modelInfo = MODEL_OPTIONS[modelIndex] or MODEL_OPTIONS[1]
    local modelHash = MISC.GET_HASH_KEY(modelInfo.model)

    if not STREAMING.IS_MODEL_IN_CDIMAGE(modelHash) then
        warn("Modèle absent du jeu")
        return nil
    end

    if not STREAMING.IS_MODEL_VALID(modelHash) then
        warn("Modèle invalide")
        return nil
    end

    if not STREAMING.IS_MODEL_A_PED(modelHash) then
        warn("Le modèle n'est pas un ped")
        return nil
    end

    if not load_model(modelHash) then
        warn("Chargement du modèle échoué")
        return nil
    end

    local ped = PED.CREATE_PED(
        4,
        modelHash,
        coords.x + offsetX,
        coords.y + offsetY,
        coords.z + offsetZ,
        0.0,
        true,
        true
    )

    if ped == 0 then
        warn("CREATE_PED a échoué")
        return nil
    end

    local entry = {
        ped = ped,
        blip = create_blip(ped),
        modelIndex = modelIndex,
        weaponIndex = weaponIndex,
        deathTime = 0
    }

    table.insert(bodyguards, entry)
    equip_guard(entry, godModeEnabled, showBlipsEnabled)

    local modelName = (MODEL_OPTIONS[modelIndex] or MODEL_OPTIONS[1]).label
    local weaponName = (WEAPON_OPTIONS[weaponIndex] or WEAPON_OPTIONS[1]).label
    info("Spawn: " .. modelName .. " | " .. weaponName)

    return entry
end

local function spawn_selected_amount(godModeEnabled, showBlipsEnabled, followEnabled)
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
        {  0.0,  3.0, 1.0 }
    }

    for i = 1, spawnAmount do
        local o = offsets[i] or { i * 1.1, 1.0, 1.0 }
        create_guard_with_loadout(currentModelIndex, currentWeaponIndex, o[1], o[2], o[3], godModeEnabled, showBlipsEnabled)
    end

    order_guards_by_behaviour(followEnabled)
end

------------------------------------------------
-- VEHICLE
------------------------------------------------

local function seat_in_my_vehicle()
    local veh = player_vehicle()
    if veh == 0 then
        warn("Tu n'es pas dans un véhicule")
        return
    end

    cleanup_bodyguards()

    local maxPassengers = safe(function()
        return VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(veh)
    end) or 3

    local seat = 0

    for _, entry in ipairs(bodyguards) do
        if bodyguard_exists(entry) then
            if seat <= maxPassengers then
                safe(function()
                    PED.SET_PED_INTO_VEHICLE(entry.ped, veh, seat)
                end)
                seat = seat + 1
            end
        end
    end

    info("Placement dans le véhicule terminé")
end

local function exit_vehicle()
    cleanup_bodyguards()

    for _, entry in ipairs(bodyguards) do
        if bodyguard_exists(entry) then
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

    info("Sortie du véhicule demandée")
end

local function teleport_to_vehicle()
    local veh = player_vehicle()
    if veh == 0 then
        warn("Tu n'es pas dans un véhicule")
        return
    end

    local coords = safe(function()
        return ENTITY.GET_ENTITY_COORDS(veh, true)
    end)

    if not coords then
        return
    end

    cleanup_bodyguards()

    for i, entry in ipairs(bodyguards) do
        if bodyguard_exists(entry) then
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

local function teleport_to_me()
    local coords = player_coords()
    if not coords then
        return
    end

    cleanup_bodyguards()

    for i, entry in ipairs(bodyguards) do
        if bodyguard_exists(entry) then
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

    info("Téléportation sur le joueur terminée")
end

------------------------------------------------
-- DELETE
------------------------------------------------

local function kill_entry(entry)
    if not entry or not entry.ped or entry.ped == 0 then
        return
    end

    safe(function()
        if ENTITY.DOES_ENTITY_EXIST(entry.ped) then
            ENTITY.SET_ENTITY_INVINCIBLE(entry.ped, false)
            ENTITY.SET_ENTITY_HEALTH(entry.ped, 0, 0, 0)
        end
    end)

    if entry.blip then
        hide_blip(entry.blip)
    end
end

local function delete_dead_only()
    cleanup_bodyguards()

    local cleaned = {}

    for _, entry in ipairs(bodyguards) do
        if bodyguard_dead(entry) then
            kill_entry(entry)
        else
            table.insert(cleaned, entry)
        end
    end

    bodyguards = cleaned
    info("Delete Dead Only terminé | Actifs: " .. tostring(bodyguard_count()))
end

local function delete_all()
    cleanup_bodyguards()

    for _, entry in ipairs(bodyguards) do
        kill_entry(entry)
    end

    bodyguards = {}
    info("Delete All terminé | Actifs: 0")
end

------------------------------------------------
-- AUTO RESPAWN
------------------------------------------------

local function auto_respawn_tick(godModeEnabled, showBlipsEnabled, followEnabled)
    if not autoRespawnToggle or not autoRespawnToggle:IsToggled() then
        return
    end

    local now = safe(function()
        return MISC.GET_GAME_TIMER()
    end) or 0

    local toRespawn = {}

    for _, entry in ipairs(bodyguards) do
        if entry and entry.ped and entry.ped ~= 0 then
            if bodyguard_dead(entry) then
                if entry.deathTime == nil or entry.deathTime == 0 then
                    entry.deathTime = now
                elseif now - entry.deathTime >= autoRespawnDelay then
                    table.insert(toRespawn, {
                        modelIndex = entry.modelIndex,
                        weaponIndex = entry.weaponIndex
                    })
                    entry.ped = 0
                    if entry.blip then
                        hide_blip(entry.blip)
                        entry.blip = 0
                    end
                end
            end
        end
    end

    cleanup_bodyguards()

    for _, data in ipairs(toRespawn) do
        create_guard_with_loadout(data.modelIndex, data.weaponIndex, 2.0, 2.0, 1.0, godModeEnabled, showBlipsEnabled)
    end

    if #toRespawn > 0 then
        order_guards_by_behaviour(followEnabled)
    end
end

------------------------------------------------
-- FEATURES
------------------------------------------------

local modelCombo = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_ModelCombo"),
    "Agent Model",
    eFeatureType.Combo,
    "",
    function(f)
        currentModelIndex = sync_combo_index(f, #MODEL_OPTIONS, currentModelIndex)
        info("Model: " .. get_current_model().label)
    end,
    true
)

local weaponCombo = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_WeaponCombo"),
    "Primary Weapon",
    eFeatureType.Combo,
    "",
    function(f)
        currentWeaponIndex = sync_combo_index(f, #WEAPON_OPTIONS, currentWeaponIndex)
        info("Weapon: " .. get_current_weapon().label)
    end,
    true
)

local formationCombo = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_FormationCombo"),
    "Formation",
    eFeatureType.Combo,
    "",
    function(f)
        currentFormationIndex = sync_combo_index(f, #FORMATION_OPTIONS, currentFormationIndex)
        info("Formation: " .. get_current_formation().label)
    end,
    true
)

local behaviourCombo = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_BehaviourCombo"),
    "Behaviour",
    eFeatureType.Combo,
    "",
    function(f)
        currentBehaviourIndex = sync_combo_index(f, #BEHAVIOUR_OPTIONS, currentBehaviourIndex)
        info("Behaviour: " .. get_current_behaviour().label)
    end,
    true
)

local amountSlider = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_SpawnAmount"),
    "Spawn Amount",
    eFeatureType.SliderInt,
    "",
    function(f)
        spawnAmount = sync_slider_value(f, 1, 20, spawnAmount)
        info("Spawn Amount: " .. tostring(spawnAmount))
    end,
    true
)

local accuracySlider = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_Accuracy"),
    "Accuracy",
    eFeatureType.SliderInt,
    "",
    function(f)
        accuracyValue = sync_slider_value(f, 1, 100, accuracyValue)
        info("Accuracy: " .. tostring(accuracyValue))
    end,
    true
)

local armourSlider = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_Armour"),
    "Armour",
    eFeatureType.SliderInt,
    "",
    function(f)
        armourValue = sync_slider_value(f, 0, 100, armourValue)
        info("Armour: " .. tostring(armourValue))
    end,
    true
)

local distanceSlider = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_FollowDistance"),
    "Follow Distance",
    eFeatureType.SliderInt,
    "",
    function(f)
        followDistance = sync_slider_value(f, 1, 15, followDistance)
        info("Follow Distance: " .. tostring(followDistance))
    end,
    true
)

local godModeToggle = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_GodMode"),
    "God Mode",
    eFeatureType.Toggle,
    "",
    function(f)
        info("God Mode: " .. (f:IsToggled() and "ON" or "OFF"))
    end,
    true
)

local showBlipsToggle = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_ShowBlips"),
    "Show Blips",
    eFeatureType.Toggle,
    "",
    function(f)
        info("Show Blips: " .. (f:IsToggled() and "ON" or "OFF"))
    end,
    true
)

local followToggle = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_Follow"),
    "Follow Player",
    eFeatureType.Toggle,
    "",
    function(f)
        info("Follow Player: " .. (f:IsToggled() and "ON" or "OFF"))
    end,
    true
)

local combatToggle = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_Combat"),
    "Combat Mode",
    eFeatureType.Toggle,
    "",
    function(f)
        info("Combat Mode: " .. (f:IsToggled() and "ON" or "OFF"))
    end,
    true
)

autoRespawnToggle = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_AutoRespawn"),
    "Auto Respawn",
    eFeatureType.Toggle,
    "",
    function(f)
        info("Auto Respawn: " .. (f:IsToggled() and "ON" or "OFF"))
    end,
    true
)

local showSelectionButton = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_ShowSelection"),
    "Show Current Selection",
    eFeatureType.Button,
    "",
    function(f)
        info(
            "Model: " .. get_current_model().label ..
            " | Weapon: " .. get_current_weapon().label ..
            " | Formation: " .. get_current_formation().label ..
            " | Behaviour: " .. get_current_behaviour().label
        )
    end,
    true
)

local showCountButton = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_ShowCount"),
    "Show Count",
    eFeatureType.Button,
    "",
    function(f)
        info("Bodyguards actifs: " .. tostring(bodyguard_count()))
    end,
    true
)

local refreshButton = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_Refresh"),
    "Refresh All",
    eFeatureType.Button,
    "",
    function(f)
        refresh_all()
    end,
    true
)

local spawnSelectedButton = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_SpawnSelected"),
    "Spawn Selected Amount",
    eFeatureType.Button,
    "",
    function(f)
        spawn_selected_amount(is_toggled(godModeToggle), is_toggled(showBlipsToggle), is_toggled(followToggle))
    end,
    true
)

local spawn1Button = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_Spawn1"),
    "Spawn 1",
    eFeatureType.Button,
    "",
    function(f)
        create_guard_with_loadout(currentModelIndex, currentWeaponIndex, 2.0, 2.0, 1.0, is_toggled(godModeToggle), is_toggled(showBlipsToggle))
        order_guards_by_behaviour(is_toggled(followToggle))
    end,
    true
)

local spawn5Button = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_Spawn5"),
    "Spawn 5",
    eFeatureType.Button,
    "",
    function(f)
        local old = spawnAmount
        spawnAmount = 5
        spawn_selected_amount(is_toggled(godModeToggle), is_toggled(showBlipsToggle), is_toggled(followToggle))
        spawnAmount = old
    end,
    true
)

local spawn10Button = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_Spawn10"),
    "Spawn 10",
    eFeatureType.Button,
    "",
    function(f)
        local old = spawnAmount
        spawnAmount = 10
        spawn_selected_amount(is_toggled(godModeToggle), is_toggled(showBlipsToggle), is_toggled(followToggle))
        spawnAmount = old
    end,
    true
)

local seatVehicleButton = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_SeatVehicle"),
    "Seat In My Vehicle",
    eFeatureType.Button,
    "",
    function(f)
        seat_in_my_vehicle()
    end,
    true
)

local exitVehicleButton = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_ExitVehicle"),
    "Exit Vehicle",
    eFeatureType.Button,
    "",
    function(f)
        exit_vehicle()
    end,
    true
)

local tpVehicleButton = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_TPVehicle"),
    "Teleport To Vehicle",
    eFeatureType.Button,
    "",
    function(f)
        teleport_to_vehicle()
    end,
    true
)

local tpMeButton = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_TPMe"),
    "Teleport To Me",
    eFeatureType.Button,
    "",
    function(f)
        teleport_to_me()
    end,
    true
)

local applyBehaviourButton = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_ApplyBehaviour"),
    "Apply Behaviour",
    eFeatureType.Button,
    "",
    function(f)
        order_guards_by_behaviour(is_toggled(followToggle))
        info("Behaviour appliqué: " .. get_current_behaviour().label)
    end,
    true
)

local deleteDeadButton = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_DeleteDead"),
    "Delete Dead Only",
    eFeatureType.Button,
    "",
    function(f)
        delete_dead_only()
    end,
    true
)

local deleteAllButton = FeatureMgr.AddFeature(
    Utils.Joaat("BGV12_DeleteAll"),
    "Delete All",
    eFeatureType.Button,
    "",
    function(f)
        delete_all()
    end,
    true
)

------------------------------------------------
-- FEATURE SETUP
------------------------------------------------

if modelCombo then
    safe(function() modelCombo:SetList(MODEL_LABELS) end)
    safe(function() modelCombo:SetListIndex(currentModelIndex - 1) end)
end

if weaponCombo then
    safe(function() weaponCombo:SetList(WEAPON_LABELS) end)
    safe(function() weaponCombo:SetListIndex(currentWeaponIndex - 1) end)
end

if formationCombo then
    safe(function() formationCombo:SetList(FORMATION_LABELS) end)
    safe(function() formationCombo:SetListIndex(currentFormationIndex - 1) end)
end

if behaviourCombo then
    safe(function() behaviourCombo:SetList(BEHAVIOUR_LABELS) end)
    safe(function() behaviourCombo:SetListIndex(currentBehaviourIndex - 1) end)
end

if amountSlider then
    safe(function() amountSlider:SetLimitValues(1, 20) end)
    safe(function() amountSlider:SetStepSize(1) end)
    safe(function() amountSlider:SetFormat("%d") end)
    safe(function() amountSlider:SetIntValue(spawnAmount) end)
end

if accuracySlider then
    safe(function() accuracySlider:SetLimitValues(1, 100) end)
    safe(function() accuracySlider:SetStepSize(1) end)
    safe(function() accuracySlider:SetFormat("%d") end)
    safe(function() accuracySlider:SetIntValue(accuracyValue) end)
end

if armourSlider then
    safe(function() armourSlider:SetLimitValues(0, 100) end)
    safe(function() armourSlider:SetStepSize(5) end)
    safe(function() armourSlider:SetFormat("%d") end)
    safe(function() armourSlider:SetIntValue(armourValue) end)
end

if distanceSlider then
    safe(function() distanceSlider:SetLimitValues(1, 15) end)
    safe(function() distanceSlider:SetStepSize(1) end)
    safe(function() distanceSlider:SetFormat("%d") end)
    safe(function() distanceSlider:SetIntValue(followDistance) end)
end

------------------------------------------------
-- AUTO RESPAWN LOOP
------------------------------------------------

if EventMgr and eLuaEvent and eLuaEvent.GUI_FRAME then
    EventMgr.RegisterHandler(eLuaEvent.GUI_FRAME, function()
        auto_respawn_tick(is_toggled(godModeToggle), is_toggled(showBlipsToggle), is_toggled(followToggle))
    end)
end

------------------------------------------------
-- MENU
------------------------------------------------

ClickGUI.AddTab("Bodyguard Menu", function()

    if ClickGUI.BeginCustomChildWindow("Dashboard") then
        ClickGUI.RenderFeature(showSelectionButton)
        ClickGUI.RenderFeature(showCountButton)
        ClickGUI.RenderFeature(refreshButton)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Identity") then
        ClickGUI.RenderFeature(modelCombo)
        ClickGUI.RenderFeature(weaponCombo)
        ClickGUI.RenderFeature(behaviourCombo)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("AI & Formation") then
        ClickGUI.RenderFeature(formationCombo)
        ClickGUI.RenderFeature(followToggle)
        ClickGUI.RenderFeature(combatToggle)
        ClickGUI.RenderFeature(autoRespawnToggle)
        ClickGUI.RenderFeature(distanceSlider)
        ClickGUI.RenderFeature(applyBehaviourButton)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Stats & Live Options") then
        ClickGUI.RenderFeature(accuracySlider)
        ClickGUI.RenderFeature(armourSlider)
        ClickGUI.RenderFeature(godModeToggle)
        ClickGUI.RenderFeature(showBlipsToggle)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Deployment") then
        ClickGUI.RenderFeature(amountSlider)
        ClickGUI.RenderFeature(spawnSelectedButton)
        ClickGUI.RenderFeature(spawn1Button)
        ClickGUI.RenderFeature(spawn5Button)
        ClickGUI.RenderFeature(spawn10Button)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Vehicle Support") then
        ClickGUI.RenderFeature(seatVehicleButton)
        ClickGUI.RenderFeature(exitVehicleButton)
        ClickGUI.RenderFeature(tpVehicleButton)
        ClickGUI.RenderFeature(tpMeButton)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Cleanup") then
        ClickGUI.RenderFeature(deleteDeadButton)
        ClickGUI.RenderFeature(deleteAllButton)
        ClickGUI.EndCustomChildWindow()
    end
end)

info("Bodyguard V12 Loaded")
info("Model: " .. get_current_model().label)
info("Weapon: " .. get_current_weapon().label)
info("Formation: " .. get_current_formation().label)
info("Behaviour: " .. get_current_behaviour().label)
info("Spawn Amount: " .. tostring(spawnAmount))

-- 12. Création du slider pour le nombre de gardes
FeatureMgr.AddFeature(HASH_BG_SLIDER, "Number of Bodyguards", eFeatureType.Slider, "", function(sliderValue)
    maxBodyguards = math.floor(sliderValue)
    info("Nombre de gardes défini à : " .. maxBodyguards)
end, true)

-- 13. Définir la formation de garde
FeatureMgr.AddFeature(HASH_BG_FORMATION_COMBO, "Formation", eFeatureType.Combo, "", function(f)
    local idx = f:GetListIndex()
    formationIndex = idx + 1
    info("Formation de garde choisie : Formation " .. formationIndex)
end, true)

-- 14. Ajouter la section "Formation" et "AI"
FeatureMgr.AddFeature(HASH_BG_TACTICAL, "Formation", eFeatureType.Button, "", function()
    -- Activation de la formation
    info("Formation activée pour les gardes")
end, true)

-- 15. Ajouter une option de suivi
FeatureMgr.AddFeature(HASH_BG_AUTO_RESPAWN, "Auto Respawn", eFeatureType.Toggle, "", function()
    info("Auto respawn activé pour les gardes")
end, true)
