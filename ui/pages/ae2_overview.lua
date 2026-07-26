--================================================--
-- GEN'S Nuclear Control
-- UI Page : AE2 Overview
-- Version : 0.1.0
--================================================--

local Common = dofile("/ui/pages/ae2_common.lua")
local AE2Overview = {}

local function storageOrEmpty(storage)
    if type(storage) == "table" then return storage end
    return { used = 0, total = 0, available = 0, percentage = 0 }
end

local function drawOffline(context, width, height)
    context.layout.panel(
        context.monitor, 2, 7,
        math.max(width - 2, 2),
        math.max(height - 8, 3),
        "AE2 NETWORK",
        context.layout.theme.emergency
    )
    context.layout.writeAt(
        context.monitor, 4, 9,
        "ME Bridge peripheral unavailable",
        context.layout.theme.emergency
    )
end

function AE2Overview.draw(context)
    if type(context) ~= "table" then error("AE2 Overview context required") end

    local monitor = context.monitor
    local Layout = context.layout

    if not monitor or not Layout or not context.navigation then
        error("Incomplete AE2 Overview context")
    end

    local state = context.cache and context.cache:get("ae2")
    if not state and context.devices and context.devices.ae2 then
        state = context.devices.ae2:getState()
    end

    local width, height, contentY, backWidth = Common.begin(
        context,
        "ae2_overview",
        "APPLIED ENERGISTICS 2"
    )

    if not state or not state.connected then
        drawOffline(context, width, height)
        return { state = state }
    end

    local itemStorage = storageOrEmpty(state.itemStorage)
    local fluidStorage = storageOrEmpty(state.fluidStorage)
    local energy = type(state.energy) == "table" and state.energy or {}
    local crafting = type(state.crafting) == "table" and state.crafting or {}
    local safety = state.safety or { level = "warning", warnings = {} }

    local cells = Layout.grid(
        monitor,
        1,
        contentY,
        width,
        math.max(height - contentY, 6),
        3,
        2,
        1
    )

    --------------------------------------------------
    -- Network status
    --------------------------------------------------

    local cell = cells[1]
    Common.drawPanel(monitor, Layout, cell, "NETWORK")
    local x, y = cell.x + 2, cell.y + 2
    local innerWidth = math.max(cell.width - 4, 1)
    local online = state.online and state.networkConnected

    Layout.statusBadge(monitor, x, y, online and "ONLINE" or "OFFLINE", {})
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Bridge", state.name or "ME Bridge")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Connected", state.networkConnected and "YES" or "NO")
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Safety", string.upper(safety.level or "UNKNOWN"), {
        valueColor = Layout.safetyColor(safety.level)
    })

    --------------------------------------------------
    -- Item storage
    --------------------------------------------------

    cell = cells[2]
    Common.drawPanel(monitor, Layout, cell, "ITEM STORAGE")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "Used", Layout.formatNumber(itemStorage.used, 0) .. " B")
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Total", Layout.formatNumber(itemStorage.total, 0) .. " B")
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Available", Layout.formatNumber(itemStorage.available, 0) .. " B")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Filled", Layout.formatPercent(itemStorage.percentage or 0))

    if cell.height >= 8 then
        Layout.progressBar(monitor, x, y + 5, innerWidth, itemStorage.percentage or 0, {
            filledColor = (itemStorage.percentage or 0) >= 0.98
                and Layout.theme.emergency
                or (itemStorage.percentage or 0) >= 0.90
                and Layout.theme.warning
                or Common.color
        })
    end

    --------------------------------------------------
    -- Energy
    --------------------------------------------------

    cell = cells[3]
    Common.drawPanel(monitor, Layout, cell, "AE ENERGY")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "Stored", Layout.formatNumber(energy.stored or 0, 2) .. " AE")
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Capacity", Layout.formatNumber(energy.capacity or 0, 2) .. " AE")
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Usage", Layout.formatNumber(energy.usage or 0, 2) .. " AE/t")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Average input", Layout.formatNumber(energy.averageInput or 0, 2) .. " AE/t")
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Net flow", Layout.formatNumber(energy.netFlow or 0, 2) .. " AE/t", {
        valueColor = (energy.netFlow or 0) >= 0 and Layout.theme.safe or Layout.theme.warning
    })

    --------------------------------------------------
    -- Crafting
    --------------------------------------------------

    cell = cells[4]
    Common.drawPanel(monitor, Layout, cell, "CRAFTING")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "CPUs", tostring(crafting.cpuCount or 0))
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Busy", tostring(crafting.busyCPUCount or 0))
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Available", tostring(crafting.freeCPUCount or 0))
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Active tasks", tostring(crafting.activeTaskCount or 0), {
        valueColor = (crafting.activeTaskCount or 0) > 0 and Common.color or Layout.theme.muted
    })

    --------------------------------------------------
    -- Fluids
    --------------------------------------------------

    cell = cells[5]
    Common.drawPanel(monitor, Layout, cell, "FLUID STORAGE")
    x, y = cell.x + 2, cell.y + 2
    innerWidth = math.max(cell.width - 4, 1)

    Layout.labelValue(monitor, x, y, innerWidth, "Used", Layout.formatNumber(fluidStorage.used, 0) .. " B")
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Total", Layout.formatNumber(fluidStorage.total, 0) .. " B")
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Available", Layout.formatNumber(fluidStorage.available, 0) .. " B")
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Filled", Layout.formatPercent(fluidStorage.percentage or 0))

    if cell.height >= 8 then
        Layout.progressBar(monitor, x, y + 5, innerWidth, fluidStorage.percentage or 0, {
            filledColor = Common.color
        })
    end

    --------------------------------------------------
    -- Diagnostics
    --------------------------------------------------

    cell = cells[6]
    Common.drawPanel(monitor, Layout, cell, "DIAGNOSTICS")
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
    Layout.labelValue(monitor, x, y + 3, innerWidth, "Power margin", (energy.netFlow or 0) >= 0 and "POSITIVE" or "NEGATIVE", {
        valueColor = (energy.netFlow or 0) >= 0 and Layout.theme.safe or Layout.theme.warning
    })
    Layout.labelValue(monitor, x, y + 4, innerWidth, "Data source", "LIVE CACHE")

    local footerText = #warnings > 0
        and ("WARNING: " .. tostring(warnings[1]))
        or "AE2 network nominal | Select a tab for details"

    Common.footer(
        context,
        backWidth,
        footerText,
        #warnings > 0 and Layout.theme.warning or Layout.theme.muted
    )

    return { state = state, cells = cells }
end

return AE2Overview
