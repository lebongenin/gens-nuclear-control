--================================================--
-- GEN'S Nuclear Control
-- UI Page : Induction Matrix
-- Version : 0.1.0
--================================================--

local InductionPage = {}
local PAGE_COLOR = colors.yellow

local function drawButton(monitor, Layout, x, y, width, text, color)
    Layout.writeAt(monitor, x, y, string.rep(" ", width), colors.black, color)
    text = Layout.truncate(text, width)
    local textX = x + math.max(math.floor((width - #text) / 2), 0)
    Layout.writeAt(monitor, textX, y, text, colors.black, color)
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

local function flowText(state)
    if state.charging then return "CHARGING" end
    if state.discharging then return "DISCHARGING" end
    return "STABLE"
end

local function flowColor(Layout, state)
    if state.charging then return Layout.theme.safe end
    if state.discharging then return Layout.theme.warning end
    return Layout.theme.muted
end

local function drawOffline(monitor, Layout, width, height)
    Layout.panel(
        monitor, 2, 6,
        math.max(width - 2, 2),
        math.max(height - 7, 3),
        "INDUCTION MATRIX",
        Layout.theme.emergency
    )
    Layout.writeAt(
        monitor, 4, 8,
        "Induction Matrix peripheral unavailable",
        Layout.theme.emergency
    )
end

function InductionPage.draw(context)
    if type(context) ~= "table" then error("Induction page context required") end

    local monitor = context.monitor
    local Layout = context.layout
    local navigation = context.navigation

    if not monitor or not Layout or not navigation then
        error("Incomplete Induction page context")
    end

    local state = context.cache and context.cache:get("induction")
    if not state and context.devices and context.devices.induction then
        state = context.devices.induction:getState()
    end

    local width, height = monitor.getSize()
    navigation:clearRegions("induction")
    Layout.clear(monitor)
    Layout.header(monitor, "GEN'S NUCLEAR CONTROL", "INDUCTION MATRIX")

    local backWidth = math.min(12, width)
    local backX = 1
    local backY = height
    drawButton(monitor, Layout, backX, backY, backWidth, "< BACK", PAGE_COLOR)
    navigation:registerBackButton(backX, backY, backWidth, 1, {
        id = "induction_back",
        page = "induction",
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

    Layout.statusBadge(monitor, x, y, state.formed and "ONLINE" or "OFFLINE", {})
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Formed", state.formed and "YES" or "NO")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Safety", string.upper(safety.level or "UNKNOWN"), {
        valueColor = Layout.safetyColor(safety.level)
    })
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Flow state", flowText(state), {
        valueColor = flowColor(Layout, state)
    })

    --------------------------------------------------
    -- Storage
    --------------------------------------------------

    cell = cells[2]
    drawPanel(monitor, Layout, cell, "ENERGY STORAGE")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "Stored", Layout.formatNumber(state.energy, 2) .. " FE")
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Capacity", Layout.formatNumber(state.capacity, 2) .. " FE")
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Available", Layout.formatNumber(state.needed, 2) .. " FE")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Filled", Layout.formatPercent(state.percentage or 0))

    if cell.height >= 8 then
        Layout.progressBar(monitor, x, y + 5, innerWidth, state.percentage or 0, {
            filledColor = (state.percentage or 0) <= 0.05
                and Layout.theme.emergency
                or (state.percentage or 0) <= 0.20
                and Layout.theme.warning
                or PAGE_COLOR
        })
    end

    --------------------------------------------------
    -- Live flow
    --------------------------------------------------

    cell = cells[3]
    drawPanel(monitor, Layout, cell, "LIVE FLOW")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "Input", Layout.formatNumber(state.input, 2) .. " FE/t", {
        valueColor = Layout.theme.safe
    })
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Output", Layout.formatNumber(state.output, 2) .. " FE/t", {
        valueColor = state.output > state.input and Layout.theme.warning or colors.white
    })
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Net flow", Layout.formatNumber(state.netFlow, 2) .. " FE/t", {
        valueColor = flowColor(Layout, state)
    })
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Direction", flowText(state), {
        valueColor = flowColor(Layout, state)
    })

    --------------------------------------------------
    -- Transfer utilization
    --------------------------------------------------

    cell = cells[4]
    drawPanel(monitor, Layout, cell, "TRANSFER")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "Limit", Layout.formatNumber(state.transferCapacity, 2) .. " FE/t")
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Input use", Layout.formatPercent(state.inputUtilization or 0))
    Layout.progressBar(monitor, x, y + 3, innerWidth, state.inputUtilization or 0, {
        dynamicColor = true
    })
    Layout.labelValue(monitor, x, y + 5, innerWidth, "Output use", Layout.formatPercent(state.outputUtilization or 0))
    Layout.progressBar(monitor, x, y + 6, innerWidth, state.outputUtilization or 0, {
        dynamicColor = true
    })

    --------------------------------------------------
    -- Installed components
    --------------------------------------------------

    cell = cells[5]
    drawPanel(monitor, Layout, cell, "COMPONENTS")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "Cells", tostring(state.installedCells or 0))
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Providers", tostring(state.installedProviders or 0))
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Cell capacity", Layout.formatNumber(state.capacity, 2) .. " FE")
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Transfer limit", Layout.formatNumber(state.transferCapacity, 2) .. " FE/t")

    --------------------------------------------------
    -- Diagnostics
    --------------------------------------------------

    cell = cells[6]
    drawPanel(monitor, Layout, cell, "DIAGNOSTICS")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "API errors", tostring(type(state.errors) == "table" and #state.errors or 0), {
        valueColor = state.hasErrors and Layout.theme.warning or Layout.theme.safe
    })
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Warnings", tostring(type(safety.warnings) == "table" and #safety.warnings or 0), {
        valueColor = type(safety.warnings) == "table" and #safety.warnings > 0
            and Layout.theme.warning
            or Layout.theme.safe
    })
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Energy balance", state.netFlow >= 0 and "POSITIVE" or "NEGATIVE", {
        valueColor = flowColor(Layout, state)
    })
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Data source", "LIVE CACHE")

    --------------------------------------------------
    -- Footer
    --------------------------------------------------

    local warnings = safety.warnings or {}
    local footerText = #warnings > 0
        and ("WARNING: " .. tostring(warnings[1]))
        or "Induction Matrix nominal | Cached live data"

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

return InductionPage
