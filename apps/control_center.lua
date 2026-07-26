--================================================--
-- GEN'S Nuclear Control
-- Application : Control Center
-- Version : 0.1.0
--================================================--

local MonitorManager =
    dofile("/core/monitor_manager.lua")

local Navigation =
    dofile("/core/navigation.lua")

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

local OverviewPage =
    dofile("/ui/pages/overview.lua")

--------------------------------------------------
-- Configuration
--------------------------------------------------

local VERSION = "0.1.0"
local REFRESH_RATE = 0.5
local TEXT_SCALE = 0.5

--------------------------------------------------
-- Monitor setup
--------------------------------------------------

local manager = MonitorManager.new({
    defaultScale = TEXT_SCALE,
    primaryRole = "overview"
})

local monitor, monitorName =
    manager:getPrimary()

if not monitor then
    error("No Advanced Monitor found")
end

local scaleConfigured, scaleError =
    manager:setScale(
        monitorName,
        TEXT_SCALE
    )

if not scaleConfigured then
    error(
        "Unable to configure monitor scale: "
        .. tostring(scaleError)
    )
end

local function configureMonitor(target)
    if not target then
        return false
    end

    local success = pcall(function()
        target.setBackgroundColor(colors.black)
        target.setTextColor(colors.white)
        target.clear()
        target.setCursorPos(1, 1)
    end)

    return success
end

if not configureMonitor(monitor) then
    error("Unable to configure monitor")
end

--------------------------------------------------
-- Layout compatibility adapter
--------------------------------------------------

local function createLayoutAdapter(
    baseLayout,
    getCurrentMonitor
)
    local adapter = {}

    setmetatable(adapter, {
        __index = function(_, key)
            local value = baseLayout[key]

            if type(value) ~= "function" then
                return value
            end

            return function(...)
                local arguments = table.pack(...)

                local currentMonitor =
                    getCurrentMonitor()

                -- overview.lua passes the monitor first,
                -- while layout.lua works on term.current().
                if arguments.n > 0
                    and arguments[1]
                        == currentMonitor then

                    for index = 1,
                        arguments.n - 1 do

                        arguments[index] =
                            arguments[index + 1]
                    end

                    arguments[arguments.n] = nil
                    arguments.n =
                        arguments.n - 1
                end

                return value(
                    table.unpack(
                        arguments,
                        1,
                        arguments.n
                    )
                )
            end
        end
    })

    return adapter
end

local PageLayout =
    createLayoutAdapter(
        Layout,
        function()
            return monitor
        end
    )

--------------------------------------------------
-- Devices
--------------------------------------------------

local devices = {
    fusion = Fusion.new(),
    fission = Fission.new(),
    induction = Induction.new(),
    sps = SPS.new(),
    ae2 = AE2.new()
}

--------------------------------------------------
-- Navigation
--------------------------------------------------

local navigation = Navigation.new({
    defaultPage = "overview",
    historyLimit = 20
})

--------------------------------------------------
-- Shared context
--------------------------------------------------

local context = {
    monitor = monitor,
    monitorName = monitorName,

    manager = manager,
    layout = PageLayout,
    navigation = navigation,

    devices = devices,

    application = {
        name = "GEN'S Nuclear Control",
        version = VERSION,
        refreshRate = REFRESH_RATE
    }
}

--------------------------------------------------
-- Page helpers
--------------------------------------------------

local function pageTitle(page)
    local titles = {
        overview = "SYSTEM OVERVIEW",

        fusion = "FUSION REACTOR",
        fission = "FISSION REACTOR",
        induction = "INDUCTION MATRIX",
        sps = "SUPERCHARGED SPS",

        ae2_overview = "AE2 OVERVIEW",
        ae2_items = "AE2 ITEMS",
        ae2_cells = "AE2 CELLS",
        ae2_drives = "AE2 DRIVES",
        ae2_crafting = "AE2 CRAFTING"
    }

    return titles[page]
        or string.upper(tostring(page))
end

local function drawButton(
    x,
    y,
    width,
    text,
    backgroundColor
)
    Layout.fill(
        monitor,
        x,
        y,
        width,
        1,
        backgroundColor or colors.gray
    )

    Layout.writeAt(
        monitor,
        x,
        y,
        Layout.centerText(text, width),
        colors.white,
        backgroundColor or colors.gray
    )
end

--------------------------------------------------
-- Temporary detailed-page placeholder
--------------------------------------------------

local function drawPlaceholder(page)
    navigation:clearRegions(page)

    local width, height = monitor.getSize()

    Layout.clear(monitor)

    Layout.header(
        monitor,
        "GEN'S NUCLEAR CONTROL",
        pageTitle(page)
    )

    --------------------------------------------------
    -- Back button
    --------------------------------------------------

    local backWidth = math.min(12, width)
    local backX = math.max(width - backWidth + 1, 1)

    drawButton(
        backX,
        1,
        backWidth,
        "< BACK",
        colors.gray
    )

    navigation:registerBackButton(
        backX,
        1,
        backWidth,
        2,
        {
            id = page .. "_back",
            page = page,
            monitorName = monitorName,
            priority = 100
        }
    )

    --------------------------------------------------
    -- AE2 tabs
    --------------------------------------------------

    local contentY = 4

    if Navigation.isAE2Page(page) then
        local tabs = navigation:registerAE2Tabs(
            2,
            4,
            math.max(width - 2, 5),
            {
                page = page,
                monitorName = monitorName,
                height = 2,
                gap = 1,
                priority = 50
            }
        )

        for _, tab in ipairs(tabs) do
            local selected =
                tab.targetPage == page

            drawButton(
                tab.x,
                tab.y,
                tab.width,
                tab.data.label,
                selected
                    and colors.blue
                    or colors.gray
            )
        end

        contentY = 7
    end

    --------------------------------------------------
    -- Placeholder panel
    --------------------------------------------------

    local panelX = 2
    local panelY = contentY
    local panelWidth = math.max(width - 2, 1)
    local panelHeight = math.max(height - panelY, 3)

    Layout.panel(
        monitor,
        panelX,
        panelY,
        panelWidth,
        panelHeight,
        pageTitle(page)
    )

    local messageY =
        panelY
        + math.max(
            math.floor(panelHeight / 2) - 1,
            1
        )

    Layout.writeAt(
        monitor,
        panelX + 1,
        messageY,
        Layout.centerText(
            "DETAILED PAGE UNDER CONSTRUCTION",
            math.max(panelWidth - 2, 1)
        ),
        Layout.theme.warning
    )

    Layout.writeAt(
        monitor,
        panelX + 1,
        messageY + 2,
        Layout.centerText(
            "Touch < BACK to return",
            math.max(panelWidth - 2, 1)
        ),
        Layout.theme.muted
    )
