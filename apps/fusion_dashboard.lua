--================================================--
-- GEN'S Nuclear Control
-- Version : 0.1.0
-- Application : Fusion Dashboard
--================================================--

local ui = dofile("/ui/widgets.lua")
local C = dofile("/ui/colors.lua")
local Fusion = dofile("/api/fusion.lua")

--------------------------------------------------
-- Monitor
--------------------------------------------------

local monitor = peripheral.find("monitor")

if not monitor then
    error("No monitor found")
end

monitor.setTextScale(0.5)
term.redirect(monitor)

--------------------------------------------------
-- Fusion Reactor
--------------------------------------------------

local reactor = Fusion.new()

--------------------------------------------------
-- Formatting
--------------------------------------------------

local function formatNumber(value, decimals)
    value = tonumber(value)

    if not value then
        return "N/A"
    end

    return string.format(
        "%." .. tostring(decimals or 2) .. "f",
        value
    )
end

local function formatTemperature(value)
    return formatNumber(value, 2) .. " K"
end

local function formatRate(value)
    value = tonumber(value)

    if not value then
        return "N/A"
    end

    return tostring(value)
end

local function formatLoss(value)
    return formatNumber(value, 2)
end

--------------------------------------------------
-- FE production
--------------------------------------------------

local function formatEnergyPerTick(value)
    value = tonumber(value)

    if not value then
        return "N/A"
    end

    if value >= 1000000000 then
        return string.format("%.2f GFE/t", value / 1000000000)
    elseif value >= 1000000 then
        return string.format("%.2f MFE/t", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.2f kFE/t", value / 1000)
    end

    return string.format("%.0f FE/t", value)
end

--------------------------------------------------
-- Dashboard loop
--------------------------------------------------

while true do
    if not reactor:isConnected() then
        reactor:reconnect()
    end

    local status = reactor:getStatus()

    ui.clear()
    ui.title("GEN'S Nuclear Control")

    ui.status(
        3,
        6,
        "Fusion Reactor",
        status.online == true
    )

    ui.field(
        3,
        8,
        "Connection",
        status.connected and "CONNECTED" or "LOST",
        status.connected and C.online or C.offline
    )

    ui.field(
        3,
        10,
        "Reactor Formed",
        status.formed and "YES" or "NO",
        status.formed and C.online or C.offline
    )

    ui.field(
        3,
        12,
        "Injection Rate",
        formatRate(status.injectionRate)
    )
	
	ui.field(
    3,
    14,
    "Generation",
    formatEnergyPerTick(status.production),
    C.online
	)

	ui.field(
    3,
    16,
    "Case Temperature",
    formatTemperature(status.caseTemperature)
)

	ui.field(
    3,
    18,
    "Plasma Temperature",
    formatTemperature(status.plasmaTemperature)
)

	ui.field(
    3,
    20,
    "Logic Mode",
    status.logicMode or "N/A",
    C.warning
)

	ui.field(
    3,
    22,
    "Environmental Loss",
    formatLoss(status.environmentalLoss)
)

	ui.field(
    3,
    24,
    "Transfer Loss",
    formatLoss(status.transferLoss)
)

    ui.footer(os.date("%H:%M:%S"))

    sleep(1)
end