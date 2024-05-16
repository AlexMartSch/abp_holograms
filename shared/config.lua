Config = {}
--- DONT TOUCH THIS
Config.__HologramsObjects = {}

--[[

           ____  _____        _____                 _                                  _       
     /\   |  _ \|  __ \      |  __ \               | |                                | |      
    /  \  | |_) | |__) |_____| |  | | _____   _____| | ___  _ __  _ __ ___   ___ _ __ | |_ ___ 
   / /\ \ |  _ <|  ___/______| |  | |/ _ \ \ / / _ \ |/ _ \| '_ \| '_ ` _ \ / _ \ '_ \| __/ __|
  / ____ \| |_) | |          | |__| |  __/\ V /  __/ | (_) | |_) | | | | | |  __/ | | | |_\__ \
 /_/    \_\____/|_|          |_____/ \___| \_/ \___|_|\___/| .__/|_| |_| |_|\___|_| |_|\__|___/
                                                           | |                                 
                                                           |_|                                 

    Supported version Octuber 2023
    Support Discord: https://discord.gg/NQFSD6t9hQ

]]

-- Enable/Disable debug mode
Config.DebugMode = true

-- Save algorithm with 'json' or 'kvp' methods
Config.SaveAlgorithm = 'json'

-- Maximum GFX Loaded
Config.MaxGFX = 6

-- Hologram default properties
Config.Holograms = {
	['mainmenulogo'] = {
		enabled = true,
		htmlTarget = "mainmenulogo",
		attachTo = 'world',
		type = 'hologram-marker',
		typeProperties = {
			---- MARKER PROPERTIES
			rotation = vector3(90.0, 0.0, 0.0), -- vertical, horizontal
			scale = vector3(4.5, 4.5, 4.5),
			rotate = false,
			cameraFollow = false,
			bobUpAndDown = false,
		},
		position = vector3(405.2, -949.5, -98.9),
		distanceView = 100,
		scale = vec2(1024, 1024)
	},


	-- ['playerinfo'] = {
	-- 	enabled = true,
	-- 	htmlTarget = "playerinfo",
	-- 	attachTo = 'player',
	-- 	typeProperties = {
	-- 		---- PLAYER PROPERTIES
	-- 		attachmentOffset = vec3(0.8, 1.5, 0.75),
	-- 		attachmentRotatio = vec3(6.5, -0.5, 0.85)
	-- 	},
	-- 	scale = vec2(1256, 1500),
	-- 	visible = true,
	-- },
}