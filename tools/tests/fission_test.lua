--================================================--
-- GEN'S Nuclear Control
-- Test : Fission Reactor API
-- Version : 0.1.0
--================================================--

local Fission = dofile("/api/fission.lua")
local SafeCall = dofile("/core/safe_call.lua")

local passed = 0
local failed = 0

--------------------------------------------------
-- Display helpers
--------------------------------------------------

local function printResult(name, success, details)
    if success then
        term.setTextColor(colors.lime)
        write("[PASS] ")
        passed = passed + 1
    else
        term.setTextColor(colors.red)
        write("[FAIL] ")
        failed = failed + 1
    end

    term.setTextColor(colors.white)
    print(name)

    if details then
        term.setTextColor(colors.lightGray)
        print("       " .. tostring(details))
        term.setTextColor(colors.white)
    end
end

local function expectTrue(name, value)
    printResult(
        name,
        value == true,
        value == true and nil
            or ("expected true, got " .. tostring(value))
    )
end

local function expectFalse(name, value)
    printResult(
        name,
        value == false,
        value == false and nil
            or ("expected false, got " .. tostring(value))
    )
end

local function expectEqual(name, actual, expected)
    local success = actual == expected

    printResult(
        name,
        success,
        success and nil
            or (
                "expected " .. tostring(expected)
                .. ", got " .. tostring(actual)
            )
    )
end

local function expectType(name, value, expectedType)
    local actualType = type(value)
    local success = actualType == expectedType

    printResult(
        name,
        success,
        success and nil
            or (
                "expected type " .. expectedType
                .. ", got " .. actualType
            )
    )
end

local function expectFiniteNumber(name, value)
    printResult(
        name,
        SafeCall.isFiniteNumber(value),
        SafeCall.isFiniteNumber(value)
            and nil
            or ("invalid number: " .. tostring(value))
    )
end

local function expectPercentage(name, value)
    local success =
        SafeCall.isFiniteNumber(value)
        and value >= 0
        and value <= 1

    printResult(
        name,
        success,
        success and nil
            or (
                "expected value between 0 and 1, got "
                .. tostring(value)
            )
    )
end

local function section(title)
    print()

    term.setTextColor(colors.cyan)
    print("================================")
    print(title)
    print("================================")

    term.setTextColor(colors.white)
end

local function formatNumber(value, decimals)
    if not SafeCall.isFiniteNumber(value) then
        return "N/A"
    end

    return string.format(
        "%." .. tostring(decimals or 2) .. "f",
        value
    )
end

local function formatPercent(value)
    if not SafeCall.isFiniteNumber(value) then
        return "N/A"
    end

    return string.format("%.2f%%", value * 100)
end

--------------------------------------------------
-- Tank validation
--------------------------------------------------

local function testTank(label, tank)
    section(label)

    expectType(
        label .. " structure",
        tank,
        "table"
    )

    if type(tank) ~= "table" then
        return
    end

    if tank.name ~= nil then
        expectType(
            label .. " resource name",
            tank.name,
            "string"
        )
    else
        printResult(
            label .. " resource name may be nil",
            true
        )
    end

    expectFiniteNumber(
        label .. " amount",
        tank.amount
    )

    expectFiniteNumber(
        label .. " capacity",
        tank.capacity
    )

    expectFiniteNumber(
        label .. " needed",
        tank.needed
    )

    expectPercentage(
        label .. " percentage",
        tank.percentage
    )

    print()
    term.setTextColor(colors.lightGray)

    print(
        "       Resource   : "
        .. tostring(tank.name or "empty")
    )

    print(
        "       Amount     : "
        .. formatNumber(tank.amount, 2)
    )

    print(
        "       Capacity   : "
        .. formatNumber(tank.capacity, 2)
    )

    print(
        "       Filled     : "
        .. formatPercent(tank.percentage)
    )

    term.setTextColor(colors.white)
end

--------------------------------------------------
-- Start
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

term.setTextColor(colors.cyan)
print("GEN'S Nuclear Control")
print("Fission API Test v0.1.0")
term.setTextColor(colors.white)

--------------------------------------------------
-- Constructor
--------------------------------------------------

section("CONSTRUCTOR")

local reactor = Fission.new()

expectType(
    "Fission.new returns an object",
    reactor,
    "table"
)

