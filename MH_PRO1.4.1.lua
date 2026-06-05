function mh.toggle()
    mh.enabled = not mh.enabled
    if mh.enabled then
        addLog("MH_PRO включён.")
    else
        addLog("MH_PRO выключен.")
    end
end

-- пример регистрации команды (зависит от твоего API)
-- если у тебя есть функция addCommandHandler:
addCommandHandler("mhpro", function()
    mh.toggle()
end)
-- MH_PRO 1.4.1 — Mobile Trilogy PRO
-- Автор: Moroz

local mh = {
    version = "1.4.1",
    enabled = true,
    ui = {
        theme = "neon",
        bgColor      = {0, 0, 0, 190},
        accentColor  = {0, 200, 255, 255},
        accentColor2 = {0, 255, 180, 255},
        textColor    = {255, 255, 255, 255},
    },
    tabs = {
        "Главная",
        "Логи",
        "Товары",
        "Hot Deals",
        "Телепорт",
        "Шахта",
        "Отладка"
    },
    currentTab = 1,
    logs = {},
    items = {},
    hotDeals = {},
    market = {
        enabled      = true,
        lastScanTime = 0,
        scanInterval = 5, -- сек
        pickupPos    = {x = 0, y = 0, z = 0}, -- координаты ЦР при необходимости
        shops        = {},
    },
    teleport = {
        offsetBelow = {min = 0.0, max = 5.0},
        offsetAbove = {min = 0.0, max = 5.0},
    },
    links = {
        telegram = "https://t.me/MobileTrilogyBot",
        github   = "https://github.com/YourUser/ArizonaTrilogyMobile"
    }
}

-- ========= УТИЛИТЫ =========

local function rgb(r, g, b, a)
    return {r, g, b, a or 255}
end

local function addLog(text)
    table.insert(mh.logs, os.date("[%H:%M:%S] ") .. text)
    if #mh.logs > 200 then
        table.remove(mh.logs, 1)
    end
end

-- ========= ОТРИСОВКА UI (ЗАГЛУШКИ ПОД ТВОЙ API) =========

function mh.drawNeonRect(x, y, w, h, color)
    -- Заменить на реальную функцию отрисовки прямоугольника
    -- пример: renderRectangle(x, y, w, h, color[1], color[2], color[3], color[4])
end

function mh.drawText(text, x, y, color, scale)
    -- Заменить на реальную функцию отрисовки текста
    -- пример: renderText(text, x, y, color[1], color[2], color[3], color[4], scale or 1.0)
end

-- ========= ТАБ-БАР =========

function mh.drawTabBar()
    local startX, startY = 50, 50
    local tabW, tabH     = 120, 30

    for i, name in ipairs(mh.tabs) do
        local col = (i == mh.currentTab) and mh.ui.accentColor or rgb(40, 40, 40, 200)
        mh.drawNeonRect(startX + (i - 1) * (tabW + 5), startY, tabW, tabH, col)
        mh.drawText(name, startX + (i - 1) * (tabW + 5) + 10, startY + 7, mh.ui.textColor, 0.9)
    end
end

-- ========= ЭКРАНЫ =========

function mh.drawMain()
    mh.drawText("MH_PRO 1.4 — Mobile Trilogy PRO", 60, 100, mh.ui.accentColor2, 1.0)
    mh.drawText("Статус: активен", 60, 130, mh.ui.textColor, 0.9)
end

function mh.drawLogs()
    local x, y = 60, 100
    for i = math.max(1, #mh.logs - 15), #mh.logs do
        mh.drawText(mh.logs[i], x, y, mh.ui.textColor, 0.8)
        y = y + 15
    end
end

function mh.drawItems()
    mh.drawText("Товары Центрального рынка", 60, 100, mh.ui.accentColor, 1.0)
    local x, y = 60, 130
    for _, item in ipairs(mh.items) do
        local line = string.format("%s — $%s (лавка: %s)", item.name, item.price, item.shop or "?")
        mh.drawText(line, x, y, mh.ui.textColor, 0.85)
        y = y + 15
    end
end

function mh.drawHotDeals()
    mh.drawText("Hot Deals (авто-поиск выгодных цен)", 60, 100, mh.ui.accentColor2, 1.0)
    local x, y = 60, 130
    if #mh.hotDeals == 0 then
        mh.drawText("Пока нет найденных горячих предложений.", x, y, mh.ui.textColor, 0.85)
        return
    end
    for _, deal in ipairs(mh.hotDeals) do
        local line = string.format("%s — $%s (ниже средней на %d%%)", deal.name, deal.price, deal.diff or 0)
        mh.drawText(line, x, y, mh.ui.textColor, 0.85)
        y = y + 15
    end
end

-- ========= ТЕЛЕПОРТ =========

local function getPlayerPos()
    -- Заменить на реальную функцию получения координат игрока
    return 0.0, 0.0, 0.0
end

local function setPlayerPos(x, y, z)
    -- Заменить на реальную функцию установки координат игрока
end

function mh.teleportBelow()
    local x, y, z = getPlayerPos()
    local offset  = mh.teleport.offsetBelow.min +
                    math.random() * (mh.teleport.offsetBelow.max - mh.teleport.offsetBelow.min)
    setPlayerPos(x, y, z - offset)
    addLog(string.format("Телепорт под землю: %.2f м", offset))
end

function mh.teleportAbove()
    local x, y, z = getPlayerPos()
    local offset  = mh.teleport.offsetAbove.min +
                    math.random() * (mh.teleport.offsetAbove.max - mh.teleport.offsetAbove.min)
    setPlayerPos(x, y, z + offset)
    addLog(string.format("Телепорт над землёй: %.2f м", offset))
end

function mh.drawTeleport()
    mh.drawText("Телепорт", 60, 100, mh.ui.accentColor, 1.0)
    mh.drawText("Под землёй (0–5 м)", 60, 130, mh.ui.textColor, 0.9)
    mh.drawText("Над землёй (0–5 м)", 60, 160, mh.ui.textColor, 0.9)
    -- здесь повесь обработку кликов:
    -- кнопка "Под землю" → mh.teleportBelow()
    -- кнопка "Над землю" → mh.teleportAbove()
end

-- ========= СКАНЕР ЦЕНТРАЛЬНОГО РЫНКА =========

function mh.parseMarketDialog(dialogText)
    mh.items = {}
    for line in dialogText:gmatch("[^\r\n]+") do
        -- пример строки: "Кейс Нового Сезона — $16,673,029"
        local name, price = line:match("(.+)%s+%-+%s+%$(%d[%d,]*)")
        if name and price then
            price = price:gsub(",", "")
            table.insert(mh.items, {
                name = name,
                price = tonumber(price) or 0,
                shop = "Центральный рынок"
            })
        end
    end
    addLog("Обновлены товары Центрального рынка (" .. #mh.items .. " позиций).")
end

function mh.scanMarket()
    -- Заменить на реальную функцию получения текста диалога
    -- например: local text = getCurrentDialogText()
    local text = ""
    if text ~= "" then
        mh.parseMarketDialog(text)
    end
end
