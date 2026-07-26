--================================================--
-- GEN'S Nuclear Control
-- Core Module : Safe Call
-- Version : 0.1.0
--================================================--

local SafeCall = {}

--------------------------------------------------
-- Internal helpers
--------------------------------------------------

local function isFiniteNumber(value)
    if type(value) ~= "number" then
        return false
    end

    -- NaN est le seul nombre différent de lui-même.
    if value ~= value then
        return false
    end

    -- Protection contre les valeurs infinies.
    if value == math.huge or value == -math.huge then
        return false
    end

    return true
end

local function packResults(...)
    return {
        n = select("#", ...),
        ...
    }
end

--------------------------------------------------
-- Public validation helpers
--------------------------------------------------

function SafeCall.isFiniteNumber(value)
    return isFiniteNumber(value)
end

function SafeCall.number(value, fallback)
    if isFiniteNumber(value) then
        return value
    end

    return fallback
end

function SafeCall.boolean(value, fallback)
    if type(value) == "boolean" then
        return value
    end

    return fallback
end

function SafeCall.string(value, fallback)
    if type(value) == "string" then
        return value
    end

    return fallback
end

function SafeCall.table(value, fallback)
    if type(value) == "table" then
        return value
    end

    return fallback
end

--------------------------------------------------
-- Safe method detection
--------------------------------------------------

function SafeCall.hasMethod(device, methodName)
    if type(device) ~= "table" then
        return false
    end

    if type(methodName) ~= "string" then
        return false
    end

    return type(device[methodName]) == "function"
end

--------------------------------------------------
-- Raw safe call
--------------------------------------------------

function SafeCall.raw(device, methodName, ...)
    if device == nil then
        return false, nil, "Peripheral unavailable"
    end

    if type(methodName) ~= "string" then
        return false, nil, "Invalid method name"
    end

    local method = device[methodName]

    if type(method) ~= "function" then
        return false, nil, "Method unavailable: " .. methodName
    end

    local arguments = packResults(...)

    local results = packResults(
        pcall(
            method,
            table.unpack(arguments, 1, arguments.n)
        )
    )

    if not results[1] then
        return false, nil, tostring(results[2])
    end

    local resultCount = results.n - 1

    if resultCount == 0 then
        return true, nil, nil
    end

    if resultCount == 1 then
        return true, results[2], nil
    end

    local values = {}

    for index = 2, results.n do
        values[#values + 1] = results[index]
    end

    return true, values, nil
end

--------------------------------------------------
-- Structured safe call
--------------------------------------------------

function SafeCall.call(device, methodName, ...)
    local success, value, err = SafeCall.raw(
        device,
        methodName,
        ...
    )

    return {
        success = success,
        value = value,
        error = err,
        method = methodName
    }
end

--------------------------------------------------
-- Typed calls
--------------------------------------------------

function SafeCall.getNumber(device, methodName, fallback, ...)
    local success, value, err = SafeCall.raw(
        device,
        methodName,
        ...
    )

    if not success then
        return fallback, err
    end

    if not isFiniteNumber(value) then
        return fallback, "Invalid numeric value returned by " .. methodName
    end

    return value, nil
end

function SafeCall.getBoolean(device, methodName, fallback, ...)
    local success, value, err = SafeCall.raw(
        device,
        methodName,
        ...
    )

    if not success then
        return fallback, err
    end

    if type(value) ~= "boolean" then
        return fallback, "Invalid boolean value returned by " .. methodName
    end

    return value, nil
end

function SafeCall.getString(device, methodName, fallback, ...)
    local success, value, err = SafeCall.raw(
        device,
        methodName,
        ...
    )

    if not success then
        return fallback, err
    end

    if type(value) ~= "string" then
        return fallback, "Invalid string value returned by " .. methodName
    end

    return value, nil
end

function SafeCall.getTable(device, methodName, fallback, ...)
    local success, value, err = SafeCall.raw(
        device,
        methodName,
        ...
    )

    if not success then
        return fallback, err
    end

    if type(value) ~= "table" then
        return fallback, "Invalid table value returned by " .. methodName
    end

    return value, nil
end

--------------------------------------------------
-- Percentage helpers
--------------------------------------------------

function SafeCall.normalizePercentage(value, fallback)
    if not isFiniteNumber(value) then
        return fallback
    end

    if value < 0 then
        return 0
    end

    if value > 1 then
        return 1
    end

    return value
end

function SafeCall.getPercentage(device, methodName, fallback, ...)
    local value, err = SafeCall.getNumber(
        device,
        methodName,
        fallback,
        ...
    )

    if value == fallback and err then
        return fallback, err
    end

    return SafeCall.normalizePercentage(value, fallback), nil
end

function SafeCall.calculatePercentage(amount, capacity, fallback)
    if not isFiniteNumber(amount) then
        return fallback
    end

    if not isFiniteNumber(capacity) or capacity <= 0 then
        return fallback
    end

    return SafeCall.normalizePercentage(
        amount / capacity,
        fallback
    )
end

--------------------------------------------------
-- Resource helpers
--------------------------------------------------

function SafeCall.normalizeResource(value)
    if type(value) ~= "table" then
        return {
            name = nil,
            amount = 0
        }
    end

    local name = value.name

    if type(name) ~= "string" then
        name = nil
    end

    local amount = value.amount

    if not isFiniteNumber(amount) then
        amount = 0
    end

    return {
        name = name,
        amount = amount
    }
end

function SafeCall.getResource(device, methodName, ...)
    local value, err = SafeCall.getTable(
        device,
        methodName,
        nil,
        ...
    )

    if not value then
        return {
            name = nil,
            amount = 0
        }, err
    end

    return SafeCall.normalizeResource(value), nil
end

--------------------------------------------------
-- Error collection
--------------------------------------------------

function SafeCall.addError(errors, methodName, err)
    if type(errors) ~= "table" or not err then
        return
    end

    errors[#errors + 1] = {
        method = methodName,
        message = tostring(err)
    }
end

return SafeCall