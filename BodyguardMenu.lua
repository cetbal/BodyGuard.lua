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
    { name = "WEAPON_PISTOL", label = "Pistol", ammo = 500 },
    { name = "WEAPON_COMBATPISTOL", label = "Combat Pistol", ammo = 500 },
    { name = "WEAPON_SMG", label = "SMG", ammo = 800 },
    { name = "WEAPON_CARBINERIFLE", label = "Carbine Rifle", ammo = 1200 },
    { name = "WEAPON_PUMPSHOTGUN", label = "Pump Shotgun", ammo = 300 }
}

local FORMATIONS = {
    { label = "Line" },
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

local function toast(text)
    Logger.Log(eLogColor.LIGHTGREEN, "Bodyguard Menu", text)
    GUI.AddToast("Bodyguard Menu", text, 3000, eToastPos.TOP_RIGHT)
end

local function warn(text)
    Logger.Log(eLogColor.LIGHTRED, "Bodyguard Menu", text)
    GUI.AddToast("Bodyguard Menu", text, 4000, eToastPos.TOP_RIGHT)
end

local function get_feature(hash)
    return FeatureMgr.GetFeature(hash)
end

local function is_feature_toggled(hash)
    local f = get_feature(hash)
    return f ~= nil and f:IsToggled()
end

local function get_current_model()
    return MODELS[currentModelIndex]
end

local function get_current_weapon()
    return WEAPONS[currentWeaponIndex]
end

local function get_current_formation()
    return FORMATIONS[currentFormationIndex]
end

local function load_model(model)
    STREAMING.REQUEST_MODEL(model)

    local i = 0
    while not STREAMING.HAS_MODEL_LOADED(model) and i < 300 do
        SYSTEM.WAIT(0)
        i = i + 1
    end

    return STREAMING.HAS_MODEL_LOADED(model)
end

local function create_blip(ped)
    local blip = HUD.ADD_BLIP_FOR_ENTITY(ped)

    if blip ~= 0 then
        HUD.SET_BLIP_AS_FRIENDLY(blip, true)
        HUD.SET_BLIP_COLOUR(blip, BLIP_COLOR)
        HUD.SET_BLIP_SPRITE(blip, BLIP_SPRITE)
        HUD.SET_BLIP_SCALE(blip, BLIP_SCALE)
        HUD.SET_BLIP_AS_SHORT_RANGE(blip, false)
        HUD.SET_BLIP_DISPLAY(blip, 2)
        HUD.SET_BLIP_HIGH_DETAIL(blip, true)
    end

    return blip
end

local function hide_blip(blip)
    if blip == nil or blip == 0 then
        return
    end

    pcall(function()
        HUD.SET_BLIP_DISPLAY(blip, 0)
        HUD.SET_BLIP_ALPHA(blip, 0)
    end)
end

local function cleanup_bodyguards()
    local cleaned = {}

    for _, entry in pairs(bodyguards) do
        if entry and entry.ped and entry.ped ~= 0 then
            local ok, exists = pcall(function()
                return ENTITY.DOES_ENTITY_EXIST(entry.ped)
            end)

            if ok and exists then
                table.insert(cleaned, entry)
            else
                if entry.blip then
                    hide_blip(entry.blip)
                end
            end
        end
    end

    bodyguards = cleaned
end

local function get_count()
    cleanup_bodyguards()
    return #bodyguards
end

local function apply_blip_visibility(entry)
    if not entry or not entry.blip or entry.blip == 0 then
        return
    end

    local enabled = is_feature_toggled(Utils.Joaat("BG_ShowBlips"))

    pcall(function()
        if enabled then
            HUD.SET_BLIP_DISPLAY(entry.blip, 2)
            HUD.SET_BLIP_ALPHA(entry.blip, 255)
        else
            HUD.SET_BLIP_DISPLAY(entry.blip, 0)
            HUD.SET_BLIP_ALPHA(entry.blip, 0)
        end
    end)
end

local function equip_bodyguard(ped)
    local weaponInfo = get_current_weapon()
    local weaponHash = MISC.GET_HASH_KEY(weaponInfo.name)

    WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, weaponInfo.ammo, false, true)
    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
    PED.SET_PED_NEVER_LEAVES_GROUP(ped, true)
    PED.SET_PED_CAN_SWITCH_WEAPON(ped, true)
    PED.SET_PED_ACCURACY(ped, 70)
    PED.SET_PED_ARMOUR(ped, 100)

    if is_feature_toggled(Utils.Joaat("BG_GodMode")) then
        ENTITY.SET_ENTITY_INVINCIBLE(ped, true)
    else
        ENTITY.SET_ENTITY_INVINCIBLE(ped, false)
    end
end

