--================================================--
-- GEN'S Nuclear Control
-- Core Module : Navigation
-- Version : 0.1.0
--================================================--

local Navigation = {}
Navigation.__index = Navigation

--------------------------------------------------
-- Default routes
--------------------------------------------------

local DEFAULT_PAGE = "overview"

local VALID_PAGES = {
    overview = true,

    fusion = true,
    fission = true,
    induction = true,
    sps = true,

    ae2_overview = true,
    ae2_items = true,
    ae2_cells = true,
    ae2_drives = true,
    ae2_crafting = true
}

local AE2_PAGES = {
    ae2_overview = true,
    ae2_items = true,
    ae2_cells = true,
    ae2_drives = true,
    ae2_crafting = true
}

--------------------------------------------------
-- Internal helpers
--------------------------------------------------

local function isValidCoordinate(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function normalizeCoordinate(value)
    if not isValidCoordinate(value) then
        return 0
    end

    return math.floor(value)
end

local function normalizeDimension(value)
    value = normalizeCoordinate(value)

    return math.max(value, 0)
end

local function pointInside(region, x, y)
    if type(region) ~= "table" then
        return false
    end

    return x >= region.x
        and x <= region.x + region.width - 1
        and y >= region.y
        and y <= region.y + region.height - 1
end

local function copyTable(source)
    local result = {}

    if type(source) ~= "table" then
        return result
    end

    for key, value in pairs(source) do
        result[key] = value
    end

    return result
end

--------------------------------------------------
-- Constructor
--------------------------------------------------

function Navigation.new(options)
    local self = setmetatable({}, Navigation)

    options = options or {}

    self.currentPage =
        options.defaultPage or DEFAULT_PAGE

    if not VALID_PAGES[self.currentPage] then
        self.currentPage = DEFAULT_PAGE
    end

    self.previousPage = nil
    self.lastAE2Page = "ae2_overview"

    self.regions = {}
    self.pageRegions = {}

    self.history = {
        self.currentPage
    }

    self.historyLimit =
        normalizeDimension(
            options.historyLimit or 20
        )

    if self.historyLimit <= 0 then
        self.historyLimit = 20
    end

    return self
end

--------------------------------------------------
-- Page validation
--------------------------------------------------

function Navigation.isValidPage(page)
    return VALID_PAGES[page] == true
end

function Navigation.isAE2Page(page)
    return AE2_PAGES[page] == true
end

function Navigation:getCurrentPage()
    return self.currentPage
end

function Navigation:getPreviousPage()
    return self.previousPage
end

function Navigation:getLastAE2Page()
    return self.lastAE2Page
end

--------------------------------------------------
-- Page transitions
--------------------------------------------------

function Navigation:goTo(page, options)
    options = options or {}

    if not VALID_PAGES[page] then
        return false, "Unknown page: " .. tostring(page)
    end

    if page == self.currentPage then
        return true
    end

    self.previousPage = self.currentPage
    self.currentPage = page

    if AE2_PAGES[page] then
        self.lastAE2Page = page
    end

    if options.addToHistory ~= false then
        self.history[#self.history + 1] = page

        while #self.history > self.historyLimit do
            table.remove(self.history, 1)
        end
    end

    self:clearRegions()

    return true
end

function Navigation:goOverview()
    return self:goTo("overview")
end

function Navigation:openAE2()
    return self:goTo(
        self.lastAE2Page or "ae2_overview"
    )
end

function Navigation:goBack()
    if #self.history <= 1 then
        return self:goOverview()
    end

    table.remove(self.history)

    local previous =
        self.history[#self.history]
        or DEFAULT_PAGE

    self.previousPage = self.currentPage
    self.currentPage = previous

    if AE2_PAGES[previous] then
        self.lastAE2Page = previous
    end

    self:clearRegions()

    return true
end

function Navigation:reset(page)
    page = page or DEFAULT_PAGE

    if not VALID_PAGES[page] then
        page = DEFAULT_PAGE
    end

    self.currentPage = page
    self.previousPage = nil

    if AE2_PAGES[page] then
        self.lastAE2Page = page
    end

    self.history = {
        page
    }

    self:clearRegions()
end

--------------------------------------------------
-- Region registration
--------------------------------------------------

function Navigation:registerRegion(options)
    if type(options) ~= "table" then
        return false, "Region options required"
    end

    local id = options.id

    if type(id) ~= "string" or id == "" then
        return false, "Region id required"
    end

    local region = {
        id = id,

        x = normalizeCoordinate(options.x),
        y = normalizeCoordinate(options.y),

        width = normalizeDimension(
            options.width
        ),

        height = normalizeDimension(
            options.height
        ),

        page =
            options.page
            or self.currentPage,

        targetPage = options.targetPage,

        action = options.action,

        enabled = options.enabled ~= false,

        monitorName = options.monitorName,

        data = copyTable(options.data),

        priority = normalizeCoordinate(
            options.priority or 0
        )
    }

    if region.width <= 0
        or region.height <= 0 then
        return false, "Invalid region dimensions"
    end

    if not VALID_PAGES[region.page] then
        return false, "Invalid region page"
    end

    if region.targetPage
        and not VALID_PAGES[region.targetPage] then
        return false, "Invalid target page"
    end

    self.regions[id] = region

    self.pageRegions[region.page] =
        self.pageRegions[region.page]
        or {}

    self.pageRegions[region.page][id] = region

    return true, region
end

function Navigation:registerPageLink(
    id,
    x,
    y,
    width,
    height,
    targetPage,
    options
)
    options = options or {}

    return self:registerRegion({
        id = id,

        x = x,
        y = y,
        width = width,
        height = height,

        page =
            options.page
            or self.currentPage,

        targetPage = targetPage,

        enabled = options.enabled,
        monitorName = options.monitorName,
        priority = options.priority,
        data = options.data
    })
end

function Navigation:registerAction(
    id,
    x,
    y,
    width,
    height,
    action,
    options
)
    options = options or {}

    if type(action) ~= "function" then
        return false, "Action callback required"
    end

    return self:registerRegion({
        id = id,

        x = x,
        y = y,
        width = width,
        height = height,

        page =
            options.page
            or self.currentPage,

        action = action,

        enabled = options.enabled,
        monitorName = options.monitorName,
        priority = options.priority,
        data = options.data
    })
end

function Navigation:registerBackButton(
    x,
    y,
    width,
    height,
    options
)
    options = options or {}

    return self:registerAction(
        options.id or "back",
        x,
        y,
        width,
        height,
        function()
            return self:goBack()
        end,
        options
    )
end

--------------------------------------------------
-- Region management
--------------------------------------------------

function Navigation:getRegion(id)
    return self.regions[id]
end

function Navigation:getRegions(page)
    page = page or self.currentPage

    local result = {}
    local regions = self.pageRegions[page]

    if type(regions) ~= "table" then
        return result
    end

    for _, region in pairs(regions) do
        result[#result + 1] = region
    end

    table.sort(
        result,
        function(a, b)
            if a.priority == b.priority then
                return a.id < b.id
            end

            return a.priority > b.priority
        end
    )

    return result
end

function Navigation:setRegionEnabled(
    id,
    enabled
)
    local region = self.regions[id]

    if not region then
        return false
    end

    region.enabled = enabled == true

    return true
end

function Navigation:removeRegion(id)
    local region = self.regions[id]

    if not region then
        return false
    end

    self.regions[id] = nil

    if self.pageRegions[region.page] then
        self.pageRegions[region.page][id] = nil
    end

    return true
end

function Navigation:clearRegions(page)
    if page then
        local regions = self.pageRegions[page]

        if regions then
            for id in pairs(regions) do
                self.regions[id] = nil
            end
        end

        self.pageRegions[page] = nil

        return
    end

    self.regions = {}
    self.pageRegions = {}
end

--------------------------------------------------
-- Touch lookup
--------------------------------------------------

function Navigation:findRegion(
    monitorName,
    x,
    y,
    page
)
    page = page or self.currentPage

    x = normalizeCoordinate(x)
    y = normalizeCoordinate(y)

    local regions = self:getRegions(page)

    for _, region in ipairs(regions) do
        local validMonitor =
            region.monitorName == nil
            or region.monitorName == monitorName

        if region.enabled
            and validMonitor
            and pointInside(region, x, y) then
            return region
        end
    end

    return nil
end

--------------------------------------------------
-- Touch handling
--------------------------------------------------

function Navigation:handleTouch(
    monitorName,
    x,
    y
)
    local region = self:findRegion(
        monitorName,
        x,
        y,
        self.currentPage
    )

    if not region then
        return {
            handled = false,
            page = self.currentPage
        }
    end

    local result = {
        handled = true,
        regionId = region.id,
        previousPage = self.currentPage,
        page = self.currentPage,
        data = region.data
    }

    if region.targetPage then
        local success, err =
            self:goTo(region.targetPage)

        result.success = success
        result.error = err
        result.page = self.currentPage

        return result
    end

    if type(region.action) == "function" then
        local success, value =
            pcall(
                region.action,
                region,
                monitorName,
                x,
                y
            )

        result.success = success

        if success then
            result.value = value
        else
            result.error = tostring(value)
        end

        result.page = self.currentPage

        return result
    end

    result.success = true

    return result
end

--------------------------------------------------
-- AE2 tabs
--------------------------------------------------

function Navigation:registerAE2Tabs(
    x,
    y,
    totalWidth,
    options
)
    options = options or {}

    local tabs = {
        {
            id = "ae2_tab_overview",
            label = "OVERVIEW",
            page = "ae2_overview"
        },
        {
            id = "ae2_tab_items",
            label = "ITEMS",
            page = "ae2_items"
        },
        {
            id = "ae2_tab_cells",
            label = "CELLS",
            page = "ae2_cells"
        },
        {
            id = "ae2_tab_drives",
            label = "DRIVES",
            page = "ae2_drives"
        },
        {
            id = "ae2_tab_crafting",
            label = "CRAFTING",
            page = "ae2_crafting"
        }
    }

    local gap = options.gap or 1
    local count = #tabs

    local availableWidth =
        totalWidth - gap * (count - 1)

    local baseWidth =
        math.floor(availableWidth / count)

    local remainder =
        availableWidth - baseWidth * count

    local cursorX = x
    local regions = {}

    for index, tab in ipairs(tabs) do
        local width = baseWidth

        if index <= remainder then
            width = width + 1
        end

        local success, region =
            self:registerPageLink(
                tab.id,
                cursorX,
                y,
                width,
                options.height or 1,
                tab.page,
                {
                    page =
                        options.page
                        or self.currentPage,

                    monitorName =
                        options.monitorName,

                    priority =
                        options.priority or 10,

                    data = {
                        label = tab.label,
                        targetPage = tab.page,
                        selected =
                            self.currentPage
                            == tab.page
                    }
                }
            )

        if success then
            regions[#regions + 1] = region
        end

        cursorX = cursorX + width + gap
    end

    return regions
end

--------------------------------------------------
-- Overview shortcuts
--------------------------------------------------

function Navigation:registerOverviewPanels(
    panels,
    monitorName
)
    if type(panels) ~= "table" then
        return false, "Panels table required"
    end

    local routes = {
        fusion = "fusion",
        fission = "fission",
        induction = "induction",
        sps = "sps",
        ae2 = "ae2_overview"
    }

    for id, panel in pairs(panels) do
        local targetPage = routes[id]

        if targetPage
            and type(panel) == "table" then
            local success, err =
                self:registerPageLink(
                    "overview_" .. id,
                    panel.x,
                    panel.y,
                    panel.width,
                    panel.height,
                    targetPage,
                    {
                        page = "overview",
                        monitorName = monitorName,
                        priority = 1,
                        data = {
                            system = id
                        }
                    }
                )

            if not success then
                return false, err
            end
        end
    end

    return true
end

--------------------------------------------------
-- Debug information
--------------------------------------------------

function Navigation:getDebugState()
    local regionCount = 0

    for _ in pairs(self.regions) do
        regionCount = regionCount + 1
    end

    return {
        currentPage = self.currentPage,
        previousPage = self.previousPage,
        lastAE2Page = self.lastAE2Page,

        history = copyTable(self.history),
        regionCount = regionCount
    }
end

return Navigation