end

--------------------------------------------------
-- Page registry
--------------------------------------------------

local pages = {
    overview = function()
        return OverviewPage.draw(context)
    end

    -- Les pages détaillées seront ajoutées ici :
    --
    -- fusion = function()
    --     return FusionPage.draw(context)
    -- end
}

--------------------------------------------------
-- Rendering
--------------------------------------------------

local lastRenderError = nil

local function drawError(err)
    navigation:clearRegions()

    local width, height = monitor.getSize()

    Layout.clear(monitor)

    Layout.header(
        monitor,
        "GEN'S NUCLEAR CONTROL",
        "CONTROL CENTER ERROR"
    )

    Layout.panel(
        monitor,
        2,
        4,
        math.max(width - 2, 1),
        math.max(height - 5, 3),
        "ERROR",
        Layout.theme.emergency
    )

    Layout.writeAt(
        monitor,
        4,
        6,
        Layout.truncate(
            tostring(err),
            math.max(width - 6, 1)
        ),
        Layout.theme.emergency
    )

    Layout.writeAt(
        monitor,
        4,
        8,
        "Automatic retry in progress...",
        Layout.theme.muted
    )
end

local function renderCurrentPage()
    local currentPage =
        navigation:getCurrentPage()

    local pageRenderer =
        pages[currentPage]

    if pageRenderer then
        return pageRenderer()
    end

    return drawPlaceholder(currentPage)
end

local function safeRender()
    local success, result =
        manager:render(
            monitor,
            renderCurrentPage
        )

    if not success then
        lastRenderError = tostring(result)

        manager:render(
            monitor,
            function()
                drawError(lastRenderError)
            end
        )

        return false, lastRenderError
    end

    lastRenderError = nil

    return true, result
end

--------------------------------------------------
-- Event handling
--------------------------------------------------

local function handleMonitorTouch(
    touchedMonitor,
    x,
    y
)
    if touchedMonitor ~= monitorName then
        return false
    end

    local result =
        navigation:handleTouch(
            touchedMonitor,
            x,
            y
        )

    return result.handled == true
end

local function handleMonitorResize(
    resizedMonitor
)
    if resizedMonitor
        and resizedMonitor ~= monitorName then
        return false
    end

    manager:refresh()

    local refreshedMonitor =
        manager:get(monitorName)

    if not refreshedMonitor then
        local fallbackMonitor,
            fallbackName =
            manager:getPrimary()

        if not fallbackMonitor then
            return false
        end

        refreshedMonitor = fallbackMonitor
        monitorName = fallbackName
        context.monitorName = fallbackName
    end

    monitor = refreshedMonitor
    context.monitor = refreshedMonitor

    local scaleConfigured =
        manager:setScale(
            monitorName,
            TEXT_SCALE
        )

    if not scaleConfigured then
        return false
    end

    configureMonitor(monitor)

    return true
end

--------------------------------------------------
-- Main loop
--------------------------------------------------

local function main()
    safeRender()

    local refreshTimer =
        os.startTimer(REFRESH_RATE)

    while true do
        local event = {
            os.pullEventRaw()
        }

        local eventName = event[1]
        local redraw = false

        if eventName == "monitor_touch" then
            redraw = handleMonitorTouch(
                event[2],
                event[3],
                event[4]
            )

        elseif eventName == "timer"
            and event[2] == refreshTimer then

            redraw = true

            refreshTimer =
                os.startTimer(REFRESH_RATE)

        elseif eventName == "monitor_resize" then
            redraw = handleMonitorResize(
                event[2]
            )

        elseif eventName == "peripheral"
    or eventName == "peripheral_detach" then

    local changed =
        manager:handlePeripheralEvent(
            eventName,
            event[2]
        )

    if changed then
        local refreshedMonitor =
            manager:get(monitorName)

        if refreshedMonitor then
            monitor = refreshedMonitor
            context.monitor = refreshedMonitor

            manager:setScale(
                monitorName,
                TEXT_SCALE
            )

            configureMonitor(monitor)
        end

        redraw = true
    end

        elseif eventName == "terminate" then
            break
        end

        if redraw then
            safeRender()
        end
    end
end

--------------------------------------------------
-- Application execution
--------------------------------------------------

local previousTerminal = term.current()

local success, err = pcall(main)

term.redirect(previousTerminal)

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

if not success then
    print("GEN'S Nuclear Control stopped:")
    print(tostring(err))
else
    print("GEN'S Nuclear Control stopped.")
end