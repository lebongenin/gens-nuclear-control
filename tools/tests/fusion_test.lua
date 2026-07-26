--================================================--
-- GEN'S Nuclear Control
-- Test : Fusion Reactor API
-- Version : 0.1.0
--================================================--

local Fusion = dofile("/api/fusion.lua")
local Test = dofile("/tools/tests/testlib.lua")

local test = Test.new("Fusion API Test v0.1.0")

--------------------------------------------------
-- Constructor
--------------------------------------------------

test:section("CONSTRUCTOR")

local reactor = Fusion.new()

test:expectType(
    "Fusion object",
    reactor,
    "table"
)

test:expectType(
    "getState available",
    reactor.getState,
    "function"
)

test:expectType(
    "setInjectionRate available",
    reactor.setInjectionRate,
    "function"
)

test:expectType(
    "setActiveCooled available",
    reactor.setActiveCooled,
    "function"
)

--------------------------------------------------
-- Discovery
--------------------------------------------------

test:section("PERIPHERAL DISCOVERY")

test:expectTrue(
    "Fusion reactor connected",
    reactor:isConnected()
)

test:expectType(
    "Wrapped peripheral",
    reactor:getPeripheral(),
    "table"
)

--------------------------------------------------
-- State
--------------------------------------------------

test:section("STATE READING")

local success, state = pcall(function()
    return reactor:getState()
end)

test:expectTrue(
    "getState does not crash",
    success
)

if not success then
    print(tostring(state))
    test:summary("FUSION API: READY")
    return
end

test:expectType(
    "State structure",
    state,
    "table"
)

test:expectTrue(
    "State connected",
    state.connected
)

test:expectEqual(
    "Peripheral type",
    state.peripheralType,
    "fusionReactorLogicAdapter"
)

test:expectType(
    "Formed state",
    state.formed,
    "boolean"
)

test:expectType(
    "Ignited state",
    state.ignited,
    "boolean"
)

test:expectType(
    "Active cooled state",
    state.activeCooled,
    "boolean"
)

--------------------------------------------------
-- Measurements
--------------------------------------------------

test:section("MEASUREMENTS")

test:expectNonNegative(
    "Production rate",
    state.productionRate
)

test:expectNonNegative(
    "Net production",
    state.netProduction
)

test:expectNonNegative(
    "Injection rate",
    state.injectionRate
)

test:expectNonNegative(
    "Plasma temperature",
    state.plasmaTemperature
)

test:expectNonNegative(
    "Case temperature",
    state.caseTemperature
)

test:expectNonNegative(
    "Environmental loss",
    state.environmentalLoss
)

test:expectNonNegative(
    "Transfer loss",
    state.transferLoss
)

test:expectTrue(
    "Net production not above production",
    state.netProduction <= state.productionRate
)

--------------------------------------------------
-- Tanks
--------------------------------------------------

test:expectTank(
    "D-T FUEL",
    state.dtFuel,
    false
)

test:expectTank(
    "DEUTERIUM",
    state.deuterium,
    false
)

test:expectTank(
    "TRITIUM",
    state.tritium,
    false
)

test:expectTank(
    "WATER",
    state.water,
    true
)

test:expectTank(
    "STEAM",
    state.steam,
    true
)

--------------------------------------------------
-- Errors and safety
--------------------------------------------------

test:section("ERRORS AND SAFETY")

test:expectErrors(state)
test:expectSafety(state.safety)

--------------------------------------------------
-- Aliases
--------------------------------------------------

test:section("ALIASES")

local readSuccess, readState = pcall(function()
    return reactor:read()
end)

test:expectTrue(
    "read does not crash",
    readSuccess
)

if readSuccess then
    test:expectType(
        "read returns table",
        readState,
        "table"
    )
end

local updateSuccess, updateState = pcall(function()
    return reactor:update()
end)

test:expectTrue(
    "update does not crash",
    updateSuccess
)

if updateSuccess then
    test:expectType(
        "update returns table",
        updateState,
        "table"
    )
end

--------------------------------------------------
-- Safe command validation
--------------------------------------------------

test:section("COMMAND VALIDATION")

local invalidRate =
    reactor:setInjectionRate("invalid")

test:expectFalse(
    "Invalid injection rejected",
    invalidRate.success
)

test:expectEqual(
    "Injection action name",
    invalidRate.action,
    "setInjectionRate"
)

local invalidCooling =
    reactor:setActiveCooled("invalid")

test:expectFalse(
    "Invalid cooling value rejected",
    invalidCooling.success
)

test:expectEqual(
    "Cooling action name",
    invalidCooling.action,
    "setActiveCooledLogic"
)

term.setTextColor(colors.yellow)
print()
print("No fusion setting was modified.")
term.setTextColor(colors.white)

test:summary("FUSION API: READY")