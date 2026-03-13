dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

local bodyguards = {}
local groupId = 0

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
-- FORMATIONS
------------------------------------------------

local FORMATIONS = {
"Line",
"Circle",
"Diamond",
"Around"
}

------------------------------------------------
-- SETTINGS
------------------------------------------------

local modelIndex = 1
local weaponIndex = 4
local formationIndex = 1

local spawnAmount = 3
local followDistance = 3
local accuracy = 80
local armour = 100

local autoRespawn = false

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

local model = MODELS[modelIndex]

local hash = MISC.GET_HASH_KEY(model)

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

------------------------------------------------
-- weapon
------------------------------------------------

local weapon = MISC.GET_HASH_KEY(WEAPONS[weaponIndex])

WEAPON.GIVE_WEAPON_TO_PED(
ped,
weapon,
9999,
false,
true
)

------------------------------------------------
-- stats
------------------------------------------------

PED.SET_PED_ACCURACY(ped,accuracy)
PED.SET_PED_ARMOUR(ped,armour)

PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped,true)

ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ped,true,true)

add_guard(ped)

table.insert(bodyguards,ped)

end

------------------------------------------------
-- SPAWN MULTI
------------------------------------------------

local function spawn_multiple(amount)

for i=1,amount do
spawn_guard()
end

end

------------------------------------------------
-- FOLLOW
------------------------------------------------

local function order_follow()

local playerPed=PLAYER.PLAYER_PED_ID()

for i,ped in ipairs(bodyguards) do

if ENTITY.DOES_ENTITY_EXIST(ped) then

TASK.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(
ped,
playerPed,
math.random(-followDistance,followDistance),
math.random(-followDistance,followDistance),
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
-- ATTACK AROUND
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
-- ATTACK AIM TARGET
------------------------------------------------

local function attack_aim()

local player=PLAYER.PLAYER_PED_ID()

local entity=0

if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(
PLAYER.PLAYER_ID(),
entity
) then

for i,ped in ipairs(bodyguards) do

TASK.TASK_SHOOT_AT_ENTITY(
ped,
entity,
5000,
0
)

end

end

end

------------------------------------------------
-- VEHICLE
------------------------------------------------

local function seat_vehicle()

local veh=PED.GET_VEHICLE_PED_IS_IN(
PLAYER.PLAYER_PED_ID(),
false
)

if veh==0 then return end

local seat=-1

for i,ped in ipairs(bodyguards) do

PED.SET_PED_INTO_VEHICLE(
ped,
veh,
seat
)

seat=seat+1

end

end

local function exit_vehicle()

for i,ped in ipairs(bodyguards) do

if PED.IS_PED_IN_ANY_VEHICLE(ped,false) then

TASK.TASK_LEAVE_VEHICLE(
ped,
PED.GET_VEHICLE_PED_IS_IN(ped,false),
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

FeatureMgr.AddFeature(Utils.Joaat("BGV11_Spawn"),"Spawn Bodyguard",eFeatureType.Button,"",function()

spawn_guard()
order_follow()

end)

FeatureMgr.AddFeature(Utils.Joaat("BGV11_SpawnX"),"Spawn Custom",eFeatureType.Button,"",function()

spawn_multiple(spawnAmount)
order_follow()

end)

FeatureMgr.AddFeature(Utils.Joaat("BGV11_Follow"),"Follow Player",eFeatureType.Button,"",function()

order_follow()

end)

FeatureMgr.AddFeature(Utils.Joaat("BGV11_Attack"),"Attack Around",eFeatureType.Button,"",function()

attack_mode()

end)

FeatureMgr.AddFeature(Utils.Joaat("BGV11_AttackAim"),"Attack Aimed Target",eFeatureType.Button,"",function()

attack_aim()

end)

FeatureMgr.AddFeature(Utils.Joaat("BGV11_Seat"),"Seat In Vehicle",eFeatureType.Button,"",function()

seat_vehicle()

end)

FeatureMgr.AddFeature(Utils.Joaat("BGV11_Exit"),"Exit Vehicle",eFeatureType.Button,"",function()

exit_vehicle()

end)

FeatureMgr.AddFeature(Utils.Joaat("BGV11_Delete"),"Delete All",eFeatureType.Button,"",function()

delete_all()

end)

------------------------------------------------
-- MENU
------------------------------------------------

ClickGUI.AddTab("Bodyguard Menu",function()

if ClickGUI.BeginCustomChildWindow("Deployment") then

ClickGUI.RenderFeature(Utils.Joaat("BGV11_Spawn"))
ClickGUI.RenderFeature(Utils.Joaat("BGV11_SpawnX"))

ClickGUI.EndCustomChildWindow()

end

if ClickGUI.BeginCustomChildWindow("Combat") then

ClickGUI.RenderFeature(Utils.Joaat("BGV11_Follow"))
ClickGUI.RenderFeature(Utils.Joaat("BGV11_Attack"))
ClickGUI.RenderFeature(Utils.Joaat("BGV11_AttackAim"))

ClickGUI.EndCustomChildWindow()

end

if ClickGUI.BeginCustomChildWindow("Vehicle") then

ClickGUI.RenderFeature(Utils.Joaat("BGV11_Seat"))
ClickGUI.RenderFeature(Utils.Joaat("BGV11_Exit"))

ClickGUI.EndCustomChildWindow()

end

if ClickGUI.BeginCustomChildWindow("Cleanup") then

ClickGUI.RenderFeature(Utils.Joaat("BGV11_Delete"))

ClickGUI.EndCustomChildWindow()

end

end)

Logger.Log(eLogColor.LIGHTGREEN,"Bodyguard","V11 Loaded")
