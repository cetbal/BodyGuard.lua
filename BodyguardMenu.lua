dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

local bodyguards = {}

-- =========================
-- CONFIG
-- =========================

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

local FORMATION_OPTIONS = {
    { label = "Line" },
    { label = "Circle" },
    { label = "Diamond" },
    { label = "Around" }
}

local BEHAVIOUR_OPTIONS = {
    { label = "Passive" },
    { label = "Protect" },
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

local BLIP_COLOR = 5
local BLIP_SPRITE = 1
local BLIP_SCALE = 0.85

local RESPAWN_DELAY_MS = 1500

-- =========================
-- HASHES
-- =========================

local HASH_MODEL_COMBO        = Utils.Joaat("BG_ModelCombo")
local HASH_WEAPON_COMBO       = Utils.Joaat("BG_WeaponCombo")
local HASH_FORMATION_COMBO    = Utils.Joaat("BG_FormationCombo")
local HASH_BEHAVIOUR_COMBO    = Utils.Joaat("BG_BehaviourCombo")

local HASH_AMOUNT_SLIDER      = Utils.Joaat("BG_AmountSlider")
local HASH_ACCURACY_SLIDER    = Utils.Joaat("BG_AccuracySlider")
local HASH_ARMOUR_SLIDER      = Utils.Joaat("BG_ArmourSlider")
local HASH_DISTANCE_SLIDER    = Utils.Joaat("BG_DistanceSlider")

local HASH_GODMODE            = Utils.Joaat("BG_GodMode")
local HASH_SHOWBLIPS          = Utils.Joaat("BG_ShowBlips")
local HASH_FOLLOWPLAYER       = Utils.Joaat("BG_FollowPlayer")
local HASH_COMBATMODE         = Utils.Joaat("BG_CombatMode")
local HASH_AUTORESPAWN        = Utils.Joaat("BG_AutoRespawn")

local HASH_SHOW_SELECTION     = Utils.Joaat("BG_ShowSelection")
local HASH_SHOW_COUNT         = Utils.Joaat("BG_ShowCount")
local HASH_REFRESH_ALL        = Utils.Joaat("BG_RefreshAll")

local HASH_SPAWN_SELECTED     = Utils.Joaat("BG_SpawnSelected")
local HASH_SPAWN1             = Utils.Joaat("BG_Spawn1")
local HASH_SPAWN5             = Utils.Joaat("BG_Spawn5")
local HASH_SPAWN10            = Utils.Joaat("BG_Spawn10")

local HASH_SEAT_IN_VEHICLE    = Utils.Joaat("BG_SeatInVehicle")
local HASH_EXIT_VEHICLE       = Utils.Joaat("BG_ExitVehicle")
local HASH_TP_TO_VEHICLE      = Utils.Joaat("BG_TPToVehicle")
local HASH_TP_TO_ME           = Utils.Joaat("BG_TPToMe")

local HASH_DELETE_DEAD        = Utils.Joaat("BG_DeleteDeadOnly")
local HASH_DELETE_ALL         = Utils.Joaat("BG_DeleteAll")

-- =========================
-- HELPERS
-- =========================

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

local function get_feature(hash)
    return FeatureMgr.GetFeature(hash)
end

local function is_toggled(hash)
    local f = get_feature(hash)
    return f ~= nil and f:IsToggled()
end

local function get_list_index(hash, defaultIndex)
    local f = get_feature(hash)
    if not f then
        return defaultIndex
    end

    local idx = safe(function() return f:GetListIndex() end)
    if idx == nil then
        return defaultIndex
    end

    idx = idx + 1
    if idx < 1 then idx = 1 end
    return idx
end

local function get_int_value(hash, defaultValue)
    local f = get_feature(hash)
    if not f then
        return defaultValue
    end

    local value = safe(function() return f:GetIntValue() end)
    if value == nil then
        return defaultValue
    end

    return value
end

local function get_current_model_info()
    local idx = get_list_index(HASH_MODEL_COMBO, 1)
    return MODEL_OPTIONS[idx] or MODEL_OPTIONS[1], idx
end

local function get_current_weapon_info()
    local idx = get_list_index(HASH_WEAPON_COMBO, 1)
    return WEAPON_OPTIONS[idx] or WEAPON_OPTIONS[1], idx
end

local function get_current_formation_info()
    local idx = get_list_index(HASH_FORMATION_COMBO, 1)
    return FORMATION_OPTIONS[idx] or FORMATION_OPTIONS[1], idx
end

local function get_current_behaviour_info()
    local idx = get_list_index(HASH_BEHAVIOUR_COMBO, 1)
    return BEHAVIOUR_OPTIONS[idx] or BEHAVIOUR_OPTIONS[1], idx
end

local function get_spawn_amount()
    local value = get_int_value(HASH_AMOUNT_SLIDER, 3)
    if value < 1 then value = 1 end
    if value > 20 then value = 20 end
    return value
end

local function get_accuracy_value()
    local value = get_int_value(HASH_ACCURACY_SLIDER, 75)
    if value < 1 then value = 1 end
    if value > 100 then value = 100 end
    return value
end

local function get_armour_value()
    local value = get_int_value(HASH_ARMOUR_SLIDER, 100)
    if value < 0 then value = 0 end
    if value > 100 then value = 100 end
    return value
end

local function get_follow_distance()
    local value = get_int_value(HASH_DISTANCE_SLIDER, 3)
    if value < 1 then value = 1 end
    if value > 15 then value = 15 end
    return value
end

local function current_time_ms()
    return safe(function() return MISC.GET_GAME_TIMER() end) or 0
end

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

    if veh == nil then
        veh = 0
    end

    return veh
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

local function apply_blip_state(entry)
    if not entry or not entry.blip or entry.blip == 0 then
        return
    end

    if is_toggled(HASH_SHOWBLIPS) then
        safe(function() HUD.SET_BLIP_DISPLAY(entry.blip, 2) end)
        safe(function() HUD.SET_BLIP_ALPHA(entry.blip, 255) end)
    else
        safe(function() HUD.SET_BLIP_DISPLAY(entry.blip, 0) end)
        safe(function() HUD.SET_BLIP_ALPHA(entry.blip, 0) end)
    end
end

local function bodyguard_exists(entry)
    if not entry or not entry.ped or entry.ped == 0 then
        return false
    end

    return safe(function()
        return ENTITY.DOES_ENTITY_EXIST(entry.ped)
    end) or false
end

local function bodyguard_dead(entry)
    if not bodyguard_exists(entry) then
        return true
    end

    local health = safe(function()
        return ENTITY.GET_ENTITY_HEALTH(entry.ped)
    end)

    if health == nil then
        return true
    end

    return health <= 0
end

local function cleanup_bodyguards()
    local cleaned = {}

    for _, entry in pairs(bodyguards) do
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

local function get_seat_list(vehicle)
    local seats = {}

    local maxPassengers = safe(function()
        return VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(vehicle)
    end)

    if maxPassengers == nil then
        maxPassengers = 3
    end

    for seat = -1, maxPassengers do
        local occupant = safe(function()
            return VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, seat, false)
        end)

        if occupant == nil or occupant == 0 then
            table.insert(seats, seat)
        end
    end

    return seats
