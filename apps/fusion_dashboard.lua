--================================================--
-- GEN'S Nuclear Control
-- Version : 0.2.0
-- Application : Fusion Dashboard
--================================================--

local ui = dofile("/ui/widgets.lua")
local C = dofile("/ui/colors.lua")
local Fusion = dofile("/api/fusion.lua")
local Induction = dofile("/api/induction.lua")
local Energy = dofile("/core/energy.lua")

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

local matrix = Induction.new()

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
-- Signed energy
--------------------------------------------------

local function formatSignedEnergy(value)
    value = tonumber(value)

    if not value then
        return "N/A"
    end

    local formatted = Energy.formatFEPerTick(math.abs(value))

    if value > 0 then
        return "+" .. formatted
    elseif value < 0 then
        return "-" .. formatted
    end

    return formatted
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
    --------------------------------------------------
    -- Reconnection
    --------------------------------------------------

    if not reactor:isConnected() then
        reactor:reconnect()
    end

    if not matrix:isConnected() then
        matrix:reconnect()
    end

    --------------------------------------------------
    -- Status
    --------------------------------------------------

    local reactorStatus = reactor:getStatus()
    local matrixStatus = matrix:getStatus()

    --------------------------------------------------
    -- Colors
    --------------------------------------------------

    local balanceColor = C.text

    if type(matrixStatus.netFlow) == "number" then
        if matrixStatus.netFlow > 0 then
            balanceColor = C.online
        elseif matrixStatus.netFlow < 0 then
            balanceColor = C.offline
        end
    end

    local usageColor =
        matrixStatus.connected
        and C.info
        or C.offline

    --------------------------------------------------
    -- Rendering
    --------------------------------------------------

    ui.clear()
    ui.title("GEN'S Nuclear Control")

    ui.status(
        3,
        6,
        "Fusion Reactor",
        reactorStatus.online == true
    )

    ui.field(
        3,
        8,
        "Connection",
        reactorStatus.connected
            and "CONNECTED"
            or "LOST",
        reactorStatus.connected
            and C.online
            or C.offline
    )

    ui.field(
        3,
        10,
        "Reactor Formed",
        reactorStatus.formed
            and "YES"
            or "NO",
        reactorStatus.formed
            and C.online
            or C.offline
    )

    ui.field(
        3,
        12,
        "Injection Rate",
        formatRate(
            reactorStatus.injectionRate
        )
    )

    ui.field(
        3,
        14,
        "Generation",
        Energy.formatFEPerTick(
            reactorStatus.production
        ),
        C.online
    )

    --------------------------------------------------
    -- Energy network
    --------------------------------------------------

    ui.field(
        3,
        16,
        "Network Usage",
        Energy.formatFEPerTick(
            matrixStatus.output
        ),
        usageColor
    )

    ui.field(
        3,
        18,
        "Matrix Input",
        Energy.formatFEPerTick(
            matrixStatus.input
        )
    )

    ui.field(
        3,
        20,
        "Matrix Balance",
        formatSignedEnergy(
            matrixStatus.netFlow
        ),
        balanceColor
    )

    ui.field(
        3,
        22,
        "Stored Energy",
        Energy.formatFE(
            matrixStatus.energy
        )
    )

    ui.field(
        3,
        24,
        "Matrix Capacity",
        Energy.formatFE(
            matrixStatus.capacity
        )
    )

    ui.field(
        3,
        26,
        "Matrix Level",
        Energy.formatPercentage(
            matrixStatus.percentage
        )
    )

    --------------------------------------------------
    -- Reactor temperatures
    --------------------------------------------------

    ui.field(
        3,
        28,
        "Case Temperature",
        Energy.formatKelvin(
            reactorStatus.caseTemperature
        )
    )

    ui.field(
        3,
        30,
        "Plasma Temperature",
        Energy.formatKelvin(
            reactorStatus.plasmaTemperature
        )
    )

    ui.field(
        3,
        32,
        "Logic Mode",
        reactorStatus.logicMode or "N/A",
        C.warning
    )

    ui.field(
        3,
        34,
        "Environmental Loss",
        Energy.formatFEPerTick(
            reactorStatus.environmentalLoss
        )
    )

    ui.field(
        3,
        36,
        "Transfer Loss",
        Energy.formatFEPerTick(
            reactorStatus.transferLoss
        )
    )

    ui.footer(os.date("%H:%M:%S"))

    sleep(1)
end