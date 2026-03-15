dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

--------------------------------------------------
-- VARIABLES
--------------------------------------------------

local bodyguards = {}
local behaviour = "Defensive"

--------------------------------------------------
-- LOAD MODEL
--------------------------------------------------

function loadModel(name)

    local hash = MISC.GET_HASH_KEY(name)

    STREAMING.REQUEST_MODEL(hash)

    while not STREAMING.HAS_MODEL_LOADED(hash) do
        SYSTEM.WAIT(0)
    end

    return hash

end

--------------------------------------------------
-- SPAWN BODYGUARD
--------------------------------------------------

function spawnBodyguard()

    local playerPed = PLAYER.PLAYER_PED_ID()

    local coords = ENTITY.GET_ENTITY_COORDS(playerPed,true)

    local model = loadModel("s_m_m_security_01")

    local ped = PED.CREATE_PED(
        4,
        model,
        coords.x + math.random(-2,2),
        coords.y + math.random(-2,2),
        coords.z,
        0.0,
        true,
        true
    )

    WEAPON.GIVE_WEAPON_TO_PED(
        ped,
        MISC.GET_HASH_KEY("WEAPON_CARBINERIFLE"),
        9999,
        false,
        true
    )

    PED.SET_PED_ACCURACY(ped,90)
    PED.SET_PED_ARMOUR(ped,100)

    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped,true)

    local group = PED.GET_PED_GROUP_INDEX(playerPed)

    PED.SET_PED_AS_GROUP_MEMBER(ped,group)

    PED.SET_PED_NEVER_LEAVES_GROUP(ped,true)

    table.insert(bodyguards,ped)

end

--------------------------------------------------
-- DELETE
--------------------------------------------------

function deleteAll()

    for _,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then
            PED.DELETE_PED(ped)
        end

    end

    bodyguards = {}

end

--------------------------------------------------
-- FOLLOW PLAYER
--------------------------------------------------

function followPlayer()

    local playerPed = PLAYER.PLAYER_PED_ID()

    for i,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then

            TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
                ped,
                playerPed,
                i,
                -2.0,
                0.0,
                2.0,
                -1,
                3.0,
                true
            )

        end

    end

end

--------------------------------------------------
-- AI THREAD (IMPORTANT POUR CHERAX)
--------------------------------------------------

Script.RegisterLooped("Bodyguard_AI", function()

    local playerPed = PLAYER.PLAYER_PED_ID()

    --------------------------------------------------
    -- FOLLOW
    --------------------------------------------------

    followPlayer()

    --------------------------------------------------
    -- PASSIVE
    --------------------------------------------------

    if behaviour == "Passive" then
        SYSTEM.WAIT(2000)
        return
    end

    --------------------------------------------------
    -- DEFENSIVE
    --------------------------------------------------

    if behaviour == "Defensive" then

        if not PED.IS_PED_IN_COMBAT(playerPed,0) then
            SYSTEM.WAIT(2000)
            return
        end

    end

    --------------------------------------------------
    -- ATTACK
    --------------------------------------------------

    for _,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then

            TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(
                ped,
                120.0,
                0
            )

        end

    end

    SYSTEM.WAIT(2000)

end)

--------------------------------------------------
-- MENU
--------------------------------------------------

ClickGUI.AddTab("Bodyguard Menu", function()

    if ClickGUI.Button("Spawn Bodyguard") then
        spawnBodyguard()
    end

    if ClickGUI.Button("Spawn 5 Bodyguards") then
        for i=1,5 do
            spawnBodyguard()
        end
    end

    if ClickGUI.Button("Delete All") then
        deleteAll()
    end

    if ClickGUI.Button("Behaviour Passive") then
        behaviour = "Passive"
    end

    if ClickGUI.Button("Behaviour Defensive") then
        behaviour = "Defensive"
    end

    if ClickGUI.Button("Behaviour Aggressive") then
        behaviour = "Aggressive"
    end

end)
