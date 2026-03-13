dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

local bodyguards = {}
local groupId = 0

------------------------------------------------
-- GROUP
------------------------------------------------

local function ensure_group()

    if groupId ~= 0 then return end

    groupId = PED.CREATE_GROUP(0)

    PED.SET_PED_AS_GROUP_LEADER(
        PLAYER.PLAYER_PED_ID(),
        groupId
    )

    PED.SET_GROUP_SEPARATION_RANGE(groupId,9999.0)

end

local function add_guard(ped)

    ensure_group()

    PED.SET_PED_AS_GROUP_MEMBER(ped,groupId)

    PED.SET_PED_CAN_TELEPORT_TO_GROUP_LEADER(
        ped,
        groupId,
        true
    )

end

------------------------------------------------
-- SPAWN
------------------------------------------------

local function spawn_guard()

    local playerPed = PLAYER.PLAYER_PED_ID()

    local coords = ENTITY.GET_ENTITY_COORDS(playerPed,true)

    local hash = MISC.GET_HASH_KEY("s_m_m_security_01")

    STREAMING.REQUEST_MODEL(hash)

    local i=0
    while not STREAMING.HAS_MODEL_LOADED(hash) and i<200 do
        SYSTEM.WAIT(0)
        i=i+1
    end

    local ped = PED.CREATE_PED(
        4,
        hash,
        coords.x+math.random(-3,3),
        coords.y+math.random(-3,3),
        coords.z,
        0,
        true,
        true
    )

    if ped==0 then return end

    local weapon = MISC.GET_HASH_KEY("WEAPON_CARBINERIFLE")

    WEAPON.GIVE_WEAPON_TO_PED(
        ped,
        weapon,
        9999,
        false,
        true
    )

    PED.SET_PED_ACCURACY(ped,80)
    PED.SET_PED_ARMOUR(ped,100)

    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped,true)

    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ped,true,true)

    add_guard(ped)

    table.insert(bodyguards,ped)

end

------------------------------------------------
-- FOLLOW
------------------------------------------------

local function follow_player()

    local playerPed=PLAYER.PLAYER_PED_ID()

    for i,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then

            TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
                ped,
                playerPed,
                math.random(-3,3),
                math.random(-3,3),
                0,
                3,
                -1,
                2,
                true
            )

        end

    end

end

------------------------------------------------
-- ATTACK
------------------------------------------------

local function attack_mode()

    for i,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then

            TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(
                ped,
                120.0,
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

            ENTITY.SET_ENTITY_HEALTH(ped,0)

        end

    end

    bodyguards={}

end

------------------------------------------------
-- FEATURES
------------------------------------------------

local spawnFeature = FeatureMgr.AddFeature(
Utils.Joaat("BGV11_Spawn"),
"Spawn Bodyguard",
eFeatureType.Button,
"",
function()

spawn_guard()
follow_player()

end)

local spawn5Feature = FeatureMgr.AddFeature(
Utils.Joaat("BGV11_Spawn5"),
"Spawn 5",
eFeatureType.Button,
"",
function()

for i=1,5 do
spawn_guard()
end

follow_player()

end)

local followFeature = FeatureMgr.AddFeature(
Utils.Joaat("BGV11_Follow"),
"Follow Player",
eFeatureType.Button,
"",
function()

follow_player()

end)

local attackFeature = FeatureMgr.AddFeature(
Utils.Joaat("BGV11_Attack"),
"Aggressive Mode",
eFeatureType.Button,
"",
function()

attack_mode()

end)

local deleteFeature = FeatureMgr.AddFeature(
Utils.Joaat("BGV11_Delete"),
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

    if ClickGUI.BeginCustomChildWindow("Deployment") then

        ClickGUI.RenderFeature(spawnFeature)
        ClickGUI.RenderFeature(spawn5Feature)

        ClickGUI.EndCustomChildWindow()

    end

    if ClickGUI.BeginCustomChildWindow("Combat") then

        ClickGUI.RenderFeature(followFeature)
        ClickGUI.RenderFeature(attackFeature)

        ClickGUI.EndCustomChildWindow()

    end

    if ClickGUI.BeginCustomChildWindow("Cleanup") then

        ClickGUI.RenderFeature(deleteFeature)

        ClickGUI.EndCustomChildWindow()

    end

end)

Logger.Log(eLogColor.LIGHTGREEN,"Bodyguard","V11 FIX Loaded")
