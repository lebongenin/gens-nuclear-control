--================================================--
-- GEN'S Nuclear Control
-- Application : Overview Dashboard
-- Version : 0.1.0
--================================================--

local MonitorManager =
    dofile(
        "/core/monitor_manager.lua"
    )

local Layout =
    dofile("/ui/layout.lua")

local Fusion =
    dofile("/api/fusion.lua")

local Fission =
    dofile("/api/fission.lua")

local Induction =
    dofile("/api/induction.lua")

local SPS =
    dofile("/api/sps.lua")

local AE2 =
    dofile("/api/ae2.lua")

--------------------------------------------------
-- Configuration
--------------------------------------------------

local REFRESH_INTERVAL = 1
local MONITOR_SCALE = 0.5

--------------------------------------------------
-- Devices
--------------------------------------------------

local fusion = Fusion.new()
local fission = Fission.new()
local induction = Induction.new()
local sps = SPS.new()
local ae2 = AE2.new()

--------------------------------------------------
-- Monitor manager
--------------------------------------------------

local monitors =
    MonitorManager.new({
        defaultScale = MONITOR_SCALE,
        primaryRole = "overview"
    })

monitors:configureDefaults()
monitors:autoAssign()

local display, displayName =
    monitors:getPrimary()

if not display then
    display = term.current()
    displayName = "computer"
end

--------------------------------------------------
-- Safe state reading
--------------------------------------------------

local function readState(
    api,
    fallback
)
    local success, result = pcall(
        function()
            return api:getState()
        end
    )

    if success
        and type(result) == "table" then
        return result
    end

    fallback = fallback or {}

    fallback.connected = false
    fallback.errors = {
        {
            method = "dashboard",
            message = tostring(result)
        }
    }

    return fallback
end

--------------------------------------------------
-- State fallbacks
--------------------------------------------------

local function emptyTank()
    return {
        name = nil,
        amount = 0,
        capacity = 0,
        percentage = 0
    }
end

local function fusionFallback()
    return {
        connected = false,
        formed = false,
        ignited = false,
        productionRate = 0,
        injectionRate = 0,
        dtFuel = emptyTank(),
        safety = {
            level = "emergency",
            warnings = {
                "Fusion API unavailable"
            }
        }
    }
end

local function fissionFallback()
    return {
        connected = false,
        formed = false,
        active = false,
        temperature = 0,
        actualBurnRate = 0,
        maxBurnRate = 0,
        damagePercent = 0,
        coolant = emptyTank(),
        waste = emptyTank(),
        safety = {
            level = "emergency",
            warnings = {
                "Fission API unavailable"
            }
        }
    }
end

local function inductionFallback()
    return {
        connected = false,
        formed = false,
        energy = 0,
        capacity = 0,
        percentage = 0,
        input = 0,
        output = 0,
        netFlow = 0,
        safety = {
            level = "emergency",
            warnings = {
                "Induction API unavailable"
            }
        }
    }
end

local function spsFallback()
    return {
        connected = false,
        formed = false,
        energy = 0,
        energyCapacity = 0,
        energyPercentage = 0,
        input = emptyTank(),
        output = emptyTank(),
        processRate = 0,
        coils = 0,
        processing = false,
        safety = {
            level = "emergency",
            warnings = {
                "SPS API unavailable"
            }
        }
    }
end

local function ae2Fallback()
    return {
        connected = false,
        networkConnected = false,
        online = false,

        itemStorage = {
            used = 0,
            total = 0,
            available = 0,
            percentage = 0
        },

        energy = {
            stored = 0,
            capacity = 0,
            percentage = 0,
            usage = 0,
            averageInput = 0,
            netFlow = 0
        },

        crafting = {
            cpuCount = 0,
            busyCPUCount = 0,
            activeTaskCount = 0
        },

        safety = {
            level = "emergency",
            warnings = {
                "AE2 API unavailable"
            }
        }
    }
end

--------------------------------------------------
-- Drawing helpers
--------------------------------------------------

local function safetyOf(state)
    if type(state.safety) == "table"
        and type(state.safety.level)
            == "string" then
        return state.safety.level
    end

    if state.connected then
        return "warning"
    end

    return "emergency"
end

local function drawPanelHeader(
    cell,
    title,
    state,
    active
)
    Layout.box(
        cell.x,
        cell.y,
        cell.width,
        cell.height,
        {
            title = title,
            borderColor =
                Layout.safetyColor(
                    safetyOf(state)
                )
        }
    )

    local content =
        Layout.panelContent(
            cell.x,
            cell.y,
            cell.width,
            cell.height
        )

    local status

    if not state.connected then
        status = "offline"
    elseif active == true then
        status = "active"
    elseif active == false then
        status = "idle"
    else
        status = safetyOf(state)
    end

    Layout.statusBadge(
        content.x,
        content.y,
        status
    )

    return content
end

