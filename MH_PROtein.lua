script_name('MH_PROtein')
script_author('Moroz')
script_version('1.0.0')
script_version_number(100)
script_properties('work-in-pause')

local imgui    = require('mimgui')
local inicfg   = require('inicfg')
local sampev   = require('lib.samp.events')

local MDS = MONET_DPI_SCALE or 1.0
local sw, sh = getScreenResolution()

-- ================== СОСТОЯНИЕ ==================

local state = {
    version   = "1.0.0",
    showMenu  = false,
    showSlap  = false,
    showFast  = false,
    activeTab = "UP",
    logs      = {},
}

local function addLog(text)
    print("[MH_PROtein] " .. text)
    if isSampAvailable() then
        sampAddChatMessage("{00FFFF}[MH_PROtein]{FFFFFF} " .. text, -1)
    end
    table.insert(state.logs, os.date("[%H:%M:%S] ") .. text)
    if #state.logs > 200 then table.remove(state.logs, 1) end
end

-- ================== ДЕЙСТВИЯ ==================

local function slapUp()
    if not doesCharExist(PLAYER_PED) then return end
    local x, y, z = getCharCoordinates(PLAYER_PED)
    setCharCoordinates(PLAYER_PED, x, y, z + 3.2)
    addLog("SLAP UP")
end

local function slapDown()
    if not doesCharExist(PLAYER_PED) then return end
    local x, y, z = getCharCoordinates(PLAYER_PED)
    setCharCoordinates(PLAYER_PED, x, y, z - 3.2)
    addLog("SLAP DOWN")
end

local function doFastAnim()
    sampSendChat("/anims 1")
    addLog("FASTANIM /anims 1")
end

local function doLock()
    sampSendChat("/lock")
    addLog("AUTO LOCK")
end

local function doKey()
    sampSendChat("/key")
    addLog("AUTO KEY")
end

local function doEngine()
    sampSendChat("/engine")
    addLog("AUTO ENGINE")
end

-- ================== АВТО LOCK/KEY/ENGINE ==================

function sampev.onSendEnterVehicle(id, pass)
    lua_thread.create(function()
        addLog("Вход в транспорт")
        while not isCharInAnyCar(PLAYER_PED) do wait(0) end
        wait(250)
        doLock()
        wait(250)
        doKey()
        wait(250)
        doEngine()
    end)
end

function sampev.onSendExitVehicle(id)
    lua_thread.create(function()
        addLog("Выход из транспорта")
        local ok, car = sampGetCarHandleBySampVehicleId(id)
        if ok then
            if getCarDoorLockStatus(car) == 0 then
                doLock()
            end
        end
    end)
end

-- ================== КНОПКИ SLAP UP / FASTANIM ==================

local CFG_BTN = 'MH_PROtein_btn.ini'
local iniBtn = inicfg.load({
    slap = { x = sw*0.40, y = sh*0.70, visible = false, move = false },
    fast = { x = sw*0.40, y = sh*0.60, visible = false, move = false },
}, CFG_BTN)
inicfg.save(iniBtn, CFG_BTN)

state.showSlap = iniBtn.slap.visible
state.showFast = iniBtn.fast.visible

local slapX, slapY = iniBtn.slap.x, iniBtn.slap.y
local fastX, fastY = iniBtn.fast.x, iniBtn.fast.y

local slapMove = iniBtn.slap.move
local fastMove = iniBtn.fast.move

local prevDrag = 0

local function saveBtnCfg()
    iniBtn.slap.x = slapX
    iniBtn.slap.y = slapY
    iniBtn.slap.visible = state.showSlap
    iniBtn.slap.move = slapMove

    iniBtn.fast.x = fastX
    iniBtn.fast.y = fastY
    iniBtn.fast.visible = state.showFast
    iniBtn.fast.move = fastMove

    inicfg.save(iniBtn, CFG_BTN)
end

-- ================== ИНИЦ ИМГУИ ==================

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)
end)

-- ================== ЛЕВАЯ КОЛОНКА ==================

local function drawLeftTabs()
    local tabs = {
        {id="UP",  label="UP"},
        {id="DN",  label="DN"},
        {id="FA",  label="FA"},
        {id="AU",  label="AUTO"},
        {id="TP",  label="TP"},
        {id="FM",  label="FARM"},
        {id="ST",  label="SET"},
        {id="LG",  label="LOG"},
    }

    for _, t in ipairs(tabs) do
        if state.activeTab == t.id then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.2,0.6,1,1))
        else
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.1,0.1,0.1,1))
        end

        if imgui.Button(t.label, imgui.ImVec2(80*MDS, 32*MDS)) then
            state.activeTab = t.id
        end

        imgui.PopStyleColor()
    end
end

-- ================== ПРАВАЯ ПАНЕЛЬ ==================

local function drawRightPanel()
    imgui.BeginChild("##right", imgui.ImVec2(0,0), true)

    if state.activeTab == "UP" then
        imgui.Text("SLAP UP")
        if imgui.Button("SLAP UP", imgui.ImVec2(150,35)) then slapUp() end

    elseif state.activeTab == "DN" then
        imgui.Text("SLAP DOWN")
        if imgui.Button("SLAP DOWN", imgui.ImVec2(150,35)) then slapDown() end

    elseif state.activeTab == "FA" then
        imgui.Text("FASTANIM")
        if imgui.Button("FASTANIM /anims 1", imgui.ImVec2(200,35)) then doFastAnim() end

    elseif state.activeTab == "AU" then
        imgui.Text("AUTO LOCK/KEY/ENGINE")
        if imgui.Button("LOCK", imgui.ImVec2(100,30)) then doLock() end
        imgui.SameLine()
        if imgui.Button("KEY", imgui.ImVec2(100,30)) then doKey() end
        imgui.SameLine()
        if imgui.Button("ENGINE", imgui.ImVec2(100,30)) then doEngine() end

    elseif state.activeTab == "TP" then
        imgui.Text("TELEPORT — позже добавим HAC движение")

    elseif state.activeTab == "FM" then
        imgui.Text("FARM BOT — позже добавим авто‑движение по кустам")

    elseif state.activeTab == "ST" then
        imgui.Text("SETTINGS")

        local slapPtr = imgui.new.bool(state.showSlap)
        if imgui.Checkbox("Показывать кнопку SLAP UP", slapPtr) then
            state.showSlap = slapPtr[0]
            saveBtnCfg()
        end

        local fastPtr = imgui.new.bool(state.showFast)
        if imgui.Checkbox("Показывать кнопку FASTANIM", fastPtr) then
            state.showFast = fastPtr[0]
            saveBtnCfg()
        end

    elseif state.activeTab == "LG" then
        imgui.Text("LOGS")
        imgui.Separator()
        imgui.BeginChild("##logs", imgui.ImVec2(0,0), true)
        for _, line in ipairs(state.logs) do imgui.Text(line) end
        imgui.EndChild()
    end

    imgui.EndChild()
end
