script_name('Quick Menu PRO')
script_author('Arizona Trilogy')
script_description('Advanced radial menu for Arizona RP Mobile')
script_version('2.0-pro')
script_properties('work-in-pause')

local imgui = require('mimgui')
local encoding = require('encoding')
local ffi = require('ffi')

encoding.default = 'CP1251'
local u8 = encoding.UTF8
local MDS = MONET_DPI_SCALE or 1.0
local sw, sh = getScreenResolution()

-- Telegram links
local AUTHOR_TG  = 'https://t.me/momoblank27'
local CHANNEL_TG = 'https://t.me/ArizonaTrilogy'

local mainWindow = imgui.new.bool(false)

local function openLink(url)
    pcall(function()
        local gta = ffi.load('GTASA')
        ffi.cdef([[ void _Z12AND_OpenLinkPKc(const char* link); ]])
        gta._Z12AND_OpenLinkPKc(url)
    end)
end

imgui.OnInitialize(function()
    imgui.SwitchContext()
    local io = imgui.GetIO()
    io.IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)
end)

imgui.OnFrame(
    function() return mainWindow[0] end,
    function(self)
        self.HideCursor = false
        
        imgui.SetNextWindowPos(imgui.ImVec2(sw*0.5, sh*0.5), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(500*MDS, 350*MDS), imgui.Cond.Always)
        
        if imgui.Begin(u8('ARIZONA TRILOGY'), mainWindow, imgui.WindowFlags.NoCollapse) then
            imgui.Spacing()
            imgui.Text(u8('╔════════════════════════════════════╗'))
            imgui.Text(u8('║     Добро пожаловать в меню!     ║'))
            imgui.Text(u8('╚════════════════════════════════════╝'))
            imgui.Spacing()
            
            imgui.Text(u8('📱 Версия: 2.0 PRO'))
            imgui.Text(u8('👤 Автор: Arizona Trilogy'))
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            
            if imgui.Button(u8('📢 Канал: @ArizonaTrilogy'), imgui.ImVec2(-1, 35*MDS)) then
                openLink(CHANNEL_TG)
            end
            
            imgui.Spacing()
            
            if imgui.Button(u8('👤 Автор: @momoblank27'), imgui.ImVec2(-1, 35*MDS)) then
                openLink(AUTHOR_TG)
            end
            
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            
            imgui.TextColored(imgui.ImVec4(0.2, 0.8, 1.0, 1.0), u8('✓ Меню успешно загружено!'))
            
            imgui.End()
        end
    end
)

function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(200) end
    
    sampRegisterChatCommand('menu', function()
        mainWindow[0] = not mainWindow[0]
    end)
    
    sampAddChatMessage('{00FF00}[Menu PRO] {FFFFFF}Загружено! Команда: {FFD700}/menu', -1)
    sampAddChatMessage('{696969}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', -1)
    sampAddChatMessage('{00AAFF}Канал: {FFFFFF}@ArizonaTrilogy', -1)
    sampAddChatMessage('{696969}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', -1)
    
    while true do wait(0) end
end

main()
