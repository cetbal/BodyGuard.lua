dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

local bodyguards = {}
local playerGroup = 0

------------------------------------------------
-- MODELS
------------------------------------------------

local MODELS = {
    "s_m_m_security_01",
    "s_m_m_fiboffice_01",
    "s_m_m_ciasec_01",
    "s_m_y_swat_01",
    "s_m_y_blackops_01"
}

local MODEL_NAMES = {
    "Security",
    "FIB",
    "CIA",
    "SWAT",
    "Black Ops"
}

------------------------------------------------
-- WEAPONS
------------------------------------------------

local WEAPONS = {
    "WEAPON_PISTOL",
    "WEAPON_COMBATPISTOL",
    "WEAPON_SMG",
    "WEAPON_CARBINERIFLE",
    "WEAPON_PUMPSHOTGUN"
}

local WEAPON_NAMES = {
    "Pistol",
    "Combat Pistol",
    "SMG",
    "Carbine Rifle",
    "Shotgun"
}

------------------------------------------------
-- SETTINGS
------------------------------------------------

local currentModel = 1
local currentWeapon = 4
local spawnAmount = 3

------------------------------------------------
-- HELPERS
------------------------------------------------

local function info(text)
    Logger.Log(eLogColor.LIGHTGREEN, "Bodyguard", text)
end

local function ensure_group()

    if playerGroup ~= 0 then
        return
    end

    playerGroup = PED.CREATE_GROUP(0)

    PED.SET_PED_AS_GROUP_LEADER(
        PLAYER.PLAYER_PED_ID(),
        playerGroup
    )

    PED.SET_GROUP_SEPARATION_RANGE(
        playerGroup,
        9999.0
    )

end

local function add_to_group(ped)

    ensure_group()

    PED.SET_PED_AS_GROUP_MEMBER(
        ped,
        playerGroup
    )

    PED.SET_PED_CAN_TELEPORT_TO_GROUP_LEADER(
        ped,
        playerGroup,
        true
    )

end

------------------------------------------------
-- SPAWN
------------------------------------------------

local function spawn_guard()

    local playerPed = PLAYER.PLAYER_PED_ID()

    local coords = ENTITY.GET_ENTITY_COORDS(
        playerPed,
        true
    )

    local model = MODELS[currentModel]

    local hash = MISC.GET_HASH_KEY(model)

    STREAMING.REQUEST_MODEL(hash)

    local i = 0
    while not STREAMING.HAS_MODEL_LOADED(hash) and i < 200 do
        SYSTEM.WAIT(0)
        i = i + 1
    end

    local ped = PED.CREATE_PED(
        4,
        hash,
        coords.x + math.random(-3,3),
        coords.y + math.random(-3,3),
        coords.z,
        0.0,
        true,
        true
    )

    if ped == 0 then
        return
    end

    ------------------------------------------------
    -- WEAPON
    ------------------------------------------------

    local weapon = MISC.GET_HASH_KEY(
        WEAPONS[currentWeapon]
    )

    WEAPON.GIVE_WEAPON_TO_PED(
        ped,
        weapon,
        9999,
        false,
        true
    )

    ------------------------------------------------
    -- STATS
    ------------------------------------------------

    PED.SET_PED_ACCURACY(ped, 80)
    PED.SET_PED_ARMOUR(ped, 100)

    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(
        ped,
        true
    )

    ------------------------------------------------
    -- GROUP
    ------------------------------------------------

    add_to_group(ped)

    table.insert(bodyguards, ped)

end

------------------------------------------------
-- FOLLOW
------------------------------------------------

local function order_follow()

    local playerPed = PLAYER.PLAYER_PED_ID()

    for i,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then

            TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
                ped,
                playerPed,
                math.random(-2,2),
                math.random(-2,2),
                0.0,
                3.0,
                -1,
                2.0,
                true
            )

        end

    end

end

------------------------------------------------
-- AGGRESSIVE
------------------------------------------------

local function order_attack()

    for i,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then

            TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(
                ped,
                100.0,
                0
            )

        end

    end

end

------------------------------------------------
-- DELETE
------------------------------------------------

local function delete_all()

    for i,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then

            ENTITY.SET_ENTITY_HEALTH(
                ped,
                0
            )

        end

    end

    bodyguards = {}

end

------------------------------------------------
-- FEATURES
------------------------------------------------

FeatureMgr.AddFeature(
Utils.Joaat("BG_Spawn"),
"Spawn Bodyguard",
eFeatureType.Button,
"",
function()

    spawn_guard()

    order_follow()

end)

FeatureMgr.AddFeature(
Utils.Joaat("BG_Spawn5"),
"Spawn 5",
eFeatureType.Button,
"",
function()

    for i=1,5 do
        spawn_guard()
    end

    order_follow()

end)

FeatureMgr.AddFeature(
Utils.Joaat("BG_Follow"),
"Follow Player",
eFeatureType.Button,
"",
function()

    order_follow()

end)

FeatureMgr.AddFeature(
Utils.Joaat("BG_Attack"),
"Aggressive Mode",
eFeatureType.Button,
"",
function()

    order_attack()

end)

FeatureMgr.AddFeature(
Utils.Joaat("BG_Delete"),
"Delete All",
eFeatureType.Button,
"",
function()

    delete_all()

end)

------------------------------------------------
-- MENU
------------------------------------------------

ClickGUI.AddTab("Bodyguard Menu", function()

    if ClickGUI.BeginCustomChildWindow("Spawn") then

        ClickGUI.RenderFeature(Utils.Joaat("BG_Spawn"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_Spawn5"))

        ClickGUI.EndCustomChildWindow()

    end

    if ClickGUI.BeginCustomChildWindow("Commands") then

        ClickGUI.RenderFeature(Utils.Joaat("BG_Follow"))
        ClickGUI.RenderFeature(Utils.Joaat("BG_Attack"))

        ClickGUI.EndCustomChildWindow()

    end

    if ClickGUI.BeginCustomChildWindow("Cleanup") then

        ClickGUI.RenderFeature(Utils.Joaat("BG_Delete"))

        ClickGUI.EndCustomChildWindow()

    end

end)

info("Bodyguard V9 Loaded")
