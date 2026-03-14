-- V14 - Bodyguard Lua Script (Cherax)
-- Copyright (C) 2026

-- 1. Définir les variables
local bodyguards = {}
local maxBodyguards = 5
local modelIndex = 1
local weaponIndex = 1
local respawnTime = 10  -- Temps de respawn des gardes (en secondes)

-- 2. Modèles de bodyguards (par exemple)
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

-- 4. Fonction pour récupérer un modèle de garde
local function getModel(modelIndex)
    return models[modelIndex] or models[1]  -- Si l'index est invalide, utiliser le premier modèle
end

-- 5. Fonction pour récupérer une arme
local function getWeapon(weaponIndex)
    return weapons[weaponIndex] or weapons[1]  -- Si l'index est invalide, utiliser la première arme
end

-- 6. Fonction pour créer un garde
local function createBodyguard(x, y, z)
    local model = getModel(modelIndex)
    local ped = CREATE_PED(4, model, x, y, z, 0, true, false)  -- Créer un garde à la position spécifiée
    SET_ENTITY_INVINCIBLE(ped, true)
    SET_PED_AS_GROUP_MEMBER(ped, PLAYER.PLAYER_PED_ID())  -- Le garde fait partie du groupe
    table.insert(bodyguards, ped)
end

-- 7. Fonction pour supprimer tous les gardes
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

-- 10. Fonction pour suivre le joueur
local function makeBodyguardsFollowPlayer()
    for _, ped in ipairs(bodyguards) do
        TASK.FOLLOW_TO_OFFSET_OF_ENTITY(ped, PLAYER.PLAYER_PED_ID(), 0, 2, 0, 3, -1, false)
    end
end