local function drawTankLine(
    content,
    row,
    label,
    tank
)
    tank = tank or emptyTank()

    Layout.labelValue(
        content.x,
        row,
        content.width,
        label,
        Layout.formatPercent(
            tank.percentage,
            0
        )
    )
end

--------------------------------------------------
-- Fusion panel
--------------------------------------------------

local function drawFusion(
    cell,
    state
)
    local content = drawPanelHeader(
        cell,
        "FUSION",
        state,
        state.ignited
    )

    if content.height < 2 then
        return
    end

    local row = content.y + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Production",
        Layout.formatNumber(
            state.productionRate or 0,
            1
        ) .. " FE/t"
    )

    row = row + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Injection",
        Layout.formatNumber(
            state.injectionRate or 0,
            1
        )
    )

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        drawTankLine(
            content,
            row,
            "D-T Fuel",
            state.dtFuel
        )
    end

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        Layout.progressBar(
            content.x,
            row,
            content.width,
            state.dtFuel
                and state.dtFuel.percentage
                or 0,
            {
                dynamicColor = false
            }
        )
    end
end

--------------------------------------------------
-- Fission panel
--------------------------------------------------

local function drawFission(
    cell,
    state
)
    local content = drawPanelHeader(
        cell,
        "FISSION",
        state,
        state.active
    )

    local row = content.y + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Temperature",
        Layout.formatNumber(
            state.temperature or 0,
            1
        ) .. " K"
    )

    row = row + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Burn",
        Layout.formatNumber(
            state.actualBurnRate or 0,
            2
        )
        .. "/"
        .. Layout.formatNumber(
            state.maxBurnRate or 0,
            1
        )
    )

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        Layout.labelValue(
            content.x,
            row,
            content.width,
            "Damage",
            Layout.formatNumber(
                state.damagePercent or 0,
                1
            ) .. "%"
        )
    end

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        drawTankLine(
            content,
            row,
            "Coolant",
            state.coolant
        )
    end

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        drawTankLine(
            content,
            row,
            "Waste",
            state.waste
        )
    end
end

--------------------------------------------------
-- Induction panel
--------------------------------------------------

local function drawInduction(
    cell,
    state
)
    local content = drawPanelHeader(
        cell,
        "INDUCTION",
        state,
        state.formed
    )

    local row = content.y + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Stored",
        Layout.formatNumber(
            state.energy or 0,
            1
        ) .. " FE"
    )

    row = row + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Capacity",
        Layout.formatNumber(
            state.capacity or 0,
            1
        ) .. " FE"
    )

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        Layout.progressBar(
            content.x,
            row,
            content.width,
            state.percentage or 0,
            {
                dynamicColor = false
            }
        )
    end

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        Layout.labelValue(
            content.x,
            row,
            content.width,
            "Input",
            Layout.formatNumber(
                state.input or 0,
                1
            ) .. "/t"
        )
    end

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        Layout.labelValue(
            content.x,
            row,
            content.width,
            "Output",
            Layout.formatNumber(
                state.output or 0,
                1
            ) .. "/t"
        )
    end
end

--------------------------------------------------
-- SPS panel
--------------------------------------------------

local function drawSPS(
    cell,
    state
)
    local content = drawPanelHeader(
        cell,
        "SPS",
        state,
        state.processing
    )

    local row = content.y + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Process",
        Layout.formatNumber(
            state.processRate or 0,
            3
        )
    )

    row = row + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Coils",
        tostring(state.coils or 0)
    )

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        drawTankLine(
            content,
            row,
            "Polonium",
            state.input
        )
    end

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        drawTankLine(
            content,
            row,
            "Antimatter",
            state.output
        )
    end

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        Layout.progressBar(
            content.x,
            row,
            content.width,
            state.output
                and state.output.percentage
                or 0,
            {
                dynamicColor = true
            }
        )
    end
end

--------------------------------------------------
-- AE2 panel
--------------------------------------------------

local function drawAE2(
    cell,
    state
)
    local active =
        state.online
        and state.networkConnected

    local content = drawPanelHeader(
        cell,
        "AE2",
        state,
        active
    )

    local row = content.y + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Storage",
        Layout.formatPercent(
            state.itemStorage
                and state.itemStorage.percentage
                or 0,
            1
        )
    )

    row = row + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Energy",
        Layout.formatPercent(
            state.energy
                and state.energy.percentage
                or 0,
            1
        )
    )

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        Layout.labelValue(
            content.x,
            row,
            content.width,
            "Usage",
            Layout.formatNumber(
                state.energy
                    and state.energy.usage
                    or 0,
                1
            )
        )
    end

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        Layout.labelValue(
            content.x,
            row,
            content.width,
            "CPUs",
            tostring(
                state.crafting
                    and state.crafting.busyCPUCount
                    or 0
            )
            .. "/"
            .. tostring(
                state.crafting
                    and state.crafting.cpuCount
                    or 0
            )
        )
    end

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        Layout.labelValue(
            content.x,
            row,
            content.width,
            "Tasks",
            tostring(
                state.crafting
                    and state.crafting.activeTaskCount
                    or 0
            )
        )
    end
