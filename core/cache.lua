--================================================--
-- GEN'S Nuclear Control
-- Core Module : State Cache
-- Version : 0.2.0
--================================================--

local Cache = {}
Cache.__index = Cache

local function now()
    if os.epoch then
        return os.epoch("utc")
    end

    return math.floor(os.clock() * 1000)
end

local function countEntries(value)
    local count = 0

    for _ in pairs(value or {}) do
        count = count + 1
    end

    return count
end

function Cache.new(devices, options)
    local self = setmetatable({}, Cache)

    self.devices = devices or {}
    self.options = options or {}
    self.states = {}
    self.metadata = {}
    self.version = 0
    self.lastUpdatedAt = nil
    self.updating = false
    self.updateOrder = {}
    self.updateCursor = 0
    self.details = {}
    self.detailRequests = {}

    for name in pairs(self.devices) do
        self.updateOrder[#self.updateOrder + 1] = name
    end

    table.sort(self.updateOrder)

    return self
end

function Cache:setDevice(name, device)
    if type(name) ~= "string" or name == "" then
        return false, "Device name required"
    end

    self.devices[name] = device

    local known = false

    for _, existingName in ipairs(self.updateOrder) do
        if existingName == name then
            known = true
            break
        end
    end

    if not known then
        self.updateOrder[#self.updateOrder + 1] = name
        table.sort(self.updateOrder)
    end

    return true
end

function Cache:get(name)
    return self.states[name]
end

function Cache:getAll()
    return self.states
end

function Cache:getMetadata(name)
    return self.metadata[name]
end

function Cache:getDetail(key)
    local entry = self.details[key]
    return entry and entry.value or nil
end

function Cache:getDetailMetadata(key)
    return self.details[key]
end

function Cache:requestDetail(key, deviceName, methodName, ttl)
    if type(key) ~= "string"
        or type(deviceName) ~= "string"
        or type(methodName) ~= "string" then
        return false, "Invalid detail request"
    end

    local entry = self.details[key]
    local ttlMs = math.max(tonumber(ttl) or 5000, 0)
    local stale = not entry
        or not entry.updatedAt
        or now() - entry.updatedAt >= ttlMs

    if stale then
        self.detailRequests[key] = {
            deviceName = deviceName,
            methodName = methodName,
            ttl = ttlMs
        }
    end

    return true, entry and entry.value or nil
end

function Cache:updateRequestedDetail()
    local keys = {}

    for key in pairs(self.detailRequests) do
        keys[#keys + 1] = key
    end

    table.sort(keys)

    local key = keys[1]
    if not key then return false, nil, "No detail requested" end

    local request = self.detailRequests[key]
    self.detailRequests[key] = nil

    local device = self.devices[request.deviceName]
    local method = device and device[request.methodName]
    local success, value
    local err

    if type(method) ~= "function" then
        success = false
        err = "Detail method unavailable: " .. request.methodName
    else
        success, value = pcall(method, device)
        if not success then err = tostring(value) end
    end

    self.details[key] = {
        value = success and value or (self.details[key] and self.details[key].value),
        success = success,
        error = err,
        updatedAt = now(),
        deviceName = request.deviceName,
        methodName = request.methodName,
        ttl = request.ttl
    }

    self.version = self.version + 1
    self.lastUpdatedAt = now()

    return success, key, self.details[key].value, err
end

function Cache:getVersion()
    return self.version
end

function Cache:isReady()
    return self.version > 0
end

function Cache:updateOne(name)
    local device = self.devices[name]
    local startedAt = now()
    local state
    local err

    if type(device) ~= "table"
        or type(device.getState) ~= "function" then
        err = "Device API unavailable"
    else
        local success, result = pcall(device.getState, device)

        if success and type(result) == "table" then
            state = result
        elseif success then
            err = "getState returned " .. type(result)
        else
            err = tostring(result)
        end
    end

    if state then
        self.states[name] = state
    elseif self.states[name] == nil then
        self.states[name] = {
            connected = false,
            hasErrors = true,
            errors = {
                {
                    method = "cache",
                    message = err
                }
            },
            safety = {
                level = "offline",
                safe = false,
                warnings = { err }
            }
        }
    end

    self.metadata[name] = {
        success = state ~= nil,
        error = err,
        updatedAt = now(),
        duration = now() - startedAt,
        stale = state == nil
    }

    return state ~= nil, self.states[name], err
end

function Cache:updateAll()
    if self.updating then
        return false, "Cache update already in progress"
    end

    self.updating = true

    local report = {
        success = true,
        updated = 0,
        failed = 0,
        errors = {}
    }

    for name in pairs(self.devices) do
        local success, _, err = self:updateOne(name)

        if success then
            report.updated = report.updated + 1
        else
            report.success = false
            report.failed = report.failed + 1
            report.errors[name] = err
        end

    end

    self.updating = false
    self.version = self.version + 1
    self.lastUpdatedAt = now()
    report.version = self.version
    report.deviceCount = countEntries(self.devices)

    return report.success, report
end

-- Update a single peripheral per cycle. This keeps monitor_touch events
-- responsive even when one mod exposes comparatively slow getters.
function Cache:updateNext()
    if self.updating then
        return false, nil, "Cache update already in progress"
    end

    if next(self.detailRequests) then
        return self:updateRequestedDetail()
    end

    if #self.updateOrder == 0 then
        return false, nil, "No devices registered"
    end

    self.updateCursor = self.updateCursor + 1

    if self.updateCursor > #self.updateOrder then
        self.updateCursor = 1
    end

    local name = self.updateOrder[self.updateCursor]

    self.updating = true
    local success, state, err = self:updateOne(name)
    self.updating = false

    self.version = self.version + 1
    self.lastUpdatedAt = now()

    return success, name, state, err
end

function Cache:invalidate(name)
    if name then
        self.states[name] = nil
        self.metadata[name] = nil
    else
        self.states = {}
        self.metadata = {}
        self.details = {}
        self.detailRequests = {}
        self.version = 0
        self.lastUpdatedAt = nil
    end
end

function Cache:getDebugState()
    return {
        version = self.version,
        lastUpdatedAt = self.lastUpdatedAt,
        updating = self.updating,
        deviceCount = countEntries(self.devices),
        stateCount = countEntries(self.states),
        metadata = self.metadata
    }
end

return Cache