local function follow_single(entry, index, total)
    if not entry or not entry.ped or entry.ped == 0 then
        return
    end

    if not is_feature_toggled(Utils.Joaat("BG_FollowPlayer")) then
        return
    end

    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed == 0 then
        return
    end

    local formation = get_current_formation().label
    local offX, offY, offZ = 0.0, -2.0, 0.0

    if formation == "Line" then
        offX = (index - 1) * 1.5
        offY = -2.5
    elseif formation == "Circle" then
        local angle = ((index - 1) / math.max(total, 1)) * 6.28318
        offX = math.cos(angle) * 3.0
        offY = math.sin(angle) * 3.0
    else
        if index % 2 == 0 then
            offX = 2.0 + index * 0.2
        else
            offX = -2.0 - index * 0.2
        end
        offY = -1.5 - (index * 0.15)
    end

    pcall(function()
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

local function apply_follow_to_all()
    cleanup_bodyguards()

    for i, entry in ipairs(bodyguards) do
        follow_single(entry, i, #bodyguards)
    end
end

local function refresh_all()
    cleanup_bodyguards()

    for i, entry in ipairs(bodyguards) do
        if entry and entry.ped and entry.ped ~= 0 then
            pcall(function()
                if ENTITY.DOES_ENTITY_EXIST(entry.ped) then
                    equip_bodyguard(entry.ped)
                    apply_blip_visibility(entry)
                end
            end)

            follow_single(entry, i, #bodyguards)
        end
    end

    toast("Refresh terminé | Actifs: " .. tostring(get_count()))
end

local function create_bodyguard(offsetX, offsetY, offsetZ)
    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed == 0 then
        warn("PLAYER_PED_ID invalide")
        return 0
    end

    local coords = ENTITY.GET_ENTITY_COORDS(playerPed, true)
    local modelInfo = get_current_model()
    local weaponInfo = get_current_weapon()
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

    if not load_model(modelHash) then
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

    equip_bodyguard(ped)

    local entry = {
        ped = ped,
        blip = create_blip(ped)
    }

    table.insert(bodyguards, entry)
    apply_blip_visibility(entry)

    toast("Spawn: " .. modelInfo.label .. " | " .. weaponInfo.label)
    return ped
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
        {  0.0,  3.0, 1.0 }
    }

    for i = 1, amount do
        local o = offsets[i] or { i * 1.2, 1.0, 1.0 }
        create_bodyguard(o[1], o[2], o[3])
    end

    apply_follow_to_all()
    toast(tostring(amount) .. " bodyguards spawn")
end

local function teleport_all()
    local playerPed = PLAYER.PLAYER_PED_ID()
    if playerPed == 0 then
        return
    end

    local coords = ENTITY.GET_ENTITY_COORDS(playerPed, true)
    cleanup_bodyguards()

    for i, entry in ipairs(bodyguards) do
        pcall(function()
            if entry and entry.ped and ENTITY.DOES_ENTITY_EXIST(entry.ped) then
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
            end
        end)
    end

    apply_follow_to_all()
    toast("Téléportation terminée")
end

local function kill_bodyguard(entry)
    if not entry or not entry.ped or entry.ped == 0 then
        return false
    end

    local ped = entry.ped

    local ok = pcall(function()
        if ENTITY.DOES_ENTITY_EXIST(ped) then
            ENTITY.SET_ENTITY_INVINCIBLE(ped, false)
            ENTITY.SET_ENTITY_HEALTH(ped, 0, 0, 0)
        end
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
    toast("Delete All terminé | Actifs: 0")
end

local function delete_dead_only()
    cleanup_bodyguards()

    local cleaned = {}

    for _, entry in ipairs(bodyguards) do
        local keep = true

        if entry and entry.ped and entry.ped ~= 0 then
            local ok, health = pcall(function()
                if ENTITY.DOES_ENTITY_EXIST(entry.ped) then
                    return ENTITY.GET_ENTITY_HEALTH(entry.ped)
                end
                return 0
            end)

            if ok and health <= 0 then
                kill_bodyguard(entry)
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
    toast("Delete Dead Only terminé | Actifs: " .. tostring(get_count()))
end

local function next_model()
    currentModelIndex = currentModelIndex + 1
    if currentModelIndex > #MODELS then
        currentModelIndex = 1
    end
    toast("Model: " .. get_current_model().label)
end

local function previous_model()
    currentModelIndex = currentModelIndex - 1
    if currentModelIndex < 1 then
        currentModelIndex = #MODELS
    end
    toast("Model: " .. get_current_model().label)
end

local function next_weapon()
    currentWeaponIndex = currentWeaponIndex + 1
    if currentWeaponIndex > #WEAPONS then
        currentWeaponIndex = 1
    end
    toast("Weapon: " .. get_current_weapon().label)
end

local function previous_weapon()
    currentWeaponIndex = currentWeaponIndex - 1
    if currentWeaponIndex < 1 then
        currentWeaponIndex = #WEAPONS
    end
    toast("Weapon: " .. get_current_weapon().label)
end

local function next_formation()
    currentFormationIndex = currentFormationIndex + 1
    if currentFormationIndex > #FORMATIONS then
        currentFormationIndex = 1
    end
    toast("Formation: " .. get_current_formation().label)
    apply_follow_to_all()
end

local function previous_formation()
    currentFormationIndex = currentFormationIndex - 1
    if currentFormationIndex < 1 then
        currentFormationIndex = #FORMATIONS
    end
    toast("Formation: " .. get_current_formation().label)
    apply_follow_to_all()
end

local function increase_amount()
    spawnAmount = spawnAmount + 1
    if spawnAmount > 20 then
        spawnAmount = 20
    end
    toast("Spawn Amount: " .. tostring(spawnAmount))
end

local function decrease_amount()
    spawnAmount = spawnAmount - 1
    if spawnAmount < 1 then
        spawnAmount = 1
    end
    toast("Spawn Amount: " .. tostring(spawnAmount))
end

FeatureMgr.AddFeature(Utils.Joaat("BG_GodMode"), "God Mode", eFeatureType.Toggle, "Invincibilité", function(f)
    refresh_all()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_ShowBlips"), "Show Blips", eFeatureType.Toggle, "Blips carte", function(f)
    refresh_all()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_FollowPlayer"), "Follow Player", eFeatureType.Toggle, "Suivre le joueur", function(f)
    apply_follow_to_all()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_PreviousModel"), "Previous Model", eFeatureType.Button, "", function(f)
    previous_model()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_NextModel"), "Next Model", eFeatureType.Button, "", function(f)
    next_model()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_PreviousWeapon"), "Previous Weapon", eFeatureType.Button, "", function(f)
    previous_weapon()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_NextWeapon"), "Next Weapon", eFeatureType.Button, "", function(f)
    next_weapon()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_PreviousFormation"), "Previous Formation", eFeatureType.Button, "", function(f)
    previous_formation()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_NextFormation"), "Next Formation", eFeatureType.Button, "", function(f)
    next_formation()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_AmountMinus"), "Amount -", eFeatureType.Button, "", function(f)
    decrease_amount()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_AmountPlus"), "Amount +", eFeatureType.Button, "", function(f)
    increase_amount()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_ShowSelection"), "Show Current Selection", eFeatureType.Button, "", function(f)
    toast("Model: " .. get_current_model().label .. " | Weapon: " .. get_current_weapon().label)
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_ShowFormation"), "Show Formation", eFeatureType.Button, "", function(f)
    toast("Formation: " .. get_current_formation().label)
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_ShowAmount"), "Show Spawn Amount", eFeatureType.Button, "", function(f)
    toast("Spawn Amount: " .. tostring(spawnAmount))
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_SpawnSelected"), "Spawn Selected Amount", eFeatureType.Button, "", function(f)
    spawn_amount_custom(spawnAmount)
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_Spawn1"), "Spawn 1", eFeatureType.Button, "", function(f)
    local ped = create_bodyguard(2.0, 2.0, 1.0)
    if ped ~= 0 then
        apply_follow_to_all()
    end
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_Spawn5"), "Spawn 5", eFeatureType.Button, "", function(f)
    spawn_amount_custom(5)
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_Spawn10"), "Spawn 10", eFeatureType.Button, "", function(f)
    spawn_amount_custom(10)
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_Teleport"), "Teleport To Me", eFeatureType.Button, "", function(f)
    teleport_all()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_ShowCount"), "Show Count", eFeatureType.Button, "", function(f)
    toast("Bodyguards actifs: " .. tostring(get_count()))
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_RefreshAll"), "Refresh All", eFeatureType.Button, "", function(f)
    refresh_all()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_DeleteDeadOnly"), "Delete Dead Only", eFeatureType.Button, "", function(f)
    delete_dead_only()
end, true)

FeatureMgr.AddFeature(Utils.Joaat("BG_DeleteAll"), "Delete All", eFeatureType.Button, "", function(f)
    delete_all()
end, true)

ClickGUI.AddTab("Bodyguard Menu", function()
    if ClickGUI.BeginCustomChildWindow("Overview") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_ShowSelection"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_ShowFormation"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_ShowCount"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_RefreshAll"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Loadout") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_PreviousModel"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_NextModel"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_PreviousWeapon"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_NextWeapon"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Formation") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_FollowPlayer"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_PreviousFormation"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_NextFormation"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Options") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_GodMode"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_ShowBlips"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Custom Spawn") then
        ClickGUI.RenderFeature(Utils.Joaat("BG_AmountMinus"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_AmountPlus"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_ShowAmount"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_SpawnSelected"))
        ClickGUI.EndCustomChildWindow()
    end

    if ClickGUI.BeginCustomChildWindow("Quick Spawn") then
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

toast("Menu Bodyguard chargé")
toast("Model: " .. get_current_model().label)
toast("Weapon: " .. get_current_weapon().label)
toast("Formation: " .. get_current_formation().label)
toast("Spawn Amount: " .. tostring(spawnAmount))