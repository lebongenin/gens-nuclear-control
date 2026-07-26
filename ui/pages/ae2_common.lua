--================================================--
-- GEN'S Nuclear Control
-- UI Helper : AE2 Pages
-- Version : 0.1.0
--================================================--

local Common = {}

Common.color = colors.purple

local function drawButton(monitor, Layout, x, y, width, text, color, selected)
    local background = selected and color or colors.gray
    Layout.writeAt(monitor, x, y, string.rep(" ", width), colors.white, background)
    text = Layout.truncate(text, width)
    local textX = x + math.max(math.floor((width - #text) / 2), 0)
    Layout.writeAt(monitor, textX, y, text, colors.white, background)
end

function Common.drawPanel(monitor, Layout, cell, title, borderColor)
    Layout.panel(
        monitor,
        cell.x,
        cell.y,
        cell.width,
        cell.height,
        title,
        borderColor or Common.color
    )
end

function Common.begin(context, page, title)
    local monitor = context.monitor
    local Layout = context.layout
    local navigation = context.navigation
    local width, height = monitor.getSize()

    navigation:clearRegions(page)
    Layout.clear(monitor)
    Layout.header(monitor, "GEN'S NUCLEAR CONTROL", title)

    local backWidth = math.min(12, width)
    drawButton(monitor, Layout, 1, height, backWidth, "< BACK", Common.color, true)
    navigation:registerBackButton(1, height, backWidth, 1, {
        id = page .. "_back",
        page = page,
        monitorName = context.monitorName,
        priority = 100
    })

    local tabs = navigation:registerAE2Tabs(
        1,
        5,
        width,
        {
            page = page,
            monitorName = context.monitorName,
            height = 1,
            gap = 1,
            priority = 50
        }
    )

    for _, tab in ipairs(tabs) do
        drawButton(
            monitor,
            Layout,
            tab.x,
            tab.y,
            tab.width,
            tab.data.label,
            Common.color,
            tab.targetPage == page
        )
    end

    return width, height, 7, backWidth
end

function Common.footer(context, backWidth, text, color)
    local width, height = context.monitor.getSize()

    context.layout.writeAt(
        context.monitor,
        backWidth + 2,
        height,
        context.layout.truncate(
            text,
            math.max(width - backWidth - 1, 1)
        ),
        color or context.layout.theme.muted,
        colors.black
    )
end

return Common
