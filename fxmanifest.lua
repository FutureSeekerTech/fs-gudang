fx_version 'adamant'
game 'gta5'
author 'FutureSeekerTech'
description 'Advanced Gudang System'
lua54 'yes'
shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
}

client_scripts {
    'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua'
}



