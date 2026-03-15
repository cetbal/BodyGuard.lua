dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

--------------------------------------------------
-- VARIABLES
--------------------------------------------------

local bodyguards = {}
local lastCombatTick = 0

local behaviour = "Defensive"

--------------------------------------------------
-- UTILS
--------------------------------------------------

local function loadModel(model)

    local hash = MISC.GET_HASH_KEY(model)

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

    --------------------------------------------------
    -- WEAPON
    --------------------------------------------------

    WEAPON.GIVE_WEAPON_TO_PED(
        ped,
        MISC.GET_HASH_KEY("WEAPON_CARBINERIFLE"),
        9999,
        false,
        true
    )

    PED.SET_PED_ACCURACY(ped,90)

    PED.SET_PED_ARMOUR(ped,100)

    PED.SET_PED_AS_GROUP_MEMBER(ped, PED.GET_PED_GROUP_INDEX(playerPed))

    PED.SET_PED_NEVER_LEAVES_GROUP(ped,true)

    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped,true)

    table.insert(bodyguards,ped)

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
-- BODYGUARD AI
--------------------------------------------------

function bodyguardAI()

    local playerPed = PLAYER.PLAYER_PED_ID()

    local time = MISC.GET_GAME_TIMER()

    if time - lastCombatTick < 2000 then
        return
    end

    lastCombatTick = time

    --------------------------------------------------
    -- PASSIVE
    --------------------------------------------------

    if behaviour == "Passive" then
        return
    end

    --------------------------------------------------
    -- DEFENSIVE
    --------------------------------------------------

    if behaviour == "Defensive" then

        if not PED.IS_PED_IN_COMBAT(playerPed,0) then
            return
        end

    end

    --------------------------------------------------
    -- ATTACK
    --------------------------------------------------

    for _,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then

            TASK.CLEAR_PED_TASKS(ped)

            TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(
                ped,
                120.0,
                0
            )

        end

    end

end

--------------------------------------------------
-- DELETE
--------------------------------------------------

function deleteBodyguards()

    for _,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then

            PED.DELETE_PED(ped)

        end

    end

    bodyguards = {}

end

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
        deleteBodyguards()
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

    followPlayer()

    bodyguardAI()

end)
