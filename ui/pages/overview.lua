--================================================--
-- GEN'S Nuclear Control
-- UI Page : Overview
-- Version : 0.1.0
--================================================--

local Overview = {}

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function getSafetyLevel(state)
    if not state or not state.connected then
        return "offline"
    end

    if state.safety and state.safety.level then
        return state.safety.level
    end

    return "safe"
end

local function getStatusText(state, activeField)
    if not state or not state.connected then
        return "OFFLINE"
    end

    if state.formed == false then
        return "UNFORMED"
    end

    if activeField and state[activeField] == false then
        return "IDLE"
    end

    return "ACTIVE"
end

local function drawSystemHeader(
    monitor,
    Layout,
    x,
    y,
    width,
    title,
    status,
    level
)
    Layout.writeAt(
        monitor,
        x,
        y,
        Layout.truncate(title, math.max(width - 12, 1)),
        Layout.theme.title
    )

    local badge = " " .. status .. " "

    Layout.statusBadge(
        monitor,
        x + width - #badge,
        y,
        status,
        level
    )
end

local function drawUnavailable(
    monitor,
    Layout,
    x,
    y,
    message
)
    Layout.writeAt(
        monitor,
        x,
        y,
        message or "Peripheral unavailable",
        Layout.theme.emergency
    )
end

--------------------------------------------------
-- Fusion panel
--------------------------------------------------

local function drawFusion(
    monitor,
    Layout,
    cell,
    state
)
    Layout.panel(
        monitor,
        cell.x,
        cell.y,
        cell.width,
        cell.height,
        "FUSION"
    )

    local innerX = cell.x + 2
    local innerY = cell.y + 2
    local innerWidth = math.max(cell.width - 4, 1)

    drawSystemHeader(
        monitor,
        Layout,
        innerX,
        innerY,
        innerWidth,
        "Fusion Reactor",
        getStatusText(state, "ignited"),
        getSafetyLevel(state)
    )

    if not state or not state.connected then
        drawUnavailable(
            monitor,
            Layout,
            innerX,
            innerY + 2
        )

        return
    end

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 2,
        innerWidth,
        "Production",
        Layout.formatNumber(
            state.productionRate,
            1
        ) .. " FE/t"
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 3,
        innerWidth,
        "Injection",
        Layout.formatNumber(
            state.injectionRate,
            1
        )
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 4,
        innerWidth,
        "D-T Fuel",
        Layout.formatPercent(
            state.dtFuel.percentage
        )
    )

    Layout.progressBar(
        monitor,
        innerX,
        innerY + 6,
        innerWidth,
        state.dtFuel.percentage,
        {
            lowIsDanger = true
        }
    )
end

--------------------------------------------------
-- Fission panel
--------------------------------------------------

local function drawFission(
    monitor,
    Layout,
    cell,
    state
)
    Layout.panel(
        monitor,
        cell.x,
        cell.y,
        cell.width,
        cell.height,
        "FISSION"
    )

    local innerX = cell.x + 2
    local innerY = cell.y + 2
    local innerWidth = math.max(cell.width - 4, 1)

    drawSystemHeader(
        monitor,
        Layout,
        innerX,
        innerY,
        innerWidth,
        "Fission Reactor",
        getStatusText(state, "active"),
        getSafetyLevel(state)
    )

    if not state or not state.connected then
        drawUnavailable(
            monitor,
            Layout,
            innerX,
            innerY + 2
        )

        return
    end

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 2,
        innerWidth,
        "Temperature",
        Layout.formatNumber(
            state.temperature,
            1
        ) .. " K"
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 3,
        innerWidth,
        "Burn",
        Layout.formatNumber(
            state.actualBurnRate,
            2
        )
        .. "/"
        .. Layout.formatNumber(
            state.maxBurnRate,
            1
        )
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 4,
        innerWidth,
        "Damage",
        string.format(
            "%.1f%%",
            state.damagePercent
        ),
        state.damagePercent > 0
            and Layout.theme.warning
            or Layout.theme.safe
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 5,
        innerWidth,
        "Coolant",
        Layout.formatPercent(
            state.coolant.percentage
        )
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 6,
        innerWidth,
        "Waste",
        Layout.formatPercent(
            state.waste.percentage
        )
    )
end

--------------------------------------------------
-- Induction panel
--------------------------------------------------

