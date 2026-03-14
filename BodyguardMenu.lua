dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

local bodyguards = {}

------------------------------------------------
-- OPTIONS
------------------------------------------------

local MODELS = {
    {label="Security", model="s_m_m_security_01"},
    {label="FIB", model="s_m_m_fiboffice_01"},
    {label="CIA", model="s_m_m_ciasec_01"},
    {label="SWAT", model="s_m_y_swat_01"},
    {label="Black Ops", model="s_m_y_blackops_01"}
}

local WEAPONS = {
    {label="Pistol", weapon="WEAPON_PISTOL", ammo=500},
    {label="Combat Pistol", weapon="WEAPON_COMBATPISTOL", ammo=500},
    {label="SMG", weapon="WEAPON_SMG", ammo=800},
    {label="Carbine Rifle", weapon="WEAPON_CARBINERIFLE", ammo=1200}
}

local MODEL_LABELS={}
local WEAPON_LABELS={}

for i,v in ipairs(MODELS) do MODEL_LABELS[i]=v.label end
for i,v in ipairs(WEAPONS) do WEAPON_LABELS[i]=v.label end

local currentModel=1
local currentWeapon=1
local spawnAmount=3

------------------------------------------------
-- HASHES
------------------------------------------------

local HASH_MODEL=Utils.Joaat("BG_Model")
local HASH_WEAPON=Utils.Joaat("BG_Weapon")
local HASH_AMOUNT=Utils.Joaat("BG_Amount")

------------------------------------------------
-- UTILS
------------------------------------------------

local function info(t)
Logger.Log(eLogColor.LIGHTGREEN,"Bodyguard",t)
GUI.AddToast("Bodyguard",t,2500,eToastPos.TOP_RIGHT)
end

local function loadModel(hash)
STREAMING.REQUEST_MODEL(hash)

local i=0
while not STREAMING.HAS_MODEL_LOADED(hash) and i<200 do
SYSTEM.WAIT(0)
i=i+1
end

return STREAMING.HAS_MODEL_LOADED(hash)
end

------------------------------------------------
-- SPAWN
------------------------------------------------

local function spawnOne(x,y,z)

local model=MODELS[currentModel]
local weapon=WEAPONS[currentWeapon]

local hash=MISC.GET_HASH_KEY(model.model)

if not loadModel(hash) then
info("Model load failed")
return
end

local ped=PED.CREATE_PED(4,hash,x,y,z,0,false,false)

WEAPON.GIVE_WEAPON_TO_PED(
ped,
MISC.GET_HASH_KEY(weapon.weapon),
weapon.ammo,
false,
true
)

PED.SET_PED_AS_GROUP_MEMBER(
ped,
PLAYER.GET_PLAYER_GROUP(PLAYER.PLAYER_ID())
)

table.insert(bodyguards,ped)

end

local function spawnMultiple()

local player=PLAYER.PLAYER_PED_ID()
local pos=ENTITY.GET_ENTITY_COORDS(player,true)

for i=1,spawnAmount do
spawnOne(
pos.x+(i*1.2),
pos.y+1.5,
pos.z
)
end

info(spawnAmount.." bodyguards spawned")

end

------------------------------------------------
-- DELETE
------------------------------------------------

local function deleteAll()

for _,ped in pairs(bodyguards) do

if ENTITY.DOES_ENTITY_EXIST(ped) then
ENTITY.DELETE_ENTITY(ped)
end

end

bodyguards={}

info("All bodyguards deleted")

end

------------------------------------------------
-- FEATURES
------------------------------------------------

FeatureMgr.AddFeature(
HASH_MODEL,
"Agent Model",
eFeatureType.Combo,
"Choose model",
function(f)

local i=f:GetListIndex()
currentModel=i+1

info("Model "..MODELS[currentModel].label)

end,
true
)

FeatureMgr.GetFeature(HASH_MODEL):SetList(MODEL_LABELS)

------------------------------------------------

FeatureMgr.AddFeature(
HASH_WEAPON,
"Primary Weapon",
eFeatureType.Combo,
"Choose weapon",
function(f)

local i=f:GetListIndex()
currentWeapon=i+1

info("Weapon "..WEAPONS[currentWeapon].label)

end,
true
)

FeatureMgr.GetFeature(HASH_WEAPON):SetList(WEAPON_LABELS)

------------------------------------------------

FeatureMgr.AddFeature(
HASH_AMOUNT,
"Spawn Amount",
eFeatureType.SliderInt,
"Number of guards",
function(f)

spawnAmount=f:GetIntValue()

end,
true
)

------------------------------------------------

FeatureMgr.AddFeature(
Utils.Joaat("BG_Spawn"),
"Spawn Bodyguards",
eFeatureType.Button,
"",
function()

spawnMultiple()

end,
true
)

------------------------------------------------

FeatureMgr.AddFeature(
Utils.Joaat("BG_Delete"),
"Delete All",
eFeatureType.Button,
"",
function()

deleteAll()

end,
true
)

info("Bodyguard Menu V15 Loaded")
