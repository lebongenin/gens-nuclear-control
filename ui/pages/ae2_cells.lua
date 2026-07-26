--================================================--
-- GEN'S Nuclear Control | AE2 Cells
-- Version : 0.1.0
--================================================--

local Common = dofile("/ui/pages/ae2_common.lua")
local Page = {}

function Page.draw(context)
    local monitor, Layout = context.monitor, context.layout
    local width, height, contentY, backWidth = Common.begin(
        context, "ae2_cells", "AE2 - STORAGE CELLS"
    )

    context.cache:requestDetail("ae2_cells", "ae2", "getCells", 5000)
    local cells = context.cache:getDetail("ae2_cells")
    local panel = { x = 1, y = contentY, width = width, height = math.max(height - contentY, 4) }
    Common.drawPanel(monitor, Layout, panel, "INSTALLED CELLS")

    if type(cells) ~= "table" then
        Layout.writeAt(monitor, 3, contentY + 2, "Loading storage cells...", Layout.theme.warning)
        Common.footer(context, backWidth, "AE2 cells requested from background cache")
        return { loading = true }
    end

    local total, used, types = 0, 0, 0
    for _, cell in ipairs(cells) do
        total = total + (cell.bytes or 0)
        used = used + (cell.usedBytes or 0)
        types = types + (cell.totalTypes or 0)
    end

    local x, y = 3, contentY + 2
    local innerWidth = math.max(width - 4, 1)
    Layout.labelValue(monitor, x, y, innerWidth, "Cells", tostring(#cells))
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Combined usage", Layout.formatPercent(total > 0 and used / total or 0))
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Stored types", tostring(types))

    local tableY = y + 4
    local maxRows = math.max(height - tableY - 2, 0)
    local nameWidth = math.max(math.floor(innerWidth * 0.45), 8)
    Layout.writeAt(monitor, x, tableY, "CELL", Common.color)
    Layout.writeAt(monitor, x + nameWidth, tableY, "USED", Common.color)

    for index = 1, math.min(maxRows, #cells) do
        local cell = cells[index]
        local row = tableY + index
        local name = cell.itemName or cell.type or ("Cell " .. index)
        local percentage = cell.percentage or 0
        Layout.writeAt(monitor, x, row, Layout.truncate(name, nameWidth - 1), colors.white)
        Layout.writeAt(
            monitor,
            x + nameWidth,
            row,
            Layout.formatPercent(percentage) .. " | " .. tostring(cell.totalTypes or 0) .. " types",
            percentage >= 0.95 and Layout.theme.emergency
                or percentage >= 0.80 and Layout.theme.warning
                or Layout.theme.muted
        )
    end

    Common.footer(context, backWidth, tostring(#cells) .. " cells | " .. Layout.formatNumber(used, 0) .. "/" .. Layout.formatNumber(total, 0) .. " bytes")
    return { cells = cells }
end

return Page