expectType(
    "getState method available",
    reactor.getState,
    "function"
)

expectType(
    "read alias available",
    reactor.read,
    "function"
)

expectType(
    "update alias available",
    reactor.update,
    "function"
)

expectType(
    "activate method available",
    reactor.activate,
    "function"
)

expectType(
    "scram method available",
    reactor.scram,
    "function"
)

expectType(
    "setBurnRate method available",
    reactor.setBurnRate,
    "function"
)

--------------------------------------------------
-- Peripheral discovery
--------------------------------------------------

section("PERIPHERAL DISCOVERY")

local connected = reactor:isConnected()

expectTrue(
    "Fission reactor connected",
    connected
)

expectType(
    "Wrapped peripheral available",
    reactor:getPeripheral(),
    "table"
)

--------------------------------------------------
-- State reading
--------------------------------------------------

section("STATE READING")

local success, stateOrError = pcall(function()
    return reactor:getState()
end)

expectTrue(
    "getState does not crash",
    success
)

if not success then
    term.setTextColor(colors.red)
    print()
    print("Unable to continue:")
    print(tostring(stateOrError))
    term.setTextColor(colors.white)

    return
end

local state = stateOrError

expectType(
    "State is a table",
    state,
    "table"
)

expectTrue(
    "State reports connected",
    state.connected
)

expectEqual(
    "Peripheral type",
    state.peripheralType,
    "fissionReactorLogicAdapter"
)

expectType(
    "Formed state is boolean",
    state.formed,
    "boolean"
)

expectType(
    "Active state is boolean",
    state.active,
    "boolean"
)

--------------------------------------------------
-- Reactor measurements
--------------------------------------------------

section("REACTOR MEASUREMENTS")

expectFiniteNumber(
    "Temperature",
    state.temperature
)

expectFiniteNumber(
    "Configured burn rate",
    state.burnRate
)

expectFiniteNumber(
    "Actual burn rate",
    state.actualBurnRate
)

expectFiniteNumber(
    "Maximum burn rate",
    state.maxBurnRate
)

expectFiniteNumber(
    "Damage percentage",
    state.damagePercent
)

expectPercentage(
    "Burn rate percentage",
    state.burnRatePercentage
)

expectTrue(
    "Damage is at least zero",
    state.damagePercent >= 0
)

expectTrue(
    "Damage is at most 100",
    state.damagePercent <= 100
)

expectTrue(
    "Configured burn rate is non-negative",
    state.burnRate >= 0
)

expectTrue(
    "Actual burn rate is non-negative",
    state.actualBurnRate >= 0
)

expectTrue(
    "Maximum burn rate is non-negative",
    state.maxBurnRate >= 0
)

print()
term.setTextColor(colors.lightGray)

print(
    "       Temperature : "
    .. formatNumber(state.temperature, 2)
    .. " K"
)

print(
    "       Burn rate   : "
    .. formatNumber(state.actualBurnRate, 3)
    .. " / "
    .. formatNumber(state.maxBurnRate, 3)
)

print(
    "       Damage      : "
    .. formatNumber(state.damagePercent, 2)
    .. "%"
)

term.setTextColor(colors.white)

--------------------------------------------------
-- Tanks
--------------------------------------------------

testTank("FUEL TANK", state.fuel)
testTank("COOLANT TANK", state.coolant)
testTank("HEATED COOLANT TANK", state.heatedCoolant)
testTank("WASTE TANK", state.waste)

--------------------------------------------------
-- Reactor characteristics
--------------------------------------------------

section("REACTOR CHARACTERISTICS")

expectFiniteNumber(
    "Boil efficiency",
    state.boilEfficiency
)

expectFiniteNumber(
    "Environmental loss",
    state.environmentalLoss
)

expectFiniteNumber(
    "Heating rate",
    state.heatingRate
)

expectFiniteNumber(
    "Fuel assemblies",
    state.fuelAssemblies
)

expectFiniteNumber(
    "Fuel surface area",
    state.fuelSurfaceArea
)

expectTrue(
    "Fuel assemblies are non-negative",
    state.fuelAssemblies >= 0
)

expectTrue(
    "Fuel surface area is non-negative",
    state.fuelSurfaceArea >= 0
)

