--================================================--
-- GEN'S Nuclear Control | AE2 Items
-- Version : 0.1.0
--================================================--

local Common = dofile("/ui/pages/ae2_common.lua")
local Page = {}

function Page.draw(context)
    local monitor, Layout = context.monitor, context.layout
    local width, height, contentY, backWidth = Common.begin(
        context, "ae2_items", "AE2 - STORED ITEMS"
    )

    context.cache:requestDetail("ae2_items", "ae2", "getItems", 5000)
    local items = context.cache:getDetail("ae2_items")

    local cell = { x = 1, y = contentY, width = width, height = math.max(height - contentY, 4) }
    Common.drawPanel(monitor, Layout, cell, "TOP STORED ITEMS")

    if type(items) ~= "table" then
        Layout.writeAt(monitor, 3, contentY + 2, "Loading item list...", Layout.theme.warning)
        Common.footer(context, backWidth, "AE2 items requested from background cache")
        return { loading = true }
    end

    local sorted = {}
    local totalCount = 0
    for _, item in ipairs(items) do
        sorted[#sorted + 1] = item
        totalCount = totalCount + (item.count or 0)
    end
    table.sort(sorted, function(a, b) return (a.count or 0) > (b.count or 0) end)

    local x, y = 3, contentY + 2
    local innerWidth = math.max(width - 4, 1)
    local countWidth = math.min(16, math.floor(innerWidth * 0.25))
    local nameWidth = math.max(innerWidth - countWidth - 2, 1)

    Layout.writeAt(monitor, x, y, Layout.truncate("ITEM", nameWidth), Common.color)
    Layout.writeAt(monitor, x + nameWidth + 2, y, "COUNT", Common.color)

    local maxRows = math.max(height - y - 3, 0)
    for index = 1, math.min(maxRows, #sorted) do
        local item = sorted[index]
        local row = y + index
        local name = item.displayName or item.name or "Unknown item"
        Layout.writeAt(monitor, x, row, Layout.truncate(name, nameWidth), colors.white)
        Layout.writeAt(
            monitor,
            x + nameWidth + 2,
            row,
            Layout.formatNumber(item.count or 0, 0),
            index <= 3 and Common.color or Layout.theme.muted
        )
    end

    Common.footer(
        context,
        backWidth,
        tostring(#items) .. " item types | " .. Layout.formatNumber(totalCount, 0) .. " total items"
    )

    return { items = items, sorted = sorted }
end

return Page
