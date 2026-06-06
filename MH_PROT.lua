script_name('MH_PRO')
script_author('Moroz')
script_version('1.4.0')
script_version_number(140)
script_properties('work-in-pause')

local imgui    = require('mimgui')
local encoding = require('encoding')
local inicfg   = require('inicfg')
local sampev   = require('lib.samp.events')

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local MDS = MONET_DPI_SCALE or 1.0
local sw, sh = getScreenResolution()

-- ========= СОСТОЯНИЕ MH_PRO =========

local mh = {
    version  = "1.4.0",
    enabled  = true,
    logs     = {},
    teleport = {
        offsetAbove = {min = 2.5, max = 4.0}, -- высота "slap up"
    }
}

-- ========= ЛОГИ =========

local function addLog(text)
    local msg = string.format("[MH_PRO] %s", text)
    print(msg)
    if isSampAvailable() then
        sampAddChatMessage(u8("{00FFFF}[MH_PRO]{FFFFFF} " .. text), -1)
    end
    table.insert(mh.logs, msg)
    if #mh.logs > 200 then
        table.remove(mh.logs, 1)
    end
end

-- ========= ВСПОМОГАТЕЛЬНОЕ =========

local function randOffset(range)
    return range.min + math.random() * (range.max - range.min)
end

local function teleportAbove()
    local x, y, z = getCharCoordinates(PLAYER_PED)
    local offset  = randOffset(mh.teleport.offsetAbove)
    setCharCoordinates(PLAYER_PED, x, y, z + offset)
    addLog(string.format(u8("Телепорт над землёй на %.2f м"), offset))
end

-- ========= АВТО LOCK/KEY/ENGINE =========

function sampev.onSendEnterVehicle(id, pass)
    lua_thread.create(function()
        addLog(u8("Отправлен запрос входа в транспорт, id: ") .. tostring(id))
        while not isCharInAnyCar(PLAYER_PED) do wait(0) end
        wait(250)
        sampSendChat('/lock')
        addLog(u8("Авто /lock при входе"))
        wait(500)
        sampSendChat('/key')
        addLog(u8("Авто /key при входе"))
        wait(500)
        sampSendChat('/engine')
        addLog(u8("Авто /engine при входе"))
    end)
end

function sampev.onSendExitVehicle(id)
    lua_thread.create(function()
        addLog(u8("Отправлен запрос выхода из транспорта, id: ") .. tostring(id))
        local result, carHandle = sampGetCarHandleBySampVehicleId(id)
        if result then
            local doorStatus = getCarDoorLockStatus(carHandle)
            if doorStatus == 0 then
                sampSendChat('/lock')
                addLog(u8("Авто /lock при выходе (машина была открыта)"))
            else
                addLog(u8("Выход: машина уже была закрыта"))
            end
        else
            addLog(u8("Не удалось получить handle машины по id: ") .. tostring(id))
        end

        wait(500)
        if isCharInAnyCar(PLAYER_PED) then
            sampSendChat('/key')
            addLog(u8("Авто /key при выходе (ещё в машине)"))
        else
            addLog(u8("Выход: персонаж уже не в машине"))
        end
    end)
end

-- ========= КНОПКА SLAPUP (IMGUI) =========

local CFG = 'MH_PRO_btn.ini'
local ini = inicfg.load({
    btn = {
        x       = math.floor(sw * 0.40),
        y       = math.floor(sh * 0.70),
        visible = false,
        move    = false,
    }
}, CFG)
inicfg.save(ini, CFG)

local showBtn  = ini.btn.visible == true
local moveMode = ini.btn.move   == true
local posX     = ini.btn.x + 0.0
local posY     = ini.btn.y + 0.0

local cooldown   = false
local flashTime  = 0
local prevDragH  = 0
local prevDragV  = 0

local function saveBtnCfg()
    ini.btn.x       = math.floor(posX)
    ini.btn.y       = math.floor(posY)
    ini.btn.visible = showBtn
    ini.btn.move    = moveMode
    inicfg.save(ini, CFG)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)
end)

