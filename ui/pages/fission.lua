--================================================--
-- GEN'S Nuclear Control
-- UI Page : Fission Reactor
-- Version : 0.1.0
--================================================--

local FissionPage = {}
local PAGE_COLOR = colors.orange

local function tankOrEmpty(tank)
    if type(tank) == "table" then return tank end
    return { amount = 0, capacity = 0, percentage = 0 }
end

local function drawButton(monitor, Layout, x, y, width, text, color)
    Layout.writeAt(monitor, x, y, string.rep(" ", width), colors.white, color)
    text = Layout.truncate(text, width)
    local textX = x + math.max(math.floor((width - #text) / 2), 0)
    Layout.writeAt(monitor, textX, y, text, colors.white, color)
end

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
end

local function tankColor(Layout, percentage, highIsDanger)
    percentage = percentage or 0

    if highIsDanger then
        if percentage >= 0.95 then return Layout.theme.emergency end
        if percentage >= 0.80 then return Layout.theme.warning end
    else
        if percentage <= 0.05 then return Layout.theme.emergency end
        if percentage <= 0.25 then return Layout.theme.warning end
    end

    return Layout.theme.safe
end

local function drawTank(
    monitor,
    Layout,
    cell,
    title,
    tank,
    highIsDanger
)
    tank = tankOrEmpty(tank)
    drawPanel(monitor, Layout, cell, title)

    local x = cell.x + 2
    local y = cell.y + 2
    local width = math.max(cell.width - 4, 1)
    local percentage = tank.percentage or 0

    Layout.labelValue(monitor, x, y, width, "Filled", Layout.formatPercent(percentage), {
        valueColor = tankColor(Layout, percentage, highIsDanger)
    })
    Layout.labelValue(monitor, x, y + 1, width, "Amount", Layout.formatNumber(tank.amount, 1))
    Layout.labelValue(monitor, x, y + 2, width, "Capacity", Layout.formatNumber(tank.capacity, 1))

    if cell.height >= 7 then
        Layout.progressBar(monitor, x, y + 4, width, percentage, {
            filledColor = tankColor(Layout, percentage, highIsDanger)
        })
    end
end

local function drawOffline(monitor, Layout, width, height)
    Layout.panel(
        monitor, 2, 6,
        math.max(width - 2, 2),
        math.max(height - 7, 3),
        "FISSION REACTOR",
        Layout.theme.emergency
    )
    Layout.writeAt(
        monitor, 4, 8,
        "Fission reactor peripheral unavailable",
        Layout.theme.emergency
    )
end

function FissionPage.draw(context)
    if type(context) ~= "table" then error("Fission page context required") end

    local monitor = context.monitor
    local Layout = context.layout
    local navigation = context.navigation

    if not monitor or not Layout or not navigation then
        error("Incomplete Fission page context")
    end

    local state = context.cache and context.cache:get("fission")
    if not state and context.devices and context.devices.fission then
        state = context.devices.fission:getState()
    end

    local width, height = monitor.getSize()
    navigation:clearRegions("fission")
    Layout.clear(monitor)
    Layout.header(monitor, "GEN'S NUCLEAR CONTROL", "FISSION REACTOR")

    local backWidth = math.min(12, width)
    local backX = 1
    local backY = height
    drawButton(monitor, Layout, backX, backY, backWidth, "< BACK", PAGE_COLOR)
    navigation:registerBackButton(backX, backY, backWidth, 1, {
        id = "fission_back",
        page = "fission",
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

    --------------------------------------------------
    -- Status
    --------------------------------------------------

    local cell = cells[1]
    drawPanel(monitor, Layout, cell, "STATUS")
    local x, y = cell.x + 2, cell.y + 2
    local innerWidth = math.max(cell.width - 4, 1)

    Layout.statusBadge(monitor, x, y, state.active and "ACTIVE" or "IDLE", {})
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Formed", state.formed and "YES" or "NO")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Safety", string.upper(safety.level or "UNKNOWN"), {
        valueColor = Layout.safetyColor(safety.level)
    })
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Damage", string.format("%.2f%%", state.damagePercent or 0), {
        valueColor = (state.damagePercent or 0) > 0
            and Layout.theme.warning
            or Layout.theme.safe
    })

    --------------------------------------------------
    -- Operation
    --------------------------------------------------

    cell = cells[2]
    drawPanel(monitor, Layout, cell, "OPERATION")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "Burn set", Layout.formatNumber(state.burnRate, 3) .. " mB/t")
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Actual burn", Layout.formatNumber(state.actualBurnRate, 3) .. " mB/t")
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Maximum", Layout.formatNumber(state.maxBurnRate, 3) .. " mB/t")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Utilization", Layout.formatPercent(state.burnRatePercentage or 0))

    if cell.height >= 8 then
        Layout.progressBar(monitor, x, y + 5, innerWidth, state.burnRatePercentage or 0, {
            dynamicColor = true
        })
    end

    --------------------------------------------------
    -- Thermal data
    --------------------------------------------------

    cell = cells[3]
    drawPanel(monitor, Layout, cell, "THERMAL")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "Temperature", Layout.formatNumber(state.temperature, 2) .. " K", {
        valueColor = (state.temperature or 0) >= 1000
            and Layout.theme.emergency
            or (state.temperature or 0) >= 800
            and Layout.theme.warning
            or Layout.theme.safe
    })
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Heating rate", Layout.formatNumber(state.heatingRate, 2))
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Boil efficiency", Layout.formatNumber(state.boilEfficiency, 3))
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Environment", Layout.formatNumber(state.environmentalLoss, 2))
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Assemblies", tostring(state.fuelAssemblies or 0))
    Layout.labelValue(monitor, x, y + 5, innerWidth, "Fuel surface", Layout.formatNumber(state.fuelSurfaceArea, 1))

    --------------------------------------------------
    -- Tanks
    --------------------------------------------------

    drawTank(monitor, Layout, cells[4], "FISSILE FUEL", state.fuel, false)

    cell = cells[5]
    drawPanel(monitor, Layout, cell, "COOLANT")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)
    local coolant = tankOrEmpty(state.coolant)
    local heated = tankOrEmpty(state.heatedCoolant)

    Layout.labelValue(monitor, x, y, innerWidth, "Coolant", Layout.formatPercent(coolant.percentage or 0), {
        valueColor = tankColor(Layout, coolant.percentage, false)
    })
    Layout.progressBar(monitor, x, y + 1, innerWidth, coolant.percentage or 0, {
        filledColor = tankColor(Layout, coolant.percentage, false)
    })
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Heated", Layout.formatPercent(heated.percentage or 0), {
        valueColor = tankColor(Layout, heated.percentage, true)
    })
    Layout.progressBar(monitor, x, y + 4, innerWidth, heated.percentage or 0, {
        filledColor = tankColor(Layout, heated.percentage, true)
    })

    drawTank(monitor, Layout, cells[6], "NUCLEAR WASTE", state.waste, true)

    --------------------------------------------------
    -- Footer
    --------------------------------------------------

    local warnings = safety.warnings or {}
    local footerText = #warnings > 0
        and ("WARNING: " .. tostring(warnings[1]))
        or "Fission reactor nominal | Read-only controls"

    Layout.writeAt(
        monitor,
        backWidth + 2,
        height,
        Layout.truncate(footerText, math.max(width - backWidth - 1, 1)),
        #warnings > 0 and Layout.theme.warning or Layout.theme.muted,
        colors.black
    )

    return { state = state, cells = cells }
end

return FissionPage
