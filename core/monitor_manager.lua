--================================================--
-- GEN'S Nuclear Control
-- Core Module : Monitor Manager
-- Version : 0.1.0
--================================================--

local MonitorManager = {}
MonitorManager.__index = MonitorManager

local MONITOR_TYPE = "monitor"

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function isMonitor(name)
    if type(name) ~= "string" then
        return false
    end

    if not peripheral.isPresent(name) then
        return false
    end

    if peripheral.hasType then
        return peripheral.hasType(
            name,
            MONITOR_TYPE
        )
    end

    return peripheral.getType(name) == MONITOR_TYPE
end

local function safeGetSize(target)
    if not target
        or type(target.getSize) ~= "function" then
        return 0, 0
    end

    local success, width, height = pcall(
        target.getSize
    )

    if not success then
        return 0, 0
    end

    return width or 0, height or 0
end

local function safeSetTextScale(
    monitor,
    scale
)
    if not monitor
        or type(monitor.setTextScale)
            ~= "function" then
        return false
    end

    if type(scale) ~= "number" then
        return false
    end

    return pcall(
        monitor.setTextScale,
        scale
    )
end

--------------------------------------------------
-- Constructor
--------------------------------------------------

function MonitorManager.new(options)
    local self = setmetatable(
        {},
        MonitorManager
    )

    options = options or {}

    self.defaultScale =
        options.defaultScale or 0.5

    self.monitors = {}
    self.order = {}
    self.roles = {}

    self.primaryRole =
        options.primaryRole or "overview"

    self.originalTerminal = term.current()

    self:discover()

    return self
end

--------------------------------------------------
-- Discovery
--------------------------------------------------

function MonitorManager:discover()
    self.monitors = {}
    self.order = {}

    for _, name in ipairs(
        peripheral.getNames()
    ) do
        if isMonitor(name) then
            local wrapped =
                peripheral.wrap(name)

            local width, height =
                safeGetSize(wrapped)

            self.monitors[name] = {
                name = name,
                peripheral = wrapped,
                width = width,
                height = height,
                scale = nil
            }

            self.order[#self.order + 1] =
                name
        end
    end

    table.sort(self.order)

    return #self.order
end

function MonitorManager:refresh()
    local previousRoles = self.roles

    self:discover()

    self.roles = {}

    for role, monitorName in pairs(
        previousRoles
    ) do
        if self.monitors[monitorName] then
            self.roles[role] = monitorName
        end
    end

    return #self.order
end

--------------------------------------------------
-- Monitor information
--------------------------------------------------

function MonitorManager:count()
    return #self.order
end

function MonitorManager:getNames()
    local result = {}

    for index, name in ipairs(
        self.order
    ) do
        result[index] = name
    end

    return result
end

function MonitorManager:has(name)
    return self.monitors[name] ~= nil
end

function MonitorManager:get(name)
    local entry = self.monitors[name]

    if entry then
        return entry.peripheral
    end

    return nil
end

function MonitorManager:getEntry(name)
    return self.monitors[name]
end

function MonitorManager:getFirst()
    local name = self.order[1]

    if not name then
        return nil, nil
    end

    return self:get(name), name
end

--------------------------------------------------
-- Role assignment
--------------------------------------------------

function MonitorManager:assign(
    role,
    monitorName
)
    if type(role) ~= "string"
        or role == "" then
        return false,
            "Invalid monitor role"
    end

    if not self.monitors[monitorName] then
        return false,
            "Monitor unavailable: "
            .. tostring(monitorName)
    end

    self.roles[role] = monitorName

    return true
end

function MonitorManager:autoAssign()
    local roles = {
        "overview",
        "fusion",
        "fission",
        "sps",
        "ae2"
    }

    for index, role in ipairs(roles) do
        local monitorName =
            self.order[index]

        if monitorName then
            self.roles[role] =
                monitorName
        end
    end

    return self.roles
end

function MonitorManager:getRoleName(role)
    return self.roles[role]
end

function MonitorManager:getRole(role)
    local monitorName =
        self.roles[role]

    if not monitorName then
        return nil, nil
    end

    return self:get(monitorName),
        monitorName
end

function MonitorManager:getPrimary()
    local monitor, name =
        self:getRole(self.primaryRole)

    if monitor then
        return monitor, name
    end

    return self:getFirst()
end

--------------------------------------------------
-- Configuration
--------------------------------------------------

function MonitorManager:setScale(
    monitorName,
    scale
)
    local entry =
        self.monitors[monitorName]

    if not entry then
        return false,
            "Monitor unavailable"
    end

    local success =
        safeSetTextScale(
            entry.peripheral,
            scale
        )

    if not success then
        return false,
            "Unable to set text scale"
    end

    entry.scale = scale
    entry.width,
    entry.height =
        safeGetSize(entry.peripheral)

    return true
end

function MonitorManager:setAllScales(scale)
    local results = {}

    for _, name in ipairs(
        self.order
    ) do
        local success, err =
            self:setScale(name, scale)

        results[name] = {
            success = success,
            error = err
        }
    end

    return results
end

function MonitorManager:configureDefaults()
    return self:setAllScales(
        self.defaultScale
    )
end

--------------------------------------------------
-- Rendering
--------------------------------------------------

function MonitorManager:redirect(target)
    if type(target) == "string" then
        target = self:get(target)
    end

    if not target then
        return false,
            "Invalid terminal target"
    end

    term.redirect(target)

    return true
end

function MonitorManager:restore()
    if self.originalTerminal then
        term.redirect(
            self.originalTerminal
        )
    end
end

function MonitorManager:render(
    target,
    callback,
    ...
)
    if type(callback) ~= "function" then
        return false,
            "Render callback required"
    end

    if type(target) == "string" then
        target = self:get(target)
    end

    if not target then
        return false,
            "Monitor unavailable"
    end

    local previous = term.current()

    term.redirect(target)

    local results = table.pack(
        pcall(callback, ...)
    )

    term.redirect(previous)

    if not results[1] then
        return false,
            tostring(results[2])
    end

    if results.n == 1 then
        return true
    end

    if results.n == 2 then
        return true, results[2]
    end

    local values = {}

    for index = 2, results.n do
        values[#values + 1] =
            results[index]
    end

    return true, values
end

function MonitorManager:renderRole(
    role,
    callback,
    ...
)
    local monitor, monitorName =
        self:getRole(role)

    if not monitor then
        return false,
            "No monitor assigned to role "
            .. tostring(role)
    end

    return self:render(
        monitor,
        callback,
        ...
    )
end

--------------------------------------------------
-- Events
--------------------------------------------------

function MonitorManager:handlePeripheralEvent(
    event,
    side
)
    if event ~= "peripheral"
        and event
            ~= "peripheral_detach" then
        return false
    end

    if event == "peripheral"
        and isMonitor(side) then
        self:refresh()

        return true
    end

    if event == "peripheral_detach"
        and self.monitors[side] then
        self:refresh()

        return true
    end

    return false
end

return MonitorManager