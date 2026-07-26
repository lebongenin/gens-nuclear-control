--================================================--
-- GEN'S Nuclear Control
-- Test Library
-- Version : 0.1.0
--================================================--

local SafeCall = dofile("/core/safe_call.lua")

local Test = {}
Test.__index = Test

function Test.new(title)
    local self = setmetatable({}, Test)

    self.title = title or "GNC Test"
    self.passed = 0
    self.failed = 0

    term.clear()
    term.setCursorPos(1, 1)

    term.setTextColor(colors.cyan)
    print("GEN'S Nuclear Control")
    print(self.title)
    term.setTextColor(colors.white)

    return self
end

function Test:section(title)
    print()
    term.setTextColor(colors.cyan)
    print("================================")
    print(title)
    print("================================")
    term.setTextColor(colors.white)
end

function Test:result(name, success, details)
    if success then
        term.setTextColor(colors.lime)
        write("[PASS] ")
        self.passed = self.passed + 1
    else
        term.setTextColor(colors.red)
        write("[FAIL] ")
        self.failed = self.failed + 1
    end

    term.setTextColor(colors.white)
    print(name)

    if details then
        term.setTextColor(colors.lightGray)
        print("       " .. tostring(details))
        term.setTextColor(colors.white)
    end
end

function Test:expectTrue(name, value)
    self:result(
        name,
        value == true,
        value == true and nil
            or "expected true, got " .. tostring(value)
    )
end

function Test:expectFalse(name, value)
    self:result(
        name,
        value == false,
        value == false and nil
            or "expected false, got " .. tostring(value)
    )
end

function Test:expectEqual(name, actual, expected)
    local success = actual == expected

    self:result(
        name,
        success,
        success and nil
            or (
                "expected " .. tostring(expected)
                .. ", got " .. tostring(actual)
            )
    )
end

function Test:expectType(name, value, expectedType)
    local actualType = type(value)
    local success = actualType == expectedType

    self:result(
        name,
        success,
        success and nil
            or (
                "expected type " .. expectedType
                .. ", got " .. actualType
            )
    )
end

function Test:expectFinite(name, value)
    local success = SafeCall.isFiniteNumber(value)

    self:result(
        name,
        success,
        success and nil
            or "invalid number: " .. tostring(value)
    )
end

function Test:expectNonNegative(name, value)
    local success =
        SafeCall.isFiniteNumber(value)
        and value >= 0

    self:result(
        name,
        success,
        success and nil
            or "expected non-negative number, got "
            .. tostring(value)
    )
end

function Test:expectPercentage(name, value, allowNil)
    if value == nil and allowNil then
        self:result(name, true)
        return
    end

    local success =
        SafeCall.isFiniteNumber(value)
        and value >= 0
        and value <= 1

    self:result(
        name,
        success,
        success and nil
            or "expected value between 0 and 1, got "
            .. tostring(value)
    )
end

function Test:expectSafety(safety)
    self:expectType(
        "Safety structure",
        safety,
        "table"
    )

    if type(safety) ~= "table" then
        return
    end

    local validLevels = {
        safe = true,
        warning = true,
        critical = true,
        emergency = true
    }

    self:expectType(
        "Safety level type",
        safety.level,
        "string"
    )

    self:expectTrue(
        "Safety level valid",
        validLevels[safety.level] == true
    )

    self:expectType(
        "Safety safe flag",
        safety.safe,
        "boolean"
    )

    self:expectType(
        "Safety warnings",
        safety.warnings,
        "table"
    )

    self:expectEqual(
        "Safe flag matches level",
        safety.safe,
        safety.level == "safe"
    )
end

function Test:expectErrors(state)
    self:expectType(
        "Errors collection",
        state.errors,
        "table"
    )

    self:expectType(
        "hasErrors flag",
        state.hasErrors,
        "boolean"
    )

    if type(state.errors) == "table" then
        self:expectEqual(
            "hasErrors matches error count",
            state.hasErrors,
            #state.errors > 0
        )
    end
end

function Test:expectTank(name, tank, allowNilPercentage)
    self:section(name)

    self:expectType(
        name .. " structure",
        tank,
        "table"
    )

    if type(tank) ~= "table" then
        return
    end

    if tank.name ~= nil then
        self:expectType(
            name .. " resource name",
            tank.name,
            "string"
        )
    else
        self:result(
            name .. " may be empty",
            true
        )
    end

    self:expectNonNegative(
        name .. " amount",
        tank.amount
    )

    self:expectNonNegative(
        name .. " capacity",
        tank.capacity
    )

    self:expectNonNegative(
        name .. " needed",
        tank.needed
    )

    self:expectPercentage(
        name .. " percentage",
        tank.percentage,
        allowNilPercentage
    )
end

function Test:summary(successMessage)
    print()
    term.setTextColor(colors.cyan)
    print("================================")
    print("TEST SUMMARY")
    print("================================")

    term.setTextColor(colors.lime)
    print("Passed : " .. self.passed)

    if self.failed > 0 then
        term.setTextColor(colors.red)
    else
        term.setTextColor(colors.lime)
    end

    print("Failed : " .. self.failed)
    print()

    if self.failed == 0 then
        term.setTextColor(colors.lime)
        print(successMessage or "TEST: READY")
    else
        term.setTextColor(colors.red)
        print("TEST: FAILED")
    end

    term.setTextColor(colors.white)

    return self.failed == 0
end

return Test