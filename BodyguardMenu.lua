dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

local SCRIPT_NAME = "BetterBodyguards"

local bodyguards = {}
local lastAiTick = 0

local settings = {
    modelIndex = 1,
    weaponIndex = 4,
    formationIndex = 1,
    aiModeIndex = 2, -- 1 Neutral / 2 Defense / 3 Offensive
    spawnAmount = 3,
    accuracy = 85,
    armour = 100,
    followDistance = 3,
    godMode = false,
    showBlips = true,
    followPlayer = true,
    protectPlayer = true,
    autoRespawn = false
}

local MODELS = {
    { label = "Security",  model = "s_m_m_security_01"  },
    { label = "FIB",       model = "s_m_m_fiboffice_01" },
    { label = "IAA",       model = "s_m_m_ciasec_01
