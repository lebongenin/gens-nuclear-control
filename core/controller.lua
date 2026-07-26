--================================================--
-- GEN'S Nuclear Control
-- Core Module : Controller
-- Version : 0.2.0
--================================================--

local Controller = {}
Controller.__index = Controller

function Controller.new(options)
    options = options or {}

    local self = setmetatable({}, Controller)

    self.cache = options.cache
    self.renderer = options.renderer
    self.navigation = options.navigation
    self.manager = options.manager
    self.monitorName = options.monitorName
    self.pollInterval = options.pollInterval or 0.5
    self.onResize = options.onResize
    self.onPeripheral = options.onPeripheral
    self.running = false
    self.pollTimer = nil

    return self
end

function Controller:refreshData()
    if not self.cache then
        return false, "Cache unavailable"
    end

    return self.cache:updateAll()
end

function Controller:refreshNextDevice()
    if not self.cache then
        return false, "Cache unavailable"
    end

    return self.cache:updateNext()
end

function Controller:render()
    if not self.renderer then
        return false, "Renderer unavailable"
    end

    return self.renderer:draw()
end

function Controller:schedulePoll()
    self.pollTimer = os.startTimer(self.pollInterval)
    return self.pollTimer
end

function Controller:handleTouch(monitorName, x, y)
    if self.monitorName and monitorName ~= self.monitorName then
        return false
    end

    local result = self.navigation:handleTouch(monitorName, x, y)

    if result.handled then
        -- Navigation renders immediately from cache: no peripheral reads here.
        self:render()
        return true, result
    end

    return false, result
end

function Controller:handleEvent(event)
    local name = event[1]

    if name == "monitor_touch" then
        return self:handleTouch(event[2], event[3], event[4])
    end

    if name == "timer" and event[2] == self.pollTimer then
        -- Only one peripheral read per tick. Touches no longer wait for a
        -- complete Fusion + Fission + Induction + SPS + AE2 polling pass.
        self:refreshNextDevice()
        self:render()
        self:schedulePoll()
        return true
    end

    if name == "monitor_resize" then
        if type(self.onResize) == "function" then
            local success, changed = pcall(self.onResize, event[2])

            if success and changed then
                self.monitorName = self.renderer.context.monitorName
                self:render()
            end

            return success and changed == true
        end

        self:render()
        return true
    end

    if name == "peripheral" or name == "peripheral_detach" then
        if type(self.onPeripheral) == "function" then
            pcall(self.onPeripheral, name, event[2])
        elseif self.manager
            and type(self.manager.handlePeripheralEvent) == "function" then
            self.manager:handlePeripheralEvent(name, event[2])
        end

        self:refreshData()
        self:render()
        return true
    end

    if name == "terminate" then
        self.running = false
        return true
    end

    return false
end

function Controller:start()
    self.running = true

    -- Initial blocking read happens once before the first screen is shown.
    self:refreshData()
    self:render()
    self:schedulePoll()

    while self.running do
        self:handleEvent({ os.pullEventRaw() })
    end

    return true
end

function Controller:stop()
    self.running = false
end

return Controller
