-- MH_PRO 1.4 — Mobile Trilogy PRO
-- Автор: Moroz

local mh = {
    version    = "1.4.0",
    enabled    = false,
    logs       = {},
    teleport = {
        offsetBelow = {min = 0.0, max = 5.0},
        offsetAbove = {min = 0.0, max = 5.0},
    }
}

-- ========= УТИЛИТЫ =========

local function addLog(text)
    local msg = string.format("[MH_PRO] %s", text)
    print(msg)
    if isSampAvailable() then
        sampAddChatMessage("{00FFFF}[MH_PRO]{FFFFFF} " .. text, -1)
    end
    table.insert(mh.logs, msg)
    if #mh.logs > 100 then
        table.remove(mh.logs, 1)
    end
end

local function randOffset(range)
    return range.min + math.random() * (range.max - range.min)
end

-- ========= ТЕЛЕПОРТ =========

local function teleportBelow()
    local x, y, z = getCharCoordinates(PLAYER_PED)
    local offset  = randOffset(mh.teleport.offsetBelow)
    setCharCoordinates(PLAYER_PED, x, y, z - offset)
    addLog(string.format("Телепорт под землю на %.2f м", offset))
end

local function teleportAbove()
    local x, y, z = getCharCoordinates(PLAYER_PED)
    local offset  = randOffset(mh.teleport.offsetAbove)
    setCharCoordinates(PLAYER_PED, x, y, z + offset)
    addLog(string.format("Телепорт над землёй на %.2f м", offset))
end

-- ========= ОБРАБОТКА КОМАНД =========

local function cmd_mhpro()
    mh.enabled = not mh.enabled

    if mh.enabled then
        addLog("Меню MH_PRO включено. Доступны подкоманды: /mhpro up, /mhpro down, /mhpro info")
    else
        addLog("Меню MH_PRO выключено.")
    end
end

local function cmd_mhpro_arg(arg)
    arg = arg or ""
    arg = arg:lower()

    if arg == "" then
        cmd_mhpro()
        return
    end

    if arg == "up" then
        teleportAbove()
    elseif arg == "down" then
        teleportBelow()
    elseif arg == "info" then
        addLog("Версия: " .. mh.version .. ". Автор: Moroz. Статус: " .. (mh.enabled and "включен" or "выключен"))
    else
        addLog("Неизвестная подкоманда. Используй: /mhpro, /mhpro up, /mhpro down, /mhpro info")
    end
end

-- ========= MAIN =========

function main()
    math.randomseed(os.time())

    while not isSampAvailable() do
        wait(0)
    end

    -- Приветствие при загрузке скрипта
    sampAddChatMessage("{00FFFF}[MH_PRO]{FFFFFF} скрипт загружен. Используй /mhpro для управления.", -1)
    addLog("Скрипт MH_PRO загружен. Версия: " .. mh.version)

    -- Регистрация команды /mhpro
    sampRegisterChatCommand("mhpro", function(param)
        if param and param ~= "" then
            cmd_mhpro_arg(param)
        else
            cmd_mhpro()
        end
    end)

    -- Основной цикл (пока без сложного UI)
    while true do
        wait(0)
        -- сюда позже можно добавить рендер меню, автообновление и т.п.
    end
end
