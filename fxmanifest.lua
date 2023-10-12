fx_version 'cerulean'
game 'gta5'

author 'AlexBanPer'
description 'A hologram API script for FiveM'
version '1.0.0'

lua54 'yes'

files {
	'data/handling.meta',
	'data/vehicles.meta',
	'data/carvariations.meta',
	'ui/**/*.*',
	'ui/*.*',
    'ui/pages/**/**.*',
}

shared_scripts {
	'@ox_lib/init.lua',
	'shared/config.lua',
}

client_scripts {
	'client/utils.lua',
	'client/editor.lua',
	'client/client.lua',
}

server_scripts {
	'server/server.lua',
}

data_file 'HANDLING_FILE' 'data/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