imgui.OnFrame(
    function() return showBtn end,
    function(self)
        self.HideCursor = false

        local BW      = 150 * MDS
        local BH      = 50  * MDS
        local MOVE_H  = moveMode and (40 * MDS) or 0
        local WIN_W   = BW
        local WIN_H   = BH + MOVE_H

        posX = math.max(0, math.min(sw - WIN_W, posX))
        posY = math.max(0, math.min(sh - WIN_H, posY))

        imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(WIN_W, WIN_H), imgui.Cond.Always)

        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0,0,0,0))
        imgui.PushStyleColor(imgui.Col.Border,   imgui.ImVec4(0,0,0,0))

        imgui.Begin('##mhpro_btn', nil,
            imgui.WindowFlags.NoTitleBar  +
            imgui.WindowFlags.NoResize    +
            imgui.WindowFlags.NoMove      +
            imgui.WindowFlags.NoScrollbar +
            imgui.WindowFlags.NoBackground)

        local dl = imgui.GetWindowDrawList()
        local wp = imgui.GetWindowPos()

        local elapsed = os.clock() - flashTime
        local isFlash = elapsed < 0.25
        local prog    = math.min(elapsed / 0.25, 1.0)

        -- фон
        dl:AddRectFilled(
            imgui.ImVec2(wp.x, wp.y),
            imgui.ImVec2(wp.x + WIN_W, wp.y + BH),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.06, 0.06, 0.06, 0.92)),
            10 * MDS)

        dl:AddRect(
            imgui.ImVec2(wp.x, wp.y),
            imgui.ImVec2(wp.x + WIN_W, wp.y + BH),
            imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 1.0, 1.0, 0.10)),
            10 * MDS, 0, 1 * MDS)

        if isFlash then
            local alpha = 0.25 * (1.0 - prog)
            dl:AddRectFilled(
                imgui.ImVec2(wp.x, wp.y),
                imgui.ImVec2(wp.x + WIN_W, wp.y + BH),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 0.82, 0.0, alpha)),
                10 * MDS)
        end

        if cooldown then
            local p    = math.min((os.clock() - flashTime) / 1.5, 1.0)
            local barW = WIN_W * (1.0 - p)
            dl:AddRectFilled(
                imgui.ImVec2(wp.x, wp.y + BH - 3*MDS),
                imgui.ImVec2(wp.x + barW, wp.y + BH - 1*MDS),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(1.0, 0.82, 0.0, 1.0)),
                1 * MDS)
        end

        imgui.GetStyle().FrameRounding   = 8 * MDS
        imgui.GetStyle().FrameBorderSize = 0

        imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0, 0, 0, 0))
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(1.0, 1.0, 1.0, 0.06))
        imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0, 0, 0, 0.3))
        imgui.PushStyleColor(imgui.Col.Text,          imgui.ImVec4(1.0, 1.0, 1.0, 1.0))
        imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)

        imgui.SetCursorPos(imgui.ImVec2(0, 0))
        local label = u8("SLAP UP")
        local clicked = imgui.Button(label, imgui.ImVec2(WIN_W, BH))
        imgui.PopStyleColor(4)

        if clicked and not cooldown then
            cooldown  = true
            flashTime = os.clock()
            teleportAbove()
            lua_thread.create(function()
                wait(1500)
                cooldown = false
            end)
        end

        -- режим перемещения
        if moveMode then
            imgui.PushStyleColor(imgui.Col.FrameBg,          imgui.ImVec4(0.15, 0.12, 0.0, 0.9))
            imgui.PushStyleColor(imgui.Col.FrameBgHovered,   imgui.ImVec4(0.22, 0.18, 0.0, 1.0))
            imgui.PushStyleColor(imgui.Col.FrameBgActive,    imgui.ImVec4(0.28, 0.22, 0.0, 1.0))
            imgui.PushStyleColor(imgui.Col.SliderGrab,       imgui.ImVec4(0.99, 0.84, 0.0, 1.0))
            imgui.PushStyleColor(imgui.Col.SliderGrabActive, imgui.ImVec4(1.0,  0.92, 0.2, 1.0))
            imgui.PushStyleColor(imgui.Col.Text,             imgui.ImVec4(0.99, 0.84, 0.0, 0.80))

            local PAD   = 8 * MDS
            local STABH = 20 * MDS
            local slW   = WIN_W - PAD * 2

            imgui.SetCursorPos(imgui.ImVec2(PAD, BH + 5*MDS))
            imgui.Text(u8("X"))
            imgui.SameLine()
            local hSP  = imgui.GetCursorScreenPos()
            local maxX = math.max(1, sw - WIN_W)
            dl:AddRectFilled(
                imgui.ImVec2(hSP.x, hSP.y),
                imgui.ImVec2(hSP.x + slW, hSP.y + STABH),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.15, 0.12, 0.0, 0.9)),
                6 * MDS)
            local hFrac  = math.max(0, math.min(1, posX / maxX))
            local hGrabW = 20 * MDS
            local hGrabX = hSP.x + hFrac * (slW - hGrabW)
            dl:AddRectFilled(
                imgui.ImVec2(hGrabX, hSP.y + 2*MDS),
                imgui.ImVec2(hGrabX + hGrabW, hSP.y + STABH - 2*MDS),
                imgui.ColorConvertFloat4ToU32(imgui.ImVec4(0.99, 0.84, 0.0, 1.0)),
                4 * MDS)
            imgui.SetCursorPos(imgui.ImVec2(PAD + 15*MDS, BH + 5*MDS))
            imgui.InvisibleButton('##mh_xdrag', imgui.ImVec2(slW, STABH))
            if imgui.IsItemActive() then
                local drag = imgui.GetMouseDragDelta(0, 0)
                local dx   = drag.x - prevDragH
                prevDragH  = drag.x
                posX = math.max(0, math.min(maxX, posX + dx))
                saveBtnCfg()
            else
                prevDragH = 0
            end

            local scrollV = imgui.new.int(math.floor(posY / math.max(1, sh - WIN_H) * 1000))
            imgui.SetCursorPos(imgui.ImVec2(PAD, BH + 5*MDS + STABH + 4*MDS))
            imgui.Text(u8("Y"))
            imgui.SameLine()
            imgui.SetNextItemWidth(slW)
            if imgui.SliderInt('##mh_vscroll', scrollV, 0, 1000, '') then
                local maxY = math.max(1, sh - WIN_H)
                posY = math.floor(scrollV[0] / 1000.0 * maxY)
                saveBtnCfg()
            end

            imgui.PopStyleColor(6)
        end

        imgui.End()
        imgui.PopStyleColor(2)
    end
)

