script_name('MH_PROW')
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
    activeTab = "UP", -- UP, DN, FA, AU, TP, FM, ST, LG
    logs      = {},
}

local function addLog(text)
    print("[MH_PROW] " .. text)
    if isSampAvailable() then
        sampAddChatMessage("{00FFFF}[MH_PROW]{FFFFFF} " .. text, -1)
    end
    table.insert(state.logs, os.date("[%H:%M:%S] ") .. text)
    if #state.logs > 200 then table.remove(state.logs, 1) end
end

-- ================== ТЕЛЕПОРТЫ / ДЕЙСТВИЯ ==================

local function slapUp()
    if not doesCharExist(PLAYER_PED) then return end
    local x, y, z = getCharCoordinates(PLAYER_PED)
    local offset  = 3.2
    setCharCoordinates(PLAYER_PED, x, y, z + offset)
    addLog(string.format("SLAP UP: +%.2f м", offset))
end

local function slapDown()
    if not doesCharExist(PLAYER_PED) then return end
    local x, y, z = getCharCoordinates(PLAYER_PED)
    local offset  = 3.2
    setCharCoordinates(PLAYER_PED, x, y, z - offset)
    addLog(string.format("SLAP DOWN: -%.2f м", offset))
end

local function doFastAnim()
    sampSendChat("/anims 1")
    addLog("FASTANIM: /anims 1")
end

local function doLock()
    sampSendChat("/lock")
    addLog("AUTO: /lock")
end

local function doKey()
    sampSendChat("/key")
    addLog("AUTO: /key")
end

local function doEngine()
    sampSendChat("/engine")
    addLog("AUTO: /engine")
end

-- ================== АВТО LOCK/KEY/ENGINE ==================

function sampev.onSendEnterVehicle(id, pass)
    lua_thread.create(function()
        addLog("Вход в транспорт, id: " .. tostring(id))
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
        addLog("Выход из транспорта, id: " .. tostring(id))
        local ok, car = sampGetCarHandleBySampVehicleId(id)
        if ok then
            local door = getCarDoorLockStatus(car)
            if door == 0 then
                doLock()
            else
                addLog("Машина уже была закрыта")
            end
        end
    end)
end

-- ================== КНОПКА SLAP UP ==================

local CFG_BTN = 'MH_PROW_btn.ini'
local iniBtn = inicfg.load({
    btn = {
        x       = math.floor(sw * 0.40),
        y       = math.floor(sh * 0.70),
        visible = false,
        move    = false,
    }
}, CFG_BTN)
inicfg.save(iniBtn, CFG_BTN)

state.showSlap      = iniBtn.btn.visible == true
local slapMoveMode  = iniBtn.btn.move   == true
local slapX         = iniBtn.btn.x + 0.0
local slapY         = iniBtn.btn.y + 0.0
local prevDragH     = 0

local function saveSlapCfg()
    iniBtn.btn.x       = math.floor(slapX)
    iniBtn.btn.y       = math.floor(slapY)
    iniBtn.btn.visible = state.showSlap
    iniBtn.btn.move    = slapMoveMode
    inicfg.save(iniBtn, CFG_BTN)
end

-- ================== ИМГУИ ИНИЦ ==================

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)
end)

-- ================== ГЛАВНОЕ МЕНЮ ==================

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

    for i, t in ipairs(tabs) do
        if state.activeTab == t.id then
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.20, 0.60, 1.0, 0.90))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.20, 0.60, 1.0, 1.00))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.15, 0.50, 0.90, 1.00))
        else
            imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.10, 0.10, 0.10, 0.90))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.20, 0.20, 0.20, 0.90))
            imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.25, 0.25, 0.25, 0.90))
        end

        if imgui.Button(t.label, imgui.ImVec2(80 * MDS, 32 * MDS)) then
            state.activeTab = t.id
        end
        imgui.PopStyleColor(3)
    end
end

local function drawRightPanel()
    imgui.BeginChild("##mhprow_right", imgui.ImVec2(0, 0), true)

    if state.activeTab == "UP" then
        imgui.Text("SLAP UP")
        if imgui.Button("SLAP UP", imgui.ImVec2(150 * MDS, 35 * MDS)) then
            slapUp()
        end

    elseif state.activeTab == "DN" then
        imgui.Text("SLAP DOWN")
        if imgui.Button("SLAP DOWN", imgui.ImVec2(150 * MDS, 35 * MDS)) then
            slapDown()
        end

    elseif state.activeTab == "FA" then
        imgui.Text("FASTANIM")
        if imgui.Button("FASTANIM /anims 1", imgui.ImVec2(200 * MDS, 35 * MDS)) then
            doFastAnim()
        end

    elseif state.activeTab == "AU" then
        imgui.Text("AUTO LOCK/KEY/ENGINE")
        if imgui.Button("LOCK", imgui.ImVec2(100 * MDS, 30 * MDS)) then doLock() end
        imgui.SameLine()
        if imgui.Button("KEY", imgui.ImVec2(100 * MDS, 30 * MDS)) then doKey() end
        imgui.SameLine()
        if imgui.Button("ENGINE", imgui.ImVec2(100 * MDS, 30 * MDS)) then doEngine() end
        imgui.Separator()
        imgui.Text("Авто-режим уже включен через события входа/выхода из авто.")

    elseif state.activeTab == "TP" then
        imgui.Text("TELEPORT (пока только SLAP UP/DOWN)")
        imgui.Text("Можно позже добавить точки, метки и т.п.")

    elseif state.activeTab == "FM" then
        imgui.Text("FARM (лен/хлопок)")
        imgui.Text("Здесь позже можно реализовать авто-движение по кустам.")
        imgui.Text("Сейчас только заготовка под логику бота.")

    elseif state.activeTab == "ST" then
        imgui.Text("SETTINGS")
        local show = state.showSlap
        if imgui.Checkbox("Показывать кнопку SLAP UP на экране", show) then
            state.showSlap = not state.showSlap
            saveSlapCfg()
        end

    elseif state.activeTab == "LG" then
        imgui.Text("LOGS")
        imgui.Separator()
        imgui.BeginChild("##mhprow_logs", imgui.ImVec2(0, 0), true)
        for i, line in ipairs(state.logs) do
            imgui.Text(line)
        end
        imgui.EndChild()
    end

    imgui.EndChild()
