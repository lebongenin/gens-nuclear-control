--================================================--
-- GEN'S Nuclear Control
-- Core Module : Renderer
-- Version : 0.2.0
--================================================--

local Renderer = {}
Renderer.__index = Renderer

function Renderer.new(options)
    options = options or {}

    local self = setmetatable({}, Renderer)

    self.manager = options.manager
    self.monitor = options.monitor
    self.context = options.context or {}
    self.navigation = options.navigation
    self.pages = options.pages or {}
    self.placeholder = options.placeholder
    self.errorRenderer = options.errorRenderer
    self.lastError = nil
    self.lastPage = nil
    self.renderCount = 0

    return self
end

function Renderer:setMonitor(monitor, monitorName)
    self.monitor = monitor
    self.context.monitor = monitor

    if monitorName then
        self.context.monitorName = monitorName
    end
end

function Renderer:registerPage(name, renderer)
    if type(name) ~= "string" or type(renderer) ~= "function" then
        return false, "Page name and renderer required"
    end

    self.pages[name] = renderer
    return true
end

function Renderer:getPageRenderer(page)
    return self.pages[page]
end

function Renderer:draw(page)
    page = page or (
        self.navigation
        and self.navigation:getCurrentPage()
    ) or "overview"

    local callback = self.pages[page]

    if not callback then
        callback = function()
            if type(self.placeholder) == "function" then
                return self.placeholder(page, self.context)
            end

            error("No renderer registered for page: " .. tostring(page))
        end
    end

    local function performRender()
        return callback(self.context)
    end

    local success, result

    if self.manager and type(self.manager.render) == "function" then
        success, result = self.manager:render(
            self.monitor,
            performRender
        )
    else
        success, result = pcall(performRender)
    end

    if not success then
        self.lastError = tostring(result)

        if type(self.errorRenderer) == "function" then
            local function showError()
                return self.errorRenderer(
                    self.lastError,
                    self.context
                )
            end

            if self.manager and type(self.manager.render) == "function" then
                pcall(self.manager.render, self.manager, self.monitor, showError)
            else
                pcall(showError)
            end
        end

        return false, self.lastError
    end

    self.lastError = nil
    self.lastPage = page
    self.renderCount = self.renderCount + 1

    return true, result
end

function Renderer:getDebugState()
    return {
        lastError = self.lastError,
        lastPage = self.lastPage,
        renderCount = self.renderCount
    }
end

return Renderer
