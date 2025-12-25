--[[
	System by @thehandofvoid
	Modified by @jay_peaceee
	RodShopConfig - 500K INCREMENTS (up to 25M)
	Smooth progression: 500K, 1M, 1.5M, 2M... up to 25M
--]]

local RodShopConfig = {
	-- TIER 1: Starter Rods (500K-3M) - Learn the game
	["Angelic Rod"] = {Type = "Currency", Value = 500000},       -- 500K
	["Lucky Rod"] = {Type = "Currency", Value = 1000000},        -- 1M
	["Gold Rod"] = {Type = "Currency", Value = 1500000},         -- 1.5M

	-- TIER 2: Mid-game Rods (2M-12M) - Can catch Legendary
	["Lightning"] = {Type = "Currency", Value = 2000000},        -- 2M
	["Polarized"] = {Type = "Currency", Value = 3000000},        -- 3M
	["Fluorescent Rod"] = {Type = "Currency", Value = 4000000},  -- 4M
	["GhostRod"] = {Type = "Currency", Value = 5500000},         -- 5.5M
	["Frozen Rod"] = {Type = "Currency", Value = 7000000},       -- 7M
	["LightingPunk Rod"] = {Type = "Currency", Value = 9000000}, -- 9M
	["Pirate Octopus"] = {Type = "Currency", Value = 11000000},  -- 11M
	["Aqua Prism"] = {Type = "Currency", Value = 13000000},      -- 13M

	-- TIER 3: End-game Rods (15M-25M) - Can catch Unknown
	["Earthly"] = {Type = "Currency", Value = 15000000},         -- 15M
	["Manifest"] = {Type = "Currency", Value = 18000000},        -- 18M
	["Megalofriend"] = {Type = "Currency", Value = 21000000},    -- 21M
	["Purple Saber"] = {Type = "Currency", Value = 25000000},    -- 25M (MAX)

	-- GAMEPASS RODS (Robux) - Best in game
	["Flery"] = {Type = "Gamepass", Value = 1586604376},
	["Loving"] = {Type = "Gamepass", Value = 1586498444},
	["Crystalized"] = {Type = "Gamepass", Value = 1585342091},
	["ZombieRod"] = {Type = "Gamepass", Value = 1585390168},
	["Forsaken"] = {Type = "Gamepass", Value = 1585392073},
	["Katanaa"] = {Type = "Gamepass", Value = 1591443656},
	["Umbrella"] = {Type = "Gamepass", Value = 1591443656},

	-- ADMIN RODS (Not for sale)
	["Admin Rod"] = {Type = "None"},
	["Developer Rod"] = {Type = "None"},
	["Owner Rod"] = {Type = "None"},
}

return RodShopConfig