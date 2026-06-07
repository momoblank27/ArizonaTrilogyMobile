script_name('Mine Tools')
script_author('Telek Moroz')
script_description('special edition - MonetLoader Android')
script_version('1.0-monet')
script_properties('work-in-pause')
require('lib.samp.events')
local imgui   = require('mimgui')
local ffi     = require('ffi')
local enc     = require('encoding')
enc.default   = 'CP1251'
local u8      = enc.UTF8
local inicfg  = require('inicfg')
local jsoncfg = require('jsoncfg')
local requests= require('requests')
local lfs     = require('lfs')
local sampev  = require('lib.samp.events')
local mem     = require('memory')
local MDS = MONET_DPI_SCALE
local new = imgui.new

-- Telegram links
local AUTHOR_TG  = 'https://t.me/momoblank27'
local CHANNEL_TG = 'https://t.me/ArizonaTrilogy'

-- Auto-run features
local autoRunToOre     = new.bool(false)
local autoRunDistance  = new.int(200)
local autoRunTimerSec  = new.int(3)
local autoRunActive    = false
local autoRunTarget    = nil

-- Path recording features
local pathRecording    = new.bool(false)
local pathPlayback     = new.bool(false)
local recordedPath     = {}
local currentPathPoint = 0
local pathPlaybackLoop = new.bool(true)
local pathPauseTime    = new.int(1000)
local pathPlaybackSpeed= new.float(1.0)
local recordingPoints  = 0
local playbackActive   = false
local savedPaths       = {}

local function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(200) end
    
    sampAddChatMessage('{696969}[{DCDCDC}MineTools{696969}]: {00FF00}✓ Скрипт загружен!', -1)
    sampAddChatMessage('{696969}[{DCDCDC}MineTools{696969}]: {FFD700}Канал: {00AAFF}@ArizonaTrilogy', -1)
    
    while true do
        wait(0)
    end
end

main()