end

local function apply_behaviour(ped)
    local behaviourInfo = get_current_behaviour_info()

    if not ped or ped == 0 then
        return
    end

    if behaviourInfo.label == "Passive" then
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 0) end)
        safe(function() PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false) end)
    elseif behaviourInfo.label == "Protect" then
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 1) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 1) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 1) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true) end)
    else
        safe(function() PED.SET_PED_COMBAT_ABILITY(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(ped, 2) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true) end)
        safe(function() PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, true) end)
        safe(function() PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false) end)
    end
end

local function equip_bodyguard(entry)
    if not entry or not entry.ped or entry.ped == 0 then
        return
    end

    local weaponInfo = WEAPON_OPTIONS[entry.weaponIndex] or WEAPON_OPTIONS[1]
    local weaponHash = MISC.GET_HASH_KEY(weaponInfo.weapon)

    WEAPON.GIVE_WEAPON_TO_PED(entry.ped, weaponHash, weaponInfo.ammo, false, true)

    safe(function() PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(entry.ped, true) end)
    safe(function() PED.SET_PED_NEVER_LEAVES_GROUP(entry.ped, true) end)
    safe(function() PED.SET_PED_CAN_SWITCH_WEAPON(entry.ped, true) end)
    safe(function() PED.SET_PED_ACCURACY(entry.ped, get_accuracy_value()) end)
    safe(function() PED.SET_PED_ARMOUR(entry.ped, get_armour_value()) end)

    if is_toggled(HASH_GODMODE) then
        ENTITY.SET_ENTITY_INVINCIBLE(entry.ped, true)
    else
        ENTITY.SET_ENTITY_INVINCIBLE(entry.ped, false)
    end

    if is_toggled(HASH_COMBATMODE) then
        apply_behaviour(entry.ped)
    else
        safe(function() PED.SET_PED_COMBAT_ABILITY(entry.ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_RANGE(entry.ped, 0) end)
        safe(function() PED.SET_PED_COMBAT_MOVEMENT(entry.ped, 0) end)
    end
end

local function formation_offset(index, total)
    local formationInfo = get_current_formation_info()
    local dist = get_follow_distance()

    if formationInfo.label == "Line" then
        return (index - 1) * 1.5, -(dist + 1.0), 0.0
    elseif formationInfo.label == "Circle" then
        local angle = ((index - 1) / math.max(total, 1)) * 6.28318
        return math.cos(angle) * dist, math.sin(angle) * dist, 0.0
    elseif formationInfo.label == "Diamond" then
        local map = {
            { 0.0, -dist, 0.0 },
            { dist, 0.0, 0.0 },
            { 0.0, dist, 0.0 },
            { -dist, 0.0, 0.0 }
        }
        local item = map[((index - 1) % #map) + 1]
        return item[1], item[2], item[3]
    else
        if index % 2 == 0 then
            return dist + (index * 0.2), -(dist * 0.7) - (index * 0.1), 0.0
        else
            return -(dist + (index * 0.2)), -(dist * 0.7) - (index * 0.1), 0.0
        end
    end
end

local function apply_follow_one(entry, index, total)
    if not entry or not entry.ped or entry.ped == 0 then
        return
    end

    if not is_toggled(HASH_FOLLOWPLAYER) then
        return
    end

    local ped = player_ped()
    if ped == 0 then
        return
    end

    if safe(function() return PED.IS_PED_IN_ANY_VEHICLE(entry.ped, false) end) then
        return
    end

    local offX, offY, offZ = formation_offset(index, total)

    safe(function()
        TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
            entry.ped,
            ped,
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

local function apply_follow_all()
    cleanup_bodyguards()

    for i, entry in ipairs(bodyguards) do
        apply_follow_one(entry, i, #bodyguards)
    end
end

local function refresh_all()
    cleanup_bodyguards()

    for i, entry in ipairs(bodyguards) do
        if bodyguard_exists(entry) then
            equip_bodyguard(entry)
            apply_blip_state(entry)
            apply_follow_one(entry, i, #bodyguards)
        end
    end

    info("Refresh terminé | Actifs: " .. tostring(bodyguard_count()))
end

local function create_bodyguard_with_loadout(modelIndex, weaponIndex, offsetX, offsetY, offsetZ)
    local coords = player_coords()
    if not coords then
        warn("Impossible de récupérer la position du joueur")
        return nil
    end

    local modelInfo = MODEL_OPTIONS[modelIndex] or MODEL_OPTIONS[1]
    local weaponInfo = WEAPON_OPTIONS[weaponIndex] or WEAPON_OPTIONS[1]
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
        false,
        false
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
        lastDeathTime = 0
    }

    table.insert(bodyguards, entry)
    equip_bodyguard(entry)
    apply_blip_state(entry)

    info("Spawn: " .. modelInfo.label .. " | " .. weaponInfo.label)
    return entry
end

local function create_bodyguard(offsetX, offsetY, offsetZ)
    local _, modelIndex = get_current_model_info()
    local _, weaponIndex = get_current_weapon_info()
    return create_bodyguard_with_loadout(modelIndex, weaponIndex, offsetX, offsetY, offsetZ)
end

local function spawn_amount_custom(amount)
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
        create_bodyguard(o[1], o[2], o[3])
    end

    apply_follow_all()
    info(tostring(amount) .. " bodyguards spawn")
end

local function teleport_all_to_me()
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

    apply_follow_all()
    info("Téléportation sur le joueur terminée")
end

local function seat_all_in_vehicle()
    local vehicle = player_vehicle()
    if vehicle == 0 then
        warn("Tu n'es pas dans un véhicule")
        return
    end

    cleanup_bodyguards()

    local seats = get_seat_list(vehicle)
    local used = 1

    for _, entry in ipairs(bodyguards) do
        if bodyguard_exists(entry) then
            local seat = seats[used]
            if seat == nil then
                break
            end

            safe(function()
                PED.SET_PED_INTO_VEHICLE(entry.ped, vehicle, seat)
            end)

            used = used + 1
        end
    end

    info("Placement des gardes dans le véhicule terminé")
end

local function exit_all_vehicle()
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

local function teleport_all_to_vehicle()
    local vehicle = player_vehicle()
    if vehicle == 0 then
        warn("Tu n'es pas dans un véhicule")
        return
    end

    local coords = safe(function()
        return ENTITY.GET_ENTITY_COORDS(vehicle, true)
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

local function kill_bodyguard(entry)
    if not entry or not entry.ped or entry.ped == 0 then
        return false
    end

    local ok = safe(function()
        if ENTITY.DOES_ENTITY_EXIST(entry.ped) then
            ENTITY.SET_ENTITY_INVINCIBLE(entry.ped, false)
            ENTITY.SET_ENTITY_HEALTH(entry.ped, 0, 0, 0)
        end
        return true
    end)

    if entry.blip then
        hide_blip(entry.blip)
    end

    return ok
end

local function delete_all()
    cleanup_bodyguards()

    for i = 1, #bodyguards do
        kill_bodyguard(bodyguards[i])
    end

    bodyguards = {}
    info("Delete All terminé | Actifs: 0")
end

local function delete_dead_only()
    cleanup_bodyguards()

    local cleaned = {}

    for _, entry in ipairs(bodyguards) do
        if bodyguard_dead(entry) then
            kill_bodyguard(entry)
        else
            table.insert(cleaned, entry)
        end
    end

    bodyguards = cleaned
    info("Delete Dead Only terminé | Actifs: " .. tostring(bodyguard_count()))
end

local function auto_respawn_tick()
    if not is_toggled(HASH_AUTORESPAWN) then
        return
    end

    local now = current_time_ms()
    local respawnList = {}

    for _, entry in ipairs(bodyguards) do
        if entry and entry.ped and entry.ped ~= 0 then
            local exists = bodyguard_exists(entry)
            local dead = bodyguard_dead(entry)

            if exists and dead then
                if entry.lastDeathTime == nil or entry.lastDeathTime == 0 then
                    entry.lastDeathTime = now
                end

                if now - entry.lastDeathTime >= RESPAWN_DELAY_MS then
                    table.insert(respawnList, {
                        modelIndex = entry.modelIndex,
                        weaponIndex = entry.weaponIndex
                    })
                    if entry.blip then
                        hide_blip(entry.blip)
                    end
                    entry.ped = 0
                end
            end
        end
    end

    cleanup_bodyguards()

    for _, item in ipairs(respawnList) do
        create_bodyguard_with_loadout(item.modelIndex, item.weaponIndex, 2.0, 2.0, 1.0)
    end

    if #respawnList > 0 then
        apply_follow_all()
    end
end

-- =========================
-- FEATURES
-- =========================

FeatureMgr.AddFeature(HASH_MODEL_COMBO, "Agent Model", eFeatureType.Combo, "Choisir le modèle du garde", function(f)
    local infoModel = get_current_model_info()
    info("Model: " .. infoModel.label)
end, true)

FeatureMgr.AddFeature(HASH_WEAPON_COMBO, "Primary Weapon", eFeatureType.Combo, "Choisir l'arme du garde", function(f)
    local infoWeapon = get_current_weapon_info()
    info("Weapon: " .. infoWeapon.label)
end, true)

FeatureMgr.AddFeature(HASH_FORMATION_COMBO, "Formation", eFeatureType.Combo, "Choisir la formation", function(f)
    local infoFormation = get_current_formation_info()
    info("Formation: " .. infoFormation.label)
    apply_follow_all()
end, true)

FeatureMgr.AddFeature(HASH_BEHAVIOUR_COMBO, "Behaviour", eFeatureType.Combo, "Choisir le comportement", function(f)
    local infoBehaviour = get_current_behaviour_info()
    info("Behaviour: " .. infoBehaviour.label)
    refresh_all()
end, true)

FeatureMgr.AddFeature(HASH_AMOUNT_SLIDER, "Spawn Amount", eFeatureType.SliderInt, "Nombre de gardes", function(f)
    info("Spawn Amount: " .. tostring(get_spawn_amount()))
end, true)

FeatureMgr.AddFeature(HASH_ACCURACY_SLIDER, "Accuracy", eFeatureType.SliderInt, "Précision des gardes", function(f)
    refresh_all()
    info("Accuracy: " .. tostring(get_accuracy_value()))
end, true)

FeatureMgr.AddFeature(HASH_ARMOUR_SLIDER, "Armour", eFeatureType.SliderInt, "Armure des gardes", function(f)
    refresh_all()
    info("Armour: " .. tostring(get_armour_value()))
end, true)

FeatureMgr.AddFeature(HASH_DISTANCE_SLIDER, "Follow Distance", eFeatureType.SliderInt, "Distance de suivi", function(f)
    apply_follow_all()
    info("Follow Distance: " .. tostring(get_follow_distance()))
end, true)

FeatureMgr.AddFeature(HASH_GODMODE, "God Mode", eFeatureType.Toggle, "Invincibilité", function(f)
    refresh_all()
end, true)

FeatureMgr.AddFeature(HASH_SHOWBLIPS, "Show Blips", eFeatureType.Toggle, "Blips carte", function(f)
    refresh_all()
end, true)

FeatureMgr.AddFeature(HASH_FOLLOWPLAYER, "Follow Player", eFeatureType.Toggle, "Suivre le joueur", function(f)
    apply_follow_all()
end, true)

FeatureMgr.AddFeature(HASH_COMBATMODE, "Combat Mode", eFeatureType.Toggle, "Mode combat", function(f)
    refresh_all()
end, true)

FeatureMgr.AddFeature(HASH_AUTORESPAWN, "Auto Respawn", eFeatureType.Toggle, "Respawn auto des gardes", function(f)
    if f:IsToggled() then
        info("Auto Respawn activé")
    else
        info("Auto Respawn désactivé")
    end
end, true)

FeatureMgr.AddFeature(HASH_SHOW_SELECTION, "Show Current Selection", eFeatureType.Button, "", function(f)
    local m = get_current_model_info()
    local w = get_current_weapon_info()
    local fr = get_current_formation_info()
    local bh = get_current_behaviour_info()
    info("Model: " .. m.label .. " | Weapon: " .. w.label .. " | Formation: " .. fr.label .. " | Behaviour: " .. bh.label)
end, true)

FeatureMgr.AddFeature(HASH_SHOW_COUNT, "Show Count", eFeatureType.Button, "", function(f)
    info("Bodyguards actifs: " .. tostring(bodyguard_count()))
end, true)

FeatureMgr.AddFeature(HASH_REFRESH_ALL, "Refresh All", eFeatureType.Button, "", function(f)
    refresh_all()
end, true)

FeatureMgr.AddFeature(HASH_SPAWN_SELECTED, "Spawn Selected Amount", eFeatureType.Button, "", function(f)
    spawn_amount_custom(get_spawn_amount())
end, true)

FeatureMgr.AddFeature(HASH_SPAWN1, "Spawn 1", eFeatureType.Button, "", function(f)
    local entry = create_bodyguard(2.0, 2.0, 1.0)
    if entry then
        apply_follow_all()
    end
end, true)

FeatureMgr.AddFeature(HASH_SPAWN5, "Spawn 5", eFeatureType.Button, "", function(f)
    spawn_amount_custom(5)
end, true)

FeatureMgr.AddFeature(HASH_SPAWN10, "Spawn 10", eFeatureType.Button, "", function(f)
    spawn_amount_custom(10)
end, true)

FeatureMgr.AddFeature(HASH_SEAT_IN_VEHICLE, "Seat In My Vehicle", eFeatureType.Button, "", function(f)
    seat_all_in_vehicle()
end, true)

FeatureMgr.AddFeature(HASH_EXIT_VEHICLE, "Exit Vehicle", eFeatureType.Button, "", function(f)
    exit_all_vehicle()
end, true)

FeatureMgr.AddFeature(HASH_TP_TO_VEHICLE, "Teleport To Vehicle", eFeatureType.Button, "", function(f)
    teleport_all_to_vehicle()
end, true)

FeatureMgr.AddFeature(HASH_TP_TO_ME, "Teleport To Me", eFeatureType.Button, "", function(f)
    teleport_all_to_me()
end, true)

FeatureMgr.AddFeature(HASH_DELETE_DEAD, "Delete Dead Only", eFeatureType.Button, "", function(f)
    delete_dead_only()
end, true)

FeatureMgr.AddFeature(HASH_DELETE_ALL, "Delete All", eFeatureType.Button, "", function(f)
    delete_all()
end, true)

-- =========================
-- CONFIGURE UI
-- =========================

local modelCombo = get_feature(HASH_MODEL_COMBO)
if modelCombo then
    modelCombo:SetList(MODEL_LABELS)
    modelCombo:SetListIndex(0)
end

local weaponCombo = get_feature(HASH_WEAPON_COMBO)
if weaponCombo then
    weaponCombo:SetList(WEAPON_LABELS)
    weaponCombo:SetListIndex(0)
end

local formationCombo = get_feature(HASH_FORMATION_COMBO)
if formationCombo then
    formationCombo:SetList(FORMATION_LABELS)
    formationCombo:SetListIndex(0)
end

local behaviourCombo = get_feature(HASH_BEHAVIOUR_COMBO)
if behaviourCombo then
    behaviourCombo:SetList(BEHAVIOUR_LABELS)
    behaviourCombo:SetListIndex(1)
end

local amountSlider = get_feature(HASH_AMOUNT_SLIDER)
if amountSlider then
    amountSlider:SetLimitValues(1, 20)
    amountSlider:SetStepSize(1)
    amountSlider:SetFormat("%d")
    amountSlider:SetIntValue(3)
end

local accuracySlider = get_feature(HASH_ACCURACY_SLIDER)
if accuracySlider then
    accuracySlider:SetLimitValues(1, 100)
    accuracySlider:SetStepSize(1)
    accuracySlider:SetFormat("%d")
    accuracySlider:SetIntValue(75)
end

local armourSlider = get_feature(HASH_ARMOUR_SLIDER)
if armourSlider then
    armourSlider:SetLimitValues(0, 100)
    armourSlider:SetStepSize(5)
    armourSlider:SetFormat("%d")
    armourSlider:SetIntValue(100)
end

local distanceSlider = get_feature(HASH_DISTANCE_SLIDER)
if distanceSlider then
    distanceSlider:SetLimitValues(1, 15)
    distanceSlider:SetStepSize(1)
    distanceSlider:SetFormat("%d")
    distanceSlider:SetIntValue(3)
end

-- =========================
-- AUTO RESPAWN LOOP
-- =========================

if EventMgr and eLuaEvent and eLuaEvent.GUI_FRAME then
    EventMgr.RegisterHandler(eLuaEvent.GUI_FRAME, function()
        auto_respawn_tick()
    end)
end

-- =========================
-- MENU
-- =========================

ClickGUI.AddTab("Bodyguard Menu", function()

    if ClickGUI.BeginCustomChildWindow("Dashboard") then
        ClickGUI.RenderFeature(HASH_SHOW_SELECTION)
        ClickGUI.RenderFeature(HASH_SHOW_COUNT)
        ClickGUI.RenderFeature(HASH_REFRESH_ALL)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Identity") then
        ClickGUI.RenderFeature(HASH_MODEL_COMBO)
        ClickGUI.RenderFeature(HASH_WEAPON_COMBO)
        ClickGUI.RenderFeature(HASH_BEHAVIOUR_COMBO)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("AI & Formation") then
        ClickGUI.RenderFeature(HASH_FORMATION_COMBO)
        ClickGUI.RenderFeature(HASH_FOLLOWPLAYER)
        ClickGUI.RenderFeature(HASH_COMBATMODE)
        ClickGUI.RenderFeature(HASH_AUTORESPAWN)
        ClickGUI.RenderFeature(HASH_DISTANCE_SLIDER)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Stats & Live Options") then
        ClickGUI.RenderFeature(HASH_ACCURACY_SLIDER)
        ClickGUI.RenderFeature(HASH_ARMOUR_SLIDER)
        ClickGUI.RenderFeature(HASH_GODMODE)
        ClickGUI.RenderFeature(HASH_SHOWBLIPS)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Deployment") then
        ClickGUI.RenderFeature(HASH_AMOUNT_SLIDER)
        ClickGUI.RenderFeature(HASH_SPAWN_SELECTED)
        ClickGUI.RenderFeature(HASH_SPAWN1)
        ClickGUI.RenderFeature(HASH_SPAWN5)
        ClickGUI.RenderFeature(HASH_SPAWN10)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Vehicle Support") then
        ClickGUI.RenderFeature(HASH_SEAT_IN_VEHICLE)
        ClickGUI.RenderFeature(HASH_EXIT_VEHICLE)
        ClickGUI.RenderFeature(HASH_TP_TO_VEHICLE)
        ClickGUI.RenderFeature(HASH_TP_TO_ME)
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Cleanup") then
        ClickGUI.RenderFeature(HASH_DELETE_DEAD)
        ClickGUI.RenderFeature(HASH_DELETE_ALL)
        ClickGUI.EndCustomChildWindow()
    end
end)

info("Menu Bodyguard V9 chargé")
info("Model: " .. get_current_model_info().label)
info("Weapon: " .. get_current_weapon_info().label)
info("Formation: " .. get_current_formation_info().label)
info("Behaviour: " .. get_current_behaviour_info().label)
info("Spawn Amount: " .. tostring(get_spawn_amount()))