local function drawInduction(
    monitor,
    Layout,
    cell,
    state
)
    Layout.panel(
        monitor,
        cell.x,
        cell.y,
        cell.width,
        cell.height,
        "INDUCTION"
    )

    local innerX = cell.x + 2
    local innerY = cell.y + 2
    local innerWidth = math.max(cell.width - 4, 1)

    drawSystemHeader(
        monitor,
        Layout,
        innerX,
        innerY,
        innerWidth,
        "Induction Matrix",
        getStatusText(state),
        getSafetyLevel(state)
    )

    if not state or not state.connected then
        drawUnavailable(
            monitor,
            Layout,
            innerX,
            innerY + 2
        )

        return
    end

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 2,
        innerWidth,
        "Stored",
        Layout.formatNumber(
            state.energy,
            2
        ) .. " FE"
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 3,
        innerWidth,
        "Capacity",
        Layout.formatNumber(
            state.capacity,
            2
        ) .. " FE"
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 4,
        innerWidth,
        "Input",
        Layout.formatNumber(
            state.input,
            1
        ) .. " FE/t"
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 5,
        innerWidth,
        "Output",
        Layout.formatNumber(
            state.output,
            1
        ) .. " FE/t"
    )

    Layout.progressBar(
        monitor,
        innerX,
        innerY + 7,
        innerWidth,
        state.percentage,
        {
            lowIsDanger = true
        }
    )
end

--------------------------------------------------
-- SPS panel
--------------------------------------------------

local function drawSPS(
    monitor,
    Layout,
    cell,
    state
)
    Layout.panel(
        monitor,
        cell.x,
        cell.y,
        cell.width,
        cell.height,
        "SPS"
    )

    local innerX = cell.x + 2
    local innerY = cell.y + 2
    local innerWidth = math.max(cell.width - 4, 1)

    drawSystemHeader(
        monitor,
        Layout,
        innerX,
        innerY,
        innerWidth,
        "Antimatter",
        getStatusText(state),
        getSafetyLevel(state)
    )

    if not state or not state.connected then
        drawUnavailable(
            monitor,
            Layout,
            innerX,
            innerY + 2
        )

        return
    end

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 2,
        innerWidth,
        "Process",
        Layout.formatNumber(
            state.processRate,
            3
        )
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 3,
        innerWidth,
        "Coils",
        tostring(state.coils)
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 4,
        innerWidth,
        "Polonium",
        Layout.formatPercent(
            state.input.percentage
        )
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 5,
        innerWidth,
        "Antimatter",
        Layout.formatPercent(
            state.output.percentage
        )
    )

    Layout.progressBar(
        monitor,
        innerX,
        innerY + 7,
        innerWidth,
        state.output.percentage,
        {
            highIsDanger = true
        }
    )
end

--------------------------------------------------
-- AE2 panel
--------------------------------------------------

local function drawAE2(
    monitor,
    Layout,
    cell,
    state
)
    Layout.panel(
        monitor,
        cell.x,
        cell.y,
        cell.width,
        cell.height,
        "AE2"
    )

    local innerX = cell.x + 2
    local innerY = cell.y + 2
    local innerWidth = math.max(cell.width - 4, 1)

    local status = "OFFLINE"

    if state
        and state.connected
        and state.networkConnected
        and state.online then
        status = "ACTIVE"
    end

    drawSystemHeader(
        monitor,
        Layout,
        innerX,
        innerY,
        innerWidth,
        state and state.name or "ME Network",
        status,
        getSafetyLevel(state)
    )

    if not state or not state.connected then
        drawUnavailable(
            monitor,
            Layout,
            innerX,
            innerY + 2,
            "ME Bridge unavailable"
        )

        return
    end

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 2,
        innerWidth,
        "Storage",
        Layout.formatPercent(
            state.itemStorage.percentage
        )
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 3,
        innerWidth,
        "Energy",
        Layout.formatPercent(
            state.energy.percentage
        )
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 4,
        innerWidth,
        "Usage",
        Layout.formatNumber(
            state.energy.usage,
            1
        ) .. " AE/t"
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 5,
        innerWidth,
        "CPUs",
        tostring(
            state.crafting.busyCPUCount
        )
        .. "/"
        .. tostring(
            state.crafting.cpuCount
        )
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 6,
        innerWidth,
        "Tasks",
        tostring(
            state.crafting.activeTaskCount
        )
    )
