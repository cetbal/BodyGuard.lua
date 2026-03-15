------------------------------------------------
-- Bodyguard Menu V15 Stable (Cherax)
------------------------------------------------

print("[Bodyguard] Script loaded")

local bodyguards = {}

local selectedModel = "s_m_y_blackops_01"
local selectedWeapon = "weapon_carbinerifle"

local spawnAmount = 3

local accuracy = 75
local armour = 100
local followDistance = 2.0

local autoRespawn = false
local protectPlayer = false

------------------------------------------------
-- MODELS
------------------------------------------------

local models = {
"s_m_y_blackops_01",
"s_m_m_security_01",
"s_m_m_fibsec_01",
"s_m_m_ciasec_01",
"s_m_y_swat_01"
}

------------------------------------------------
-- WEAPONS
------------------------------------------------

local weapons = {
"weapon_pistol",
"weapon_carbinerifle",
"weapon_assaultrifle",
"weapon_specialcarbine",
"weapon_smg"
}

------------------------------------------------
-- UTILS
------------------------------------------------

local function notify(msg)
    print("[Bodyguard] "..msg)
end

local function requestModel(hash)

    STREAMING.REQUEST_MODEL(hash)

    local timeout = 0

    while not STREAMING.HAS_MODEL_LOADED(hash) and timeout < 100 do
        SYSTEM.WAIT(10)
        timeout = timeout + 1
    end

    return STREAMING.HAS_MODEL_LOADED(hash)

end

------------------------------------------------
-- EQUIP
------------------------------------------------

local function equipBodyguard(ped)

    WEAPON.GIVE_WEAPON_TO_PED(ped,Utils.Joaat(selectedWeapon),9999,false,true)

    PED.SET_PED_ACCURACY(ped,accuracy)
    PED.SET_PED_ARMOUR(ped,armour)

    PED.SET_PED_COMBAT_ABILITY(ped,2)
    PED.SET_PED_COMBAT_RANGE(ped,2)

    PED.SET_PED_COMBAT_ATTRIBUTES(ped,46,true)

    if protectPlayer then
        PED.SET_PED_COMBAT_ATTRIBUTES(ped,5,true)
    end

end

------------------------------------------------
-- FOLLOW
------------------------------------------------

local function applyFollow(ped)

    local player = PLAYER.PLAYER_PED_ID()

    TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
        ped,
        player,
        math.random(-followDistance,followDistance),
        math.random(-followDistance,followDistance),
        0,
        2.0,
        -1,
        1.0,
        true
    )

end

local function applyFollowAll()

    for i,entry in pairs(bodyguards) do

        if entry and ENTITY.DOES_ENTITY_EXIST(entry.ped) then
            applyFollow(entry.ped)
        end

    end

end

------------------------------------------------
-- SPAWN
------------------------------------------------

local function spawnBodyguard()

    local player = PLAYER.PLAYER_PED_ID()

    local coords = ENTITY.GET_ENTITY_COORDS(player,true)

    local modelHash = Utils.Joaat(selectedModel)

    if not requestModel(modelHash) then
        notify("Model failed to load")
        return
    end

    local ped = PED.CREATE_PED(
        4,
        modelHash,
        coords.x + math.random(-2,2),
        coords.y + math.random(-2,2),
        coords.z,
        0,
        true,
        true
    )

    if ped == 0 then
        notify("CreatePed failed")
        return
    end

    equipBodyguard(ped)

    applyFollow(ped)

    table.insert(bodyguards,{ped=ped})

end

------------------------------------------------
-- SPAWN AMOUNT
------------------------------------------------

local function spawnAmountCustom(n)

    for i=1,n do
        spawnBodyguard()
        SYSTEM.WAIT(50)
    end

    notify("Bodyguards actifs: "..#bodyguards)

end

------------------------------------------------
-- CLEANUP
------------------------------------------------

local function cleanupBodyguards()

    for i=#bodyguards,1,-1 do

        local entry = bodyguards[i]

        if not entry
        or not entry.ped
        or not ENTITY.DOES_ENTITY_EXIST(entry.ped)
        or ENTITY.IS_ENTITY_DEAD(entry.ped)
        then
            table.remove(bodyguards,i)
        end

    end

end

------------------------------------------------
-- DELETE
------------------------------------------------

local function deleteAll()

    for i,entry in pairs(bodyguards) do

        if entry and entry.ped and ENTITY.DOES_ENTITY_EXIST(entry.ped) then

            entities.delete_by_handle(entry.ped)

        end

    end

    bodyguards = {}

    notify("Tous supprimés")

end

------------------------------------------------
-- ATTACK TARGET
------------------------------------------------

local function attackTarget()

    local success,target = PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(PLAYER.PLAYER_ID())

    if success then

        for _,entry in pairs(bodyguards) do

            if entry and ENTITY.DOES_ENTITY_EXIST(entry.ped) then

                TASK.TASK_COMBAT_PED(entry.ped,target,0,16)

            end

        end

    end

end

------------------------------------------------
-- SPAWN VEHICLE
------------------------------------------------

local function spawnInVehicle()

    local player = PLAYER.PLAYER_PED_ID()

    if PED.IS_PED_IN_ANY_VEHICLE(player,false) then

        local veh = PED.GET_VEHICLE_PED_IS_IN(player,false)

        spawnBodyguard()

        local last = bodyguards[#bodyguards]

        if last and last.ped then
            PED.SET_PED_INTO_VEHICLE(last.ped,veh,-2)
        end

    end

end

------------------------------------------------
-- FEATURES
------------------------------------------------

FeatureMgr.AddFeature(Utils.Joaat("BG_Spawn1"),"Spawn Bodyguard","button","",function()

    spawnAmountCustom(1)

end)

FeatureMgr.AddFeature(Utils.Joaat("BG_Spawn5"),"Spawn 5 Bodyguards","button","",function()

    spawnAmountCustom(5)

end)

FeatureMgr.AddFeature(Utils.Joaat("BG_DeleteAll"),"Delete All","button","",function()

    deleteAll()

end)

FeatureMgr.AddFeature(Utils.Joaat("BG_AttackTarget"),"Attack Target","button","",function()

    attackTarget()

end)

FeatureMgr.AddFeature(Utils.Joaat("BG_SpawnVehicle"),"Spawn In My Vehicle","button","",function()

    spawnInVehicle()

end)

------------------------------------------------
-- MENU
------------------------------------------------

ClickGUI.AddTab("Bodyguard Menu",function()

    ClickGUI.BeginCustomChildWindow("Spawn")

    ClickGUI.RenderFeature(Utils.Joaat("BG_Spawn1"))
    ClickGUI.RenderFeature(Utils.Joaat("BG_Spawn5"))
    ClickGUI.RenderFeature(Utils.Joaat("BG_SpawnVehicle"))

    ClickGUI.EndCustomChildWindow()

    ClickGUI.BeginCustomChildWindow("Combat")

    ClickGUI.RenderFeature(Utils.Joaat("BG_AttackTarget"))

    ClickGUI.EndCustomChildWindow()

    ClickGUI.BeginCustomChildWindow("Cleanup")

    ClickGUI.RenderFeature(Utils.Joaat("BG_DeleteAll"))

    ClickGUI.EndCustomChildWindow()

end)

------------------------------------------------
-- LOOP
------------------------------------------------

script.register_looped("BodyguardLoop",function()

    cleanupBodyguards()

    if autoRespawn and #bodyguards < spawnAmount then
        spawnBodyguard()
    end

end)

notify("Bodyguard Menu V15 Loaded")
