--================================================--
-- GEN'S Nuclear Control | AE2 Crafting
-- Version : 0.1.0
--================================================--

local Common = dofile("/ui/pages/ae2_common.lua")
local Page = {}

function Page.draw(context)
    local monitor, Layout = context.monitor, context.layout
    local width, height, contentY, backWidth = Common.begin(
        context, "ae2_crafting", "AE2 - AUTOCRAFTING"
    )

    local state = context.cache and context.cache:get("ae2") or nil
    local crafting = state and state.crafting or {}
    local cpus = type(crafting.cpus) == "table" and crafting.cpus or {}
    local tasks = type(crafting.tasks) == "table" and crafting.tasks or {}
    local grid = Layout.grid(monitor, 1, contentY, width, math.max(height - contentY, 6), 2, 1, 1)

    local cpuPanel, taskPanel = grid[1], grid[2]
    Common.drawPanel(monitor, Layout, cpuPanel, "CRAFTING CPUs")
    Common.drawPanel(monitor, Layout, taskPanel, "ACTIVE TASKS")

    local x, y = cpuPanel.x + 2, cpuPanel.y + 2
    local innerWidth = math.max(cpuPanel.width - 4, 1)
    Layout.labelValue(monitor, x, y, innerWidth, "Total", tostring(crafting.cpuCount or #cpus))
    Layout.labelValue(monitor, x, y + 1, innerWidth, "Busy", tostring(crafting.busyCPUCount or 0))
    Layout.labelValue(monitor, x, y + 2, innerWidth, "Available", tostring(crafting.freeCPUCount or 0))

    local cpuStart = y + 4
    local cpuRows = math.max(height - cpuStart - 2, 0)
    for index = 1, math.min(cpuRows, #cpus) do
        local cpu = cpus[index]
        local row = cpuStart + index - 1
        local text = (cpu.name or ("CPU " .. index))
            .. " | " .. Layout.formatNumber(cpu.storage or 0, 0)
            .. " | " .. tostring(cpu.coProcessors or 0) .. " co"
        Layout.writeAt(
            monitor, x, row, Layout.truncate(text, innerWidth),
            cpu.isBusy and Layout.theme.warning or Layout.theme.safe
        )
    end

    x, y = taskPanel.x + 2, taskPanel.y + 2
    innerWidth = math.max(taskPanel.width - 4, 1)
    Layout.labelValue(monitor, x, y, innerWidth, "Active", tostring(crafting.activeTaskCount or #tasks), {
        valueColor = #tasks > 0 and Common.color or Layout.theme.safe
    })

    local taskStart = y + 3
    local taskRows = math.max(height - taskStart - 2, 0)
    if #tasks == 0 then
        Layout.writeAt(monitor, x, taskStart, "No active crafting task", Layout.theme.muted)
    else
        for index = 1, math.min(taskRows, #tasks) do
            local task = tasks[index]
            local output = task.output or {}
            local text = (output.displayName or output.name or "Unknown craft")
                .. " x" .. tostring(output.count or task.remaining or "?")
            Layout.writeAt(monitor, x, taskStart + index - 1, Layout.truncate(text, innerWidth), colors.white)
        end
    end

    Common.footer(
        context,
        backWidth,
        tostring(crafting.busyCPUCount or 0) .. "/" .. tostring(crafting.cpuCount or #cpus)
            .. " CPUs busy | " .. tostring(crafting.activeTaskCount or #tasks) .. " active tasks"
    )

    return { cpus = cpus, tasks = tasks }
end

return Page
