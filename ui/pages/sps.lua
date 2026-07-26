--================================================--
-- GEN'S Nuclear Control
-- UI Page : Supercharged SPS
-- Version : 0.1.0
--================================================--

local SPSPage = {}
local PAGE_COLOR = colors.magenta

local function resourceOrEmpty(resource)
    if type(resource) == "table" then return resource end
    return {
        name = nil,
        amount = 0,
        capacity = 0,
        needed = 0,
        percentage = 0
    }
end

local function drawButton(monitor, Layout, x, y, width, text, color)
    Layout.writeAt(monitor, x, y, string.rep(" ", width), colors.white, color)
    text = Layout.truncate(text, width)
    local textX = x + math.max(math.floor((width - #text) / 2), 0)
    Layout.writeAt(monitor, textX, y, text, colors.white, color)
end

local function drawPanel(monitor, Layout, cell, title, borderColor)
    Layout.panel(
        monitor,
        cell.x,
        cell.y,
        cell.width,
        cell.height,
        title,
        borderColor or PAGE_COLOR
    )
end

local function levelColor(Layout, percentage, highIsDanger)
    percentage = percentage or 0

    if highIsDanger then
        if percentage >= 0.95 then return Layout.theme.emergency end
        if percentage >= 0.80 then return Layout.theme.warning end
    else
        if percentage <= 0.05 then return Layout.theme.emergency end
        if percentage <= 0.20 then return Layout.theme.warning end
    end

    return Layout.theme.safe
end

local function drawResource(
    monitor,
    Layout,
    cell,
    title,
    resource,
    highIsDanger
)
    resource = resourceOrEmpty(resource)
    drawPanel(monitor, Layout, cell, title)

    local x = cell.x + 2
    local y = cell.y + 2
    local width = math.max(cell.width - 4, 1)
    local percentage = resource.percentage or 0

    Layout.labelValue(monitor, x, y, width, "Resource", resource.name or "Empty")
    Layout.labelValue(monitor, x, y + 1, width, "Amount", Layout.formatNumber(resource.amount, 3))
    Layout.labelValue(monitor, x, y + 2, width, "Capacity", Layout.formatNumber(resource.capacity, 1))
    Layout.labelValue(monitor, x, y + 3, width, "Filled", Layout.formatPercent(percentage), {
        valueColor = levelColor(Layout, percentage, highIsDanger)
    })

    if cell.height >= 9 then
        Layout.progressBar(monitor, x, y + 5, width, percentage, {
            filledColor = levelColor(Layout, percentage, highIsDanger)
        })
    end
end

local function drawOffline(monitor, Layout, width, height)
    Layout.panel(
        monitor, 2, 6,
        math.max(width - 2, 2),
        math.max(height - 7, 3),
        "SUPERCHARGED SPS",
        Layout.theme.emergency
    )
    Layout.writeAt(
        monitor, 4, 8,
        "SPS peripheral unavailable",
        Layout.theme.emergency
    )
end

function SPSPage.draw(context)
    if type(context) ~= "table" then error("SPS page context required") end

    local monitor = context.monitor
    local Layout = context.layout
    local navigation = context.navigation

    if not monitor or not Layout or not navigation then
        error("Incomplete SPS page context")
    end

    local state = context.cache and context.cache:get("sps")
    if not state and context.devices and context.devices.sps then
        state = context.devices.sps:getState()
    end

    local width, height = monitor.getSize()
    navigation:clearRegions("sps")
    Layout.clear(monitor)
    Layout.header(monitor, "GEN'S NUCLEAR CONTROL", "SUPERCHARGED SPS")

    local backWidth = math.min(12, width)
    local backX = 1
    local backY = height
    drawButton(monitor, Layout, backX, backY, backWidth, "< BACK", PAGE_COLOR)
    navigation:registerBackButton(backX, backY, backWidth, 1, {
        id = "sps_back",
        page = "sps",
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

    Layout.statusBadge(monitor, x, y, state.processing and "ACTIVE" or "IDLE", {})
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Formed", state.formed and "YES" or "NO")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Processing", state.processing and "YES" or "NO", {
        valueColor = state.processing and Layout.theme.safe or Layout.theme.warning
    })
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Safety", string.upper(safety.level or "UNKNOWN"), {
        valueColor = Layout.safetyColor(safety.level)
    })

    --------------------------------------------------
    -- Processing
    --------------------------------------------------

    cell = cells[2]
    drawPanel(monitor, Layout, cell, "PROCESSING")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "Process rate", Layout.formatNumber(state.processRate, 4))
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Coils", tostring(state.coils or 0), {
        valueColor = (state.coils or 0) > 0 and Layout.theme.safe or Layout.theme.emergency
    })
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Input present", (state.input and state.input.amount or 0) > 0 and "YES" or "NO")
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Output stored", Layout.formatNumber(state.output and state.output.amount or 0, 3))

    --------------------------------------------------
    -- Energy
    --------------------------------------------------

    cell = cells[3]
    drawPanel(monitor, Layout, cell, "ENERGY")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "Stored", Layout.formatNumber(state.energy, 2) .. " FE")
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Capacity", Layout.formatNumber(state.energyCapacity, 2) .. " FE")
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Needed", Layout.formatNumber(state.energyNeeded, 2) .. " FE")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Filled", Layout.formatPercent(state.energyPercentage or 0))

    if cell.height >= 8 then
        Layout.progressBar(monitor, x, y + 5, innerWidth, state.energyPercentage or 0, {
            filledColor = levelColor(Layout, state.energyPercentage, false)
        })
    end

    --------------------------------------------------
    -- Resources
    --------------------------------------------------

    drawResource(monitor, Layout, cells[4], "POLONIUM INPUT", state.input, false)
    drawResource(monitor, Layout, cells[5], "ANTIMATTER OUTPUT", state.output, true)

    --------------------------------------------------
    -- Diagnostics
    --------------------------------------------------

    cell = cells[6]
    drawPanel(monitor, Layout, cell, "DIAGNOSTICS")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    local errors = type(state.errors) == "table" and state.errors or {}
    local warnings = type(safety.warnings) == "table" and safety.warnings or {}

    Layout.labelValue(monitor, x, y, innerWidth, "API errors", tostring(#errors), {
        valueColor = #errors > 0 and Layout.theme.warning or Layout.theme.safe
    })
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Warnings", tostring(#warnings), {
        valueColor = #warnings > 0 and Layout.theme.warning or Layout.theme.safe
    })
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Coil status", (state.coils or 0) > 0 and "READY" or "MISSING", {
        valueColor = (state.coils or 0) > 0 and Layout.theme.safe or Layout.theme.emergency
    })
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Data source", "LIVE CACHE")

    --------------------------------------------------
    -- Footer
    --------------------------------------------------

    local footerText = #warnings > 0
        and ("WARNING: " .. tostring(warnings[1]))
        or "SPS nominal | Antimatter production monitoring"

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

return SPSPage
