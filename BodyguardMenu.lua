-- BodyguardMenuV14.lua
-- Version V14 avec menus déroulants pour modèles, armes et options

-- Variables principales
local bodyguards = {}
local maxBodyguards = 5
local modelIndex = 1
local weaponIndex = 1
local respawnTime = 10  -- Temps en secondes pour respawn des gardes
local followPlayer = true
local models = {
    "s_m_m_security_01",  -- Security
    "s_m_m_fiboffice_01", -- FIB
    "s_m_m_iaa_01",       -- IAA
    "s_m_m_swat_01",      -- SWAT
    "s_m_m_blackops_01",  -- Black Ops
}
local weapons = {
    "WEAPON_PISTOL",
    "WEAPON_COMBATPISTOL",
    "WEAPON_CARBINERIFLE",
    "WEAPON_SMG",
    "WEAPON_HEAVYSHOTGUN",
}
local followMode = {
    "Suivre",
    "Ne pas suivre"
}

-- Fonction pour récupérer le modèle
local function getModel(modelIndex)
    return models[modelIndex] or models[1]
end

-- Fonction pour récupérer l'arme
local function getWeapon(weaponIndex)
    return weapons[weaponIndex] or weapons[1]
end

-- Fonction pour créer un garde
local function createBodyguard(x, y, z)
    local model = getModel(modelIndex)
    local ped = CREATE_PED(4, model, x, y, z, 0, true, false)  -- Créer un garde
    SET_ENTITY_INVINCIBLE(ped, true)
    SET_PED_AS_GROUP_MEMBER(ped, PLAYER.PLAYER_PED_ID())  -- Ajoute le garde au groupe
    table.insert(bodyguards, ped)
end

-- Fonction pour supprimer tous les bodyguards
local function deleteAllBodyguards()
    for _, ped in ipairs(bodyguards) do
        if DOES_ENTITY_EXIST(ped) then
            DELETE_ENTITY(ped)
        end
    end
    bodyguards = {}
    info("Tous les bodyguards ont été supprimés.")
end

-- Fonction pour faire suivre le joueur
local function makeBodyguardsFollowPlayer()
    for _, ped in ipairs(bodyguards) do
        TASK.FOLLOW_TO_OFFSET_OF_ENTITY(ped, PLAYER.PLAYER_PED_ID(), 0, 2, 0, 3, -1, false)
    end
end

-- Fonction pour donner une arme à tous les bodyguards
local function giveWeaponToBodyguards(weaponIndex)
    local weapon = getWeapon(weaponIndex)
    for _, ped in ipairs(bodyguards) do
        GIVE_WEAPON_TO_PED(ped, weapon, 250, false, false)
    end
end

-- Fonction pour faire suivre ou non
local function toggleFollowMode(followIndex)
    followPlayer = followIndex == 1
    if followPlayer then
        makeBodyguardsFollowPlayer()
    end
end

------------------------------------------------
--  Menus Déroulants et Boutons Cherax
------------------------------------------------

-- Combo pour choisir le modèle de garde
FeatureMgr.AddFeature(HASH_BG_MODEL_COMBO, "Model", eFeatureType.Combo, "", function(f)
    local idx = f:GetListIndex()  -- Récupérer l'index sélectionné
    modelIndex = idx + 1
    info("Modèle de garde changé : " .. models[modelIndex])
end, true)

-- Combo pour choisir l'arme
FeatureMgr.AddFeature(HASH_BG_WEAPON_COMBO, "Weapon", eFeatureType.Combo, "", function(f)
    local idx = f:GetListIndex()  -- Récupérer l'index sélectionné
    weaponIndex = idx + 1
    info("Arme choisie : " .. weapons[weaponIndex])
end, true)

-- Combo pour choisir si les bodyguards suivent ou non
FeatureMgr.AddFeature(HASH_BG_FOLLOW_COMBO, "Follow Mode", eFeatureType.Combo, "", function(f)
    local idx = f:GetListIndex()  -- Récupérer l'index sélectionné
    toggleFollowMode(idx + 1)
end, true)

-- Spawn d'un bodyguard
FeatureMgr.AddFeature(HASH_BG_SPAWN_BUTTON, "Spawn Bodyguard", eFeatureType.Button, "", function()
    local x, y, z = GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true)
    createBodyguard(x, y, z)
    info("Garde spawné à votre position")
end, true)

-- Supprimer tous les bodyguards
FeatureMgr.AddFeature(HASH_BG_DELETE_ALL_BUTTON, "Delete All Bodyguards", eFeatureType.Button, "", function()
    deleteAllBodyguards()
end, true)

-- Donner une arme à tous les bodyguards
FeatureMgr.AddFeature(HASH_BG_GIVE_WEAPON, "Give Weapon to Bodyguards", eFeatureType.Button, "", function()
    giveWeaponToBodyguards(weaponIndex)
end, true)

-- Respawn des bodyguards morts
FeatureMgr.AddFeature(HASH_BG_RESPAWN_BUTTON, "Respawn Dead Bodyguards", eFeatureType.Button, "", function()
    respawnBodyguards()
end, true)

-- Slider pour ajuster le nombre de bodyguards
FeatureMgr.AddFeature(HASH_BG_SLIDER, "Number of Bodyguards", eFeatureType.Slider, "", function(sliderValue)
    maxBodyguards = math.floor(sliderValue)
    info("Nombre de gardes défini à : " .. maxBodyguards)
end, true)

------------------------------------------------
--  Initialisation et Mise en place
------------------------------------------------

-- Initialisation des variables
info("Menu de bodyguards initialisé avec succès !")
