fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'PRP Busking'
author 'BevanDooooo'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    '@ox_lib/init.lua', 
    'client.lua'
}
server_script 'server.lua'
