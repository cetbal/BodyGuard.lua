-- Bodyguard Menu V15 Stable Cherax

print("[Bodyguard] Script loaded")

local bodyguards = {}

local models = {
    "s_m_m_security_01",
    "s_m_m_fiboffice_01",
    "s_m_m_iaa_01",
    "s_m_m_swat_01"
}

local weapons = {
    "WEAPON_PISTOL",
    "WEAPON_SMG",
    "WEAPON_CARBINERIFLE"
}

local modelIndex = 1
local weaponIndex = 1

------------------------------------------------
-- MENU ROOT
------------------------------------------------

local root = menu.add_feature("Bodyguard Menu", "parent", 0)

------------------------------------------------
-- MODEL MENU
------------------------------------------------

local modelMenu = menu.add_feature("Model", "autoaction_value_str", root.id, function(f)

    modelIndex = f.value + 1
    print("Model selected: "..models[modelIndex])

end)

modelMenu:set_str_data(models)

------------------------------------------------
-- WEAPON MENU
------------------------------------------------

local weaponMenu = menu.add_feature("Weapon", "autoaction_value_str", root.id, function(f)

    weaponIndex = f.value + 1
    print("Weapon selected: "..weapons[weaponIndex])

end)

weaponMenu:set_str_data(weapons)

------------------------------------------------
-- SPAWN BODYGUARD
------------------------------------------------

menu.add_feature("Spawn Bodyguard", "action", root.id, function()

    local player = player.player_ped()

    local pos = entity.get_entity_coords(player)

    local model = gameplay.get_hash_key(models[modelIndex])

    streaming.request_model(model)

    while not streaming.has_model_loaded(model) do
        system.wait(0)
    end

    local ped = ped.create_ped(
        26,
        model,
        pos.x + math.random(-2,2),
        pos.y + math.random(-2,2),
        pos.z,
        0,
        true,
        true
    )

    weapon.give_delayed_weapon_to_ped(
        ped,
        gameplay.get_hash_key(weapons[weaponIndex]),
        999,
        true
    )

    table.insert(bodyguards,ped)

    print("[Bodyguard] Spawned")

end)

------------------------------------------------
-- DELETE ALL
------------------------------------------------

menu.add_feature("Delete Bodyguards", "action", root.id, function()

    for k,ped in pairs(bodyguards) do

        if entity.does_entity_exist(ped) then
            entity.delete_entity(ped)
        end

    end

    bodyguards = {}

    print("[Bodyguard] Deleted")

end)

print("[Bodyguard] Menu Ready")
