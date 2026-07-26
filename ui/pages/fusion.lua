--================================================--
-- GEN'S Nuclear Control
-- UI Page : Fusion Reactor
-- Version : 0.1.0
--================================================--

local FusionPage = {}
local PAGE_COLOR = colors.cyan

local function tankOrEmpty(tank)
    if type(tank) == "table" then return tank end
    return { amount = 0, capacity = 0, percentage = 0 }
end

local function drawButton(monitor, Layout, x, y, width, text, color)
    Layout.writeAt(monitor, x, y, string.rep(" ", width), colors.black, color)
    text = Layout.truncate(text, width)
    local textX = x + math.max(math.floor((width - #text) / 2), 0)
    Layout.writeAt(monitor, textX, y, text, colors.black, color)
end

-- Redraw the complete title strip. This prevents stale characters from
-- appearing at panel junctions on large multi-block monitors.
local function drawPanel(monitor, Layout, cell, title, borderColor)
    borderColor = borderColor or PAGE_COLOR

    Layout.panel(
        monitor,
        cell.x,
        cell.y,
        cell.width,
        cell.height,
        title,
        borderColor
    )

    if cell.width > 2 then
        Layout.writeAt(
            monitor,
            cell.x + 1,
            cell.y,
            string.rep(" ", cell.width - 2),
            colors.black,
            borderColor
        )

        Layout.writeAt(
            monitor,
            cell.x + 2,
            cell.y,
            Layout.truncate(" " .. title .. " ", cell.width - 4),
            colors.black,
            borderColor
        )
    end
end

local function drawTank(monitor, Layout, cell, title, tank)
    tank = tankOrEmpty(tank)
    drawPanel(monitor, Layout, cell, title)

    local x = cell.x + 2
    local y = cell.y + 2
    local width = math.max(cell.width - 4, 1)
    local percentage = tank.percentage or 0

    Layout.labelValue(monitor, x, y, width, "Filled", Layout.formatPercent(percentage))
    Layout.labelValue(monitor, x, y + 1, width, "Amount", Layout.formatNumber(tank.amount, 1))
    Layout.labelValue(monitor, x, y + 2, width, "Capacity", Layout.formatNumber(tank.capacity, 1))

    if cell.height >= 7 then
        local color = Layout.theme.safe
        if percentage <= 0.10 then
            color = Layout.theme.emergency
        elseif percentage <= 0.25 then
            color = Layout.theme.warning
        end

        Layout.progressBar(monitor, x, y + 4, width, percentage, {
            filledColor = color
        })
    end
end

local function drawOffline(monitor, Layout, width, height)
    Layout.panel(
        monitor, 2, 6,
        math.max(width - 2, 2),
        math.max(height - 7, 3),
        "FUSION REACTOR",
        Layout.theme.emergency
    )
    Layout.writeAt(
        monitor, 4, 8,
        "Fusion reactor peripheral unavailable",
        Layout.theme.emergency
    )
end

function FusionPage.draw(context)
    if type(context) ~= "table" then error("Fusion page context required") end

    local monitor = context.monitor
    local Layout = context.layout
    local navigation = context.navigation

    if not monitor or not Layout or not navigation then
        error("Incomplete Fusion page context")
    end

    local state = context.cache and context.cache:get("fusion")
    if not state and context.devices and context.devices.fusion then
        state = context.devices.fusion:getState()
    end

    local width, height = monitor.getSize()
    navigation:clearRegions("fusion")
    Layout.clear(monitor)
    Layout.header(monitor, "GEN'S NUCLEAR CONTROL", "FUSION REACTOR")

    local backWidth = math.min(12, width)
    local backX = 1
    local backY = height
    drawButton(monitor, Layout, backX, backY, backWidth, "< BACK", PAGE_COLOR)
    navigation:registerBackButton(backX, backY, backWidth, 1, {
        id = "fusion_back",
        page = "fusion",
        monitorName = context.monitorName,
        priority = 100
    })

    if not state or not state.connected then
        drawOffline(monitor, Layout, width, height)
        return { state = state }
    end

    local safety = state.safety or { level = "warning", warnings = {} }
    local cells = Layout.grid(
        monitor, 1, 6, width, math.max(height - 6, 6), 3, 2, 1
    )

    local cell = cells[1]
    drawPanel(monitor, Layout, cell, "STATUS")
    local x, y = cell.x + 2, cell.y + 2
    local innerWidth = math.max(cell.width - 4, 1)
    Layout.statusBadge(monitor, x, y, state.ignited and "ACTIVE" or "IDLE", {})
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Formed", state.formed and "YES" or "NO")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Cooling", state.activeCooled and "ACTIVE" or "PASSIVE")
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Safety", string.upper(safety.level or "UNKNOWN"), {
        valueColor = Layout.safetyColor(safety.level)
    })

    cell = cells[2]
    drawPanel(monitor, Layout, cell, "ENERGY")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)
    Layout.labelValue(monitor, x, y, innerWidth, "Production", Layout.formatNumber(state.productionRate, 2) .. " FE/t")
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Net output", Layout.formatNumber(state.netProduction, 2) .. " FE/t", {
        valueColor = Layout.theme.safe
    })
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Environment", Layout.formatNumber(state.environmentalLoss, 2) .. " FE/t")
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Transfer loss", Layout.formatNumber(state.transferLoss, 2) .. " FE/t")

    cell = cells[3]
    drawPanel(monitor, Layout, cell, "PLASMA")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)
    Layout.labelValue(monitor, x, y, innerWidth, "Injection", Layout.formatNumber(state.injectionRate, 1) .. " mB/t")
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Plasma temp", Layout.formatNumber(state.plasmaTemperature, 2) .. " K")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Case temp", Layout.formatNumber(state.caseTemperature, 2) .. " K")

    drawTank(monitor, Layout, cells[4], "D-T FUEL", state.dtFuel)
    drawTank(monitor, Layout, cells[5], "DEUTERIUM", state.deuterium)
    drawTank(monitor, Layout, cells[6], "TRITIUM", state.tritium)

    local warnings = safety.warnings or {}
    local footerText = #warnings > 0
        and ("WARNING: " .. tostring(warnings[1]))
        or "Fusion reactor nominal | Cached live data"

    Layout.writeAt(
        monitor,
        backWidth + 2,
        height,
        Layout.truncate(
            footerText,
            math.max(width - backWidth - 1, 1)
        ),
        #warnings > 0
            and Layout.theme.warning
            or Layout.theme.muted,
        colors.black
    )

    return { state = state, cells = cells }
end

return FusionPage
