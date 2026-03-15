-- Bodyguard Menu V16 Stable
-- Compatible Cherax

print("[Bodyguard] Script loaded")

--------------------------------
-- VARIABLES
--------------------------------

local bodyguards = {}
local maxBodyguards = 10

local accuracy = 70
local armour = 100

local followDistance = 2.0

local pedModels = {
    "s_m_m_security_01",
    "s_m_y_blackops_01",
    "s_m_m_fibsec_01",
    "s_m_y_swat_01"
}

local weaponList = {
    {name="Pistol", weapon="WEAPON_PISTOL", ammo=250},
    {name="Carbine Rifle", weapon="WEAPON_CARBINERIFLE", ammo=500},
    {name="SMG", weapon="WEAPON_SMG", ammo=500}
}

local selectedModel = 1
local selectedWeapon = 1

--------------------------------
-- UTILS
--------------------------------

local function playerPed()
    return PLAYER.PLAYER_PED_ID()
end

local function playerCoords()
    return ENTITY.GET_ENTITY_COORDS(playerPed())
end

local function currentWeapon()
    return weaponList[selectedWeapon]
end

--------------------------------
-- EQUIP BODYGUARD
--------------------------------

local function equipBodyguard(ped)

    local weaponInfo = currentWeapon()
    local weaponHash = MISC.GET_HASH_KEY(weaponInfo.weapon)

    WEAPON.GIVE_WEAPON_TO_PED(ped, weaponHash, weaponInfo.ammo, false, true)

    PED.SET_PED_ACCURACY(ped, accuracy)
    PED.SET_PED_ARMOUR(ped, armour)

    PED.SET_PED_COMBAT_ABILITY(ped, 2)
    PED.SET_PED_COMBAT_RANGE(ped, 2)
    PED.SET_PED_COMBAT_MOVEMENT(ped, 2)

    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 0, true)
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 46, true)
    PED.SET_PED_COMBAT_ATTRIBUTES(ped, 5, true)

    PED.SET_PED_FLEE_ATTRIBUTES(ped, 0, false)

    PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)

    PED.SET_PED_RELATIONSHIP_GROUP_HASH(ped, MISC.GET_HASH_KEY("PLAYER"))

    TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(ped, 100.0, 0)

end

--------------------------------
-- FOLLOW PLAYER
--------------------------------

local function applyFollow(ped)

    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
        ped,
        playerPed(),
        0.0,
        -followDistance,
        0.0,
        5.0,
        -1,
        2.0,
        true
    )

    TASK.TASK_COMBAT_HATED_TARGETS_AROUND_PED(ped, 100.0, 0)

end

--------------------------------
-- CREATE BODYGUARD
--------------------------------

local function spawnBodyguard()

    if #bodyguards >= maxBodyguards then
        print("[Bodyguard] Max reached")
        return
    end

    local model = pedModels[selectedModel]
    local hash = MISC.GET_HASH_KEY(model)

    STREAMING.REQUEST_MODEL(hash)

    local timeout = 0
    while not STREAMING.HAS_MODEL_LOADED(hash) and timeout < 100 do
        SYSTEM.WAIT(10)
        timeout = timeout + 1
    end

    if not STREAMING.HAS_MODEL_LOADED(hash) then
        print("[Bodyguard] Model failed")
        return
    end

    local coords = playerCoords()

    local ped = PED.CREATE_PED(
        26,
        hash,
        coords.x + math.random(-2,2),
        coords.y + math.random(-2,2),
        coords.z,
        0.0,
        true,
        true
    )

    if ped == 0 then
        print("[Bodyguard] Spawn failed")
        return
    end

    PED.SET_PED_AS_GROUP_MEMBER(ped, PED.GET_PED_GROUP_INDEX(playerPed()))

    equipBodyguard(ped)
    applyFollow(ped)

    table.insert(bodyguards, ped)

    print("[Bodyguard] Spawned")
end

--------------------------------
-- CLEANUP
--------------------------------

local function cleanup()

    for i=#bodyguards,1,-1 do

        local ped = bodyguards[i]

        if not ENTITY.DOES_ENTITY_EXIST(ped) then
            table.remove(bodyguards, i)
        elseif ENTITY.IS_ENTITY_DEAD(ped) then
            table.remove(bodyguards, i)
        end

    end

end

--------------------------------
-- DELETE ALL
--------------------------------

local function deleteAll()

    for i,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then

            TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)

            entities.delete_by_handle(ped)

        end

    end

    bodyguards = {}

    print("[Bodyguard] Deleted")

end

--------------------------------
-- REFRESH
--------------------------------

local function refreshAll()

    for i,ped in ipairs(bodyguards) do

        if ENTITY.DOES_ENTITY_EXIST(ped) then

            equipBodyguard(ped)
            applyFollow(ped)

        end

    end

    print("[Bodyguard] Refreshed")

end

--------------------------------
-- MENU
--------------------------------

ClickGUI.AddTab("Bodyguard Menu", function()

    if ClickGUI.Button("Spawn Bodyguard") then
        spawnBodyguard()
    end

    if ClickGUI.Button("Delete All") then
        deleteAll()
    end

    if ClickGUI.Button("Refresh AI") then
        refreshAll()
    end

end)

--------------------------------
-- MAIN LOOP
--------------------------------

SYSTEM.CREATE_THREAD(function()

    while true do

        cleanup()

        SYSTEM.WAIT(1000)

    end

end)