end

imgui.OnFrame(
    function() return state.showMenu end,
    function()
        local winW = 600 * MDS
        local winH = 350 * MDS
        imgui.SetNextWindowSize(imgui.ImVec2(winW, winH), imgui.Cond.FirstUseEver)
        imgui.Begin("MH_PROW", nil,
            imgui.WindowFlags.NoCollapse +
            imgui.WindowFlags.NoScrollbar)

        imgui.Columns(2, "mhprow_cols", false)
        imgui.SetColumnWidth(0, 90 * MDS)

        drawLeftTabs()
        imgui.NextColumn()
        drawRightPanel()

        imgui.End()
    end
)

-- ================== ОТДЕЛЬНАЯ КНОПКА SLAP UP ==================

imgui.OnFrame(
    function() return state.showSlap end,
    function()
        local BW = 140 * MDS
        local BH = 45  * MDS

        slapX = math.max(0, math.min(sw - BW, slapX))
        slapY = math.max(0, math.min(sh - BH, slapY))

        imgui.SetNextWindowPos(imgui.ImVec2(slapX, slapY), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(BW, BH + (slapMoveMode and 40*MDS or 0)), imgui.Cond.Always)

        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.Border,   imgui.ImVec4(0,0,0,0))

        imgui.Begin("##mhprow_slapbtn", nil,
            imgui.WindowFlags.NoTitleBar  +
            imgui.WindowFlags.NoResize    +
            imgui.WindowFlags.NoMove      +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoBackground)

        local dl = imgui.GetWindowDrawList()
        local wp = imgui.GetWindowPos()

        dl:AddRectFilled(
            imgui.ImVec2(wp.x, wp.y),
            imgui.ImVec2(wp.x + BW, wp.y + BH),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.06, 0.06, 0.06, 0.92)),
            10 * MDS)

        dl:AddRect(
            imgui.ImVec2(wp.x, wp.y),
            imgui.ImVec2(wp.x + BW, wp.y + BH),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 1.0, 1.0, 0.10)),
            10 * MDS, 0, 1 * MDS)

        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.0, 1.0, 1.0, 0.06))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0, 0, 0, 0.3))
        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
        imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

        imgui.SetCursorPos(imgui.ImVec2(0, 0))
        if imgui.Button("SLAP UP", imgui.ImVec2(BW, BH)) then
            slapUp()
        end
        imgui.PopStyleColor(4)

        if slapMoveMode then
            local PAD   = 8 * MDS
            local STABH = 20 * MDS
            local slW   = BW - PAD * 2

            imgui.SetCursorPos(imgui.ImVec2(PAD, BH + 5*MDS))
            imgui.Text("X")
            imgui.SameLine()
            local hSP  = imgui.GetCursorScreenPos()
            local maxX = math.max(1, sw - BW)
            dl:AddRectFilled(
                imgui.ImVec2(hSP.x, hSP.y),
                imgui.ImVec2(hSP.x + slW, hSP.y + STABH),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.15, 0.12, 0.0, 0.9)),
                6 * MDS)
            local hFrac  = math.max(0, math.min(1, slapX / maxX))
            local hGrabW = 20 * MDS
            local hGrabX = hSP.x + hFrac * (slW - hGrabW)
            dl:AddRectFilled(
                imgui.ImVec2(hGrabX, hSP.y + 2*MDS),
                imgui.ImVec2(hGrabX + hGrabW, hSP.y + STABH - 2*MDS),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.99, 0.84, 0.0, 1.0)),
                4 * MDS)
            imgui.SetCursorPos(imgui.ImVec2(PAD + 15*MDS, BH + 5*MDS))
            imgui.InvisibleButton("##mhprow_xdrag", imgui.ImVec2(slW, STABH))
            if imgui.IsItemActive() then
                local drag = imgui.GetMouseDragDelta(0, 0)
                local dx   = drag.x - prevDragH
                prevDragH  = drag.x
                slapX = math.max(0, math.min(maxX, slapX + dx))
                saveSlapCfg()
            else
                prevDragH = 0
            end
        end

        imgui.End()
        imgui.PopStyleColor(2)
    end
)

-- ================== MAIN ==================

function main()
    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(0) end

    addLog("Скрипт MH_PROW загружен. Версия: " .. state.version)
    sampAddChatMessage("{00FFFF}[MH_PROW]{FFFFFF} /mhmenu - меню, /slapup - кнопка SLAP UP, /mhlog - логи", -1)

    sampRegisterChatCommand("mhmenu", function()
        state.showMenu = not state.showMenu
    end)

    sampRegisterChatCommand("slapup", function()
        state.showSlap = not state.showSlap
        saveSlapCfg()
        addLog("Кнопка SLAP UP: " .. (state.showSlap and "включена" or "выключена"))
    end)

    sampRegisterChatCommand("mhlog", function()
        state.activeTab = "LG"
        state.showMenu  = true
    end)

    while true do
        wait(0)
    end
end
