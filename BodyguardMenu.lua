-- BodyguardMenu.lua
-- Version V14 - Correction des boutons et de l'affichage

-- 1. Initialisation des variables
local bodyguards = {}
local maxBodyguards = 5
local modelIndex = 1
local weaponIndex = 1
local respawnTime = 10  -- Temps de respawn des gardes (en secondes)

-- 2. Modèles de bodyguards (exemple)
local models = {
    "s_m_m_security_01",  -- Security
    "s_m_m_fiboffice_01", -- FIB
    "s_m_m_iaa_01",       -- IAA
    "s_m_m_swat_01",      -- SWAT
    "s_m_m_blackops_01",  -- Black Ops
}

-- 3. Armes des bodyguards
local weapons = {
    "WEAPON_PISTOL",
    "WEAPON_COMBATPISTOL",
    "WEAPON_CARBINERIFLE",
    "WEAPON_SMG",
    "WEAPON_HEAVYSHOTGUN",
}

-- 4. Fonction pour obtenir le modèle du garde
local function getModel(modelIndex)
    return models[modelIndex] or models[1]  -- Si l'index est invalide, utiliser le premier modèle
end

-- 5. Fonction pour obtenir l'arme
local function getWeapon(weaponIndex)
    return weapons[weaponIndex] or weapons[1]  -- Si l'index est invalide, utiliser la première arme
end

-- 6. Fonction pour créer un garde
local function createBodyguard(x, y, z)
    local model = getModel(modelIndex)
    local ped = CREATE_PED(4, model, x, y, z, 0, true, false)  -- Créer un garde
    SET_ENTITY_INVINCIBLE(ped, true)
    SET_PED_AS_GROUP_MEMBER(ped, PLAYER.PLAYER_PED_ID())  -- Le garde fait partie du groupe
    table.insert(bodyguards, ped)
end

-- 7. Fonction pour supprimer tous les bodyguards
local function deleteAllBodyguards()
    for _, ped in ipairs(bodyguards) do
        if DOES_ENTITY_EXIST(ped) then
            DELETE_ENTITY(ped)
        end
    end
    bodyguards = {}
    info("Tous les bodyguards ont été supprimés.")
end

-- 8. Fonction pour respawn des gardes morts
local function respawnBodyguards()
    for i, ped in ipairs(bodyguards) do
        if DOES_ENTITY_EXIST(ped) and GET_ENTITY_HEALTH(ped) <= 0 then
            local coords = GET_ENTITY_COORDS(ped, false)
            DELETE_ENTITY(ped)
            createBodyguard(coords.x, coords.y, coords.z)
        end
    end
end

-- 9. Fonction pour donner une arme à tous les gardes
local function giveWeaponToBodyguards(weaponIndex)
    local weapon = getWeapon(weaponIndex)
    for _, ped in ipairs(bodyguards) do
        GIVE_WEAPON_TO_PED(ped, weapon, 250, false, false)
    end
end

-- 10. Fonction pour faire suivre le joueur
local function makeBodyguardsFollowPlayer()
    for _, ped in ipairs(bodyguards) do
        TASK.FOLLOW_TO_OFFSET_OF_ENTITY(ped, PLAYER.PLAYER_PED_ID(), 0, 2, 0, 3, -1, false)
    end
end

------------------------------------------------
-- 11. Ajouter les boutons et le menu
------------------------------------------------

-- Ajouter le modèle du bodyguard
FeatureMgr.AddFeature(HASH_BG_MODEL_COMBO, "Model", eFeatureType.Combo, "", function(f)
    local idx = f:GetListIndex()
    modelIndex = idx + 1
    info("Modèle de garde changé : " .. models[modelIndex])
end, true)

-- Ajouter l'arme des bodyguards
FeatureMgr.AddFeature(HASH_BG_WEAPON_COMBO, "Weapon", eFeatureType.Combo, "", function(f)
    local idx = f:GetListIndex()
    weaponIndex = idx + 1
    info("Arme choisie : " .. weapons[weaponIndex])
end, true)

-- Bouton pour spawn un bodyguard
FeatureMgr.AddFeature(HASH_BG_SPAWN_BUTTON, "Spawn Bodyguard", eFeatureType.Button, "", function()
    local x, y, z = GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), true)
    createBodyguard(x, y, z)
    info("Garde spawné à votre position")
end, true)

-- Bouton pour supprimer tous les bodyguards
FeatureMgr.AddFeature(HASH_BG_DELETE_ALL_BUTTON, "Delete All Bodyguards", eFeatureType.Button, "", function()
    deleteAllBodyguards()
end, true)

-- Bouton pour respawn des bodyguards morts
FeatureMgr.AddFeature(HASH_BG_RESPAWN_BUTTON, "Respawn Dead Bodyguards", eFeatureType.Button, "", function()
    respawnBodyguards()
end, true)

-- Bouton pour faire suivre les bodyguards
FeatureMgr.AddFeature(HASH_BG_FOLLOW_PLAYER, "Make Bodyguards Follow You", eFeatureType.Button, "", function()
    makeBodyguardsFollowPlayer()
end, true)

-- Bouton pour donner une arme à tous les bodyguards
FeatureMgr.AddFeature(HASH_BG_GIVE_WEAPON, "Give Weapon to Bodyguards", eFeatureType.Button, "", function()
    giveWeaponToBodyguards(weaponIndex)
end, true)

-- Slider pour ajuster le nombre de gardes
FeatureMgr.AddFeature(HASH_BG_SLIDER, "Number of Bodyguards", eFeatureType.Slider, "", function(sliderValue)
    maxBodyguards = math.floor(sliderValue)
    info("Nombre de gardes défini à : " .. maxBodyguards)
end, true)

-- Combo pour la formation des gardes
FeatureMgr.AddFeature(HASH_BG_FORMATION_COMBO, "Formation", eFeatureType.Combo, "", function(f)
    local idx = f:GetListIndex()
    formationIndex = idx + 1
    info("Formation de garde choisie : Formation " .. formationIndex)
end, true)
