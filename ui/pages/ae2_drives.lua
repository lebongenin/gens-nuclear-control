--================================================--
-- GEN'S Nuclear Control | AE2 Drives
-- Version : 0.1.0
--================================================--

local Common = dofile("/ui/pages/ae2_common.lua")
local Page = {}

function Page.draw(context)
    local monitor, Layout = context.monitor, context.layout
    local width, height, contentY, backWidth = Common.begin(
        context, "ae2_drives", "AE2 - ME DRIVES"
    )

    context.cache:requestDetail("ae2_drives", "ae2", "getDrives", 7000)
    local drives = context.cache:getDetail("ae2_drives")
    local panel = { x = 1, y = contentY, width = width, height = math.max(height - contentY, 4) }
    Common.drawPanel(monitor, Layout, panel, "CONNECTED DRIVES")

    if type(drives) ~= "table" then
        Layout.writeAt(monitor, 3, contentY + 2, "Loading ME Drives...", Layout.theme.warning)
        Common.footer(context, backWidth, "AE2 drives requested from background cache")
        return { loading = true }
    end

    local totalCells, populated = 0, 0
    for _, drive in ipairs(drives) do
        totalCells = totalCells + (drive.cellCount or 0)
        if (drive.cellCount or 0) > 0 then populated = populated + 1 end
    end

    local x, y = 3, contentY + 2
    local innerWidth = math.max(width - 4, 1)
    Layout.labelValue(monitor, x, y, innerWidth, "Drives", tostring(#drives))
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Populated", tostring(populated))
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Installed cells", tostring(totalCells))

    local tableY = y + 4
    local maxRows = math.max(height - tableY - 2, 0)
    local nameWidth = math.max(math.floor(innerWidth * 0.38), 8)
    Layout.writeAt(monitor, x, tableY, "DRIVE", Common.color)
    Layout.writeAt(monitor, x + nameWidth, tableY, "CELLS / PRIORITY / POSITION", Common.color)

    for index = 1, math.min(maxRows, #drives) do
        local drive = drives[index]
        local row = tableY + index
        local position = drive.position or {}
        local positionText = tostring(position.x or 0) .. "," .. tostring(position.y or 0) .. "," .. tostring(position.z or 0)
        Layout.writeAt(monitor, x, row, Layout.truncate(drive.name or ("ME Drive " .. index), nameWidth - 1), colors.white)
        Layout.writeAt(
            monitor,
            x + nameWidth,
            row,
            tostring(drive.cellCount or 0) .. " / " .. tostring(drive.priority or 0) .. " / " .. positionText,
            (drive.cellCount or 0) > 0 and Common.color or Layout.theme.muted
        )
    end

    Common.footer(context, backWidth, tostring(#drives) .. " drives | " .. tostring(totalCells) .. " storage cells")
    return { drives = drives }
end

return Page
