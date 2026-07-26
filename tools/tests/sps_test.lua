--================================================--
-- GEN'S Nuclear Control
-- Test : SPS API
-- Version : 0.1.0
--================================================--

local SPS = dofile("/api/sps.lua")
local Test = dofile("/tools/tests/testlib.lua")

local test = Test.new("SPS API Test v0.1.0")

test:section("CONSTRUCTOR")

local sps = SPS.new()

test:expectType(
    "SPS object",
    sps,
    "table"
)

test:expectType(
    "getState available",
    sps.getState,
    "function"
)

test:section("PERIPHERAL DISCOVERY")

test:expectTrue(
    "SPS connected",
    sps:isConnected()
)

test:expectType(
    "Wrapped peripheral",
    sps:getPeripheral(),
    "table"
)

test:section("STATE READING")

local success, state = pcall(function()
    return sps:getState()
end)

test:expectTrue(
    "getState does not crash",
    success
)

if not success then
    print(tostring(state))
    test:summary("SPS API: READY")
    return
end

test:expectTrue(
    "State connected",
    state.connected
)

test:expectEqual(
    "Peripheral type",
    state.peripheralType,
    "spsPort"
)

test:expectType(
    "Formed state",
    state.formed,
    "boolean"
)

test:section("ENERGY")

test:expectNonNegative(
    "Stored energy",
    state.energy
)

test:expectNonNegative(
    "Energy capacity",
    state.energyCapacity
)

test:expectNonNegative(
    "Energy needed",
    state.energyNeeded
)

test:expectPercentage(
    "Energy percentage",
    state.energyPercentage
)

test:expectTrue(
    "Stored energy not above capacity",
    state.energy <= state.energyCapacity
)

test:expectTank(
    "POLONIUM INPUT",
    state.input,
    false
)

test:expectTank(
    "ANTIMATTER OUTPUT",
    state.output,
    false
)

test:section("PROCESSING")

test:expectNonNegative(
    "Process rate",
    state.processRate
)

test:expectNonNegative(
    "Coil count",
    state.coils
)

test:expectType(
    "Processing flag",
    state.processing,
    "boolean"
)

test:expectEqual(
    "Processing flag calculation",
    state.processing,
    state.processRate > 0
        and state.input.amount > 0
)

test:section("ERRORS AND SAFETY")

test:expectErrors(state)
test:expectSafety(state.safety)

test:section("ALIASES")

local readSuccess, readState = pcall(function()
    return sps:read()
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
    return sps:update()
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

test:summary("SPS API: READY")