-- ========= MAIN =========

function main()
    math.randomseed(os.time())

    while not isSampAvailable() do wait(100) end
    while not sampIsLocalPlayerSpawned() do wait(0) end

    sampAddChatMessage(u8("{00FFFF}[MH_PRO]{FFFFFF} скрипт загружен. Версия: " .. mh.version), -1)
    addLog(u8("Скрипт MH_PRO загружен. Версия: ") .. mh.version)

    -- /mhpro только для инфо
    sampRegisterChatCommand("mhpro", function()
        addLog("Версия: " .. mh.version .. ". Статус: " .. (mh.enabled and u8("включен") or u8("выключен")))
        sampAddChatMessage(
            u8("{00FFFF}[MH_PRO]{FFFFFF} /slapup - показать/скрыть кнопку SLAP UP"),
            -1
        )
    end)

    -- /slapup — показать/скрыть кнопку
    sampRegisterChatCommand("slapup", function()
        showBtn = not showBtn
        saveBtnCfg()
        sampAddChatMessage(
            u8("{00FFFF}[MH_PRO]{FFFFFF} Кнопка SLAP UP " ..
               (showBtn and "показана" or "скрыта")),
            -1
        )
        addLog(u8("Кнопка SLAP UP ") .. (showBtn and u8("включена") or u8("выключена")))
    end)

    -- Дополнительно: двойной тап по радару можно привязать, если нужно
    while true do
        -- если в будущем захочешь: проверка WIDGET_RADAR и т.п.
        wait(0)
    end
end