end

--------------------------------------------------
-- Global status panel
--------------------------------------------------

local function drawGlobal(
    cell,
    states
)
    local priority = {
        safe = 1,
        warning = 2,
        critical = 3,
        emergency = 4
    }

    local globalLevel = "safe"
    local warnings = 0

    for _, state in pairs(states) do
        local level = safetyOf(state)

        if priority[level]
            > priority[globalLevel] then
            globalLevel = level
        end

        if type(state.safety)
            == "table"
            and type(
                state.safety.warnings
            ) == "table" then
            warnings =
                warnings
                + #state.safety.warnings
        end
    end

    local globalState = {
        connected = true,
        safety = {
            level = globalLevel
        }
    }

    local content = drawPanelHeader(
        cell,
        "SYSTEM",
        globalState,
        globalLevel == "safe"
    )

    local row = content.y + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Status",
        string.upper(globalLevel),
        {
            valueColor =
                Layout.safetyColor(
                    globalLevel
                )
        }
    )

    row = row + 1

    Layout.labelValue(
        content.x,
        row,
        content.width,
        "Warnings",
        tostring(warnings)
    )

    row = row + 1

    local online = 0
    local total = 0

    for _, state in pairs(states) do
        total = total + 1

        if state.connected then
            online = online + 1
        end
    end

    if row <= content.y
        + content.height - 1 then
        Layout.labelValue(
            content.x,
            row,
            content.width,
            "Devices",
            tostring(online)
            .. "/"
            .. tostring(total)
        )
    end

    row = row + 1

    if row <= content.y
        + content.height - 1 then
        Layout.labelValue(
            content.x,
            row,
            content.width,
            "Monitor",
            tostring(displayName)
        )
    end
end

--------------------------------------------------
-- Dashboard render
--------------------------------------------------

local function renderDashboard()
    local states = {
        fusion = readState(
            fusion,
            fusionFallback()
        ),

        fission = readState(
            fission,
            fissionFallback()
        ),

        induction = readState(
            induction,
            inductionFallback()
        ),

        sps = readState(
            sps,
            spsFallback()
        ),

        ae2 = readState(
            ae2,
            ae2Fallback()
        )
    }

    Layout.clear()

    local startY = Layout.header(
        "GEN'S NUCLEAR CONTROL",
        "SYSTEM OVERVIEW"
    )

    local cells =
        Layout.dashboardGrid(
            startY,
            6
        )

    if cells[1] then
        drawFusion(
            cells[1],
            states.fusion
        )
    end

    if cells[2] then
        drawFission(
            cells[2],
            states.fission
        )
    end

    if cells[3] then
        drawInduction(
            cells[3],
            states.induction
        )
    end

    if cells[4] then
        drawSPS(
            cells[4],
            states.sps
        )
    end

    if cells[5] then
        drawAE2(
            cells[5],
            states.ae2
        )
    end

    if cells[6] then
        drawGlobal(
            cells[6],
            states
        )
    end

    Layout.footer(
        "Refresh: "
        .. tostring(
            REFRESH_INTERVAL
        )
        .. "s | "
        .. os.date("%H:%M:%S")
    )
end

--------------------------------------------------
-- Initial terminal information
--------------------------------------------------

local originalTerminal =
    term.current()

term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1, 1)

term.setTextColor(colors.cyan)
print("GEN'S Nuclear Control")
print("Overview Dashboard")
print()

term.setTextColor(colors.white)
print(
    "Display: "
    .. tostring(displayName)
)

print(
    "Monitors detected: "
    .. tostring(monitors:count())
)

print("Press Q on the computer to stop.")

--------------------------------------------------
-- Main loop
--------------------------------------------------

local running = true

while running do
    monitors:render(
        display,
        renderDashboard
    )

    local timer =
        os.startTimer(
            REFRESH_INTERVAL
        )

    while true do
        local event, value =
            os.pullEvent()

        if event == "timer"
            and value == timer then
            break
        end

        if event == "key"
            and value == keys.q then
            running = false
            break
        end

        if event == "peripheral"
            or event
                == "peripheral_detach" then
            monitors:handlePeripheralEvent(
                event,
                value
            )

            local newDisplay,
                newDisplayName =
                monitors:getPrimary()

            if newDisplay then
                display = newDisplay
                displayName =
                    newDisplayName
            end
        end
    end
end

--------------------------------------------------
-- Shutdown
--------------------------------------------------

monitors:render(
    display,
    function()
        Layout.clear()
        Layout.centerText(
            2,
            "GEN'S NUCLEAR CONTROL",
            colors.cyan
        )

        Layout.centerText(
            4,
            "DASHBOARD STOPPED",
            colors.yellow
        )
    end
)

term.redirect(originalTerminal)
term.setTextColor(colors.white)
term.setBackgroundColor(colors.black)

print()
print("Overview dashboard stopped.")