--------------------------------------------------
-- Error handling
--------------------------------------------------

section("ERROR HANDLING")

expectType(
    "Errors collection exists",
    state.errors,
    "table"
)

expectType(
    "hasErrors is boolean",
    state.hasErrors,
    "boolean"
)

expectEqual(
    "hasErrors matches error count",
    state.hasErrors,
    #state.errors > 0
)

if #state.errors == 0 then
    printResult(
        "No peripheral read errors",
        true
    )
else
    for index, entry in ipairs(state.errors) do
        local validEntry =
            type(entry) == "table"
            and type(entry.method) == "string"
            and type(entry.message) == "string"

        printResult(
            "Error entry " .. index .. " is valid",
            validEntry,
            validEntry and nil
                or textutils.serialize(entry)
        )
    end
end

--------------------------------------------------
-- Safety evaluation
--------------------------------------------------

section("SAFETY EVALUATION")

expectType(
    "Safety state exists",
    state.safety,
    "table"
)

expectType(
    "Safety level is a string",
    state.safety.level,
    "string"
)

local validLevels = {
    safe = true,
    warning = true,
    critical = true,
    emergency = true
}

expectTrue(
    "Safety level is valid",
    validLevels[state.safety.level] == true
)

expectType(
    "Safety safe flag is boolean",
    state.safety.safe,
    "boolean"
)

expectType(
    "SCRAM recommendation is boolean",
    state.safety.shouldScram,
    "boolean"
)

expectType(
    "Warnings collection exists",
    state.safety.warnings,
    "table"
)

expectEqual(
    "Safe flag matches safety level",
    state.safety.safe,
    state.safety.level == "safe"
)

expectEqual(
    "SCRAM only recommended while active",
    state.safety.shouldScram and state.active,
    state.safety.shouldScram
)

print()
term.setTextColor(colors.lightGray)

print(
    "       Safety level : "
    .. string.upper(state.safety.level)
)

print(
    "       Should SCRAM : "
    .. tostring(state.safety.shouldScram)
)

print(
    "       Warnings     : "
    .. tostring(#state.safety.warnings)
)

term.setTextColor(colors.white)

for index, warning in ipairs(state.safety.warnings) do
    print(
        "       "
        .. tostring(index)
        .. ". "
        .. tostring(warning)
    )
end

--------------------------------------------------
-- Aliases
--------------------------------------------------

section("READ ALIASES")

local readSuccess, readState = pcall(function()
    return reactor:read()
end)

expectTrue(
    "read alias does not crash",
    readSuccess
)

if readSuccess then
    expectType(
        "read alias returns a table",
        readState,
        "table"
    )
end

local updateSuccess, updateState = pcall(function()
    return reactor:update()
end)

expectTrue(
    "update alias does not crash",
    updateSuccess
)

if updateSuccess then
    expectType(
        "update alias returns a table",
        updateState,
        "table"
    )
end

--------------------------------------------------
-- Safe command validation
--------------------------------------------------

section("COMMAND VALIDATION")

local invalidRateResult = reactor:setBurnRate(
    "invalid"
)

expectType(
    "Invalid burn rate returns a result",
    invalidRateResult,
    "table"
)

expectFalse(
    "Invalid burn rate is rejected",
    invalidRateResult.success
)

expectEqual(
    "Invalid burn rate action",
    invalidRateResult.action,
    "setBurnRate"
)

expectType(
    "Invalid burn rate gives an error",
    invalidRateResult.error,
    "string"
)

print()
term.setTextColor(colors.yellow)
print("No reactor command was executed.")
print("activate(), scram() and valid setBurnRate()")
print("were intentionally not called.")
term.setTextColor(colors.white)

--------------------------------------------------
-- Summary
--------------------------------------------------

print()
term.setTextColor(colors.cyan)
print("================================")
print("TEST SUMMARY")
print("================================")

term.setTextColor(colors.lime)
print("Passed : " .. passed)

if failed > 0 then
    term.setTextColor(colors.red)
else
    term.setTextColor(colors.lime)
end

print("Failed : " .. failed)
print()

if failed == 0 then
    term.setTextColor(colors.lime)
    print("FISSION API: READY")
else
    term.setTextColor(colors.red)
    print("FISSION API: FAILED")
end

term.setTextColor(colors.white)