end

--------------------------------------------------
-- System summary panel
--------------------------------------------------

local function drawSystem(
    monitor,
    Layout,
    cell,
    states,
    monitorName
)
    Layout.panel(
        monitor,
        cell.x,
        cell.y,
        cell.width,
        cell.height,
        "SYSTEM"
    )

    local innerX = cell.x + 2
    local innerY = cell.y + 2
    local innerWidth = math.max(cell.width - 4, 1)

    local warningCount = 0
    local disconnectedCount = 0
    local worstLevel = "safe"

    local priorities = {
        safe = 1,
        warning = 2,
        critical = 3,
        emergency = 4,
        offline = 4
    }

    for _, state in pairs(states) do
        if not state or not state.connected then
            disconnectedCount =
                disconnectedCount + 1
        end

        if state
            and state.safety
            and state.safety.warnings then
            warningCount =
                warningCount
                + #state.safety.warnings
        end

        local level = getSafetyLevel(state)

        if priorities[level] > priorities[worstLevel] then
            worstLevel = level
        end
    end

    drawSystemHeader(
        monitor,
        Layout,
        innerX,
        innerY,
        innerWidth,
        "Control Center",
        worstLevel == "safe"
            and "SAFE"
            or string.upper(worstLevel),
        worstLevel
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 2,
        innerWidth,
        "Warnings",
        tostring(warningCount),
        warningCount > 0
            and Layout.theme.warning
            or Layout.theme.safe
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 3,
        innerWidth,
        "Devices",
        tostring(
            5 - disconnectedCount
        ) .. "/5"
    )

    Layout.labelValue(
        monitor,
        innerX,
        innerY + 4,
        innerWidth,
        "Monitor",
        tostring(
            monitorName or "unknown"
        )
    )

    Layout.writeAt(
        monitor,
        innerX,
        innerY + 6,
        "Touch a panel for details",
        Layout.theme.muted
    )
end

--------------------------------------------------
-- Main page draw
--------------------------------------------------

function Overview.draw(context)
    if type(context) ~= "table" then
        error("Overview context required")
    end

    local monitor = context.monitor
    local Layout = context.layout
    local navigation = context.navigation
    local devices = context.devices
    local monitorName = context.monitorName

    if not monitor then
        error("Overview monitor required")
    end

    if not Layout then
        error("Overview layout required")
    end

    if not navigation then
        error("Overview navigation required")
    end

    if type(devices) ~= "table" then
        error("Overview devices required")
    end

    navigation:clearRegions("overview")

    local width, height = monitor.getSize()

    local states = {
        fusion = devices.fusion:getState(),
        fission = devices.fission:getState(),
        induction = devices.induction:getState(),
        sps = devices.sps:getState(),
        ae2 = devices.ae2:getState()
    }

    Layout.clear(monitor)

    Layout.header(
        monitor,
        "GEN'S NUCLEAR CONTROL",
        "SYSTEM OVERVIEW"
    )

    local contentY = 4
    local contentHeight = math.max(
        height - contentY,
        1
    )

    local cells = Layout.grid(
        1,
        contentY,
        width,
        contentHeight,
        3,
        2,
        1
    )

    local panels = {
        fusion = cells[1],
        fission = cells[2],
        induction = cells[3],
        sps = cells[4],
        ae2 = cells[5],
        system = cells[6]
    }

    drawFusion(
        monitor,
        Layout,
        panels.fusion,
        states.fusion
    )

    drawFission(
        monitor,
        Layout,
        panels.fission,
        states.fission
    )

    drawInduction(
        monitor,
        Layout,
        panels.induction,
        states.induction
    )

    drawSPS(
        monitor,
        Layout,
        panels.sps,
        states.sps
    )

    drawAE2(
        monitor,
        Layout,
        panels.ae2,
        states.ae2
    )

    drawSystem(
        monitor,
        Layout,
        panels.system,
        states,
        monitorName
    )

    navigation:registerOverviewPanels(
        {
            fusion = panels.fusion,
            fission = panels.fission,
            induction = panels.induction,
            sps = panels.sps,
            ae2 = panels.ae2
        },
        monitorName
    )

    return {
        states = states,
        panels = panels,
        width = width,
        height = height
    }
end

return Overview