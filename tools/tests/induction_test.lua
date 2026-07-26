--================================================--
-- GEN'S Nuclear Control
-- Test : Induction Matrix API
-- Version : 0.1.0
--================================================--

local Induction = dofile("/api/induction.lua")
local Test = dofile("/tools/tests/testlib.lua")

local test = Test.new("Induction API Test v0.1.0")

test:section("CONSTRUCTOR")

local matrix = Induction.new()

test:expectType(
    "Induction object",
    matrix,
    "table"
)

test:expectType(
    "getState available",
    matrix.getState,
    "function"
)

test:section("PERIPHERAL DISCOVERY")

test:expectTrue(
    "Induction Matrix connected",
    matrix:isConnected()
)

test:expectType(
    "Wrapped peripheral",
    matrix:getPeripheral(),
    "table"
)

test:section("STATE READING")

local success, state = pcall(function()
    return matrix:getState()
end)

test:expectTrue(
    "getState does not crash",
    success
)

if not success then
    print(tostring(state))
    test:summary("INDUCTION API: READY")
    return
end

test:expectTrue(
    "State connected",
    state.connected
)

test:expectEqual(
    "Peripheral type",
    state.peripheralType,
    "inductionPort"
)

test:expectType(
    "Formed state",
    state.formed,
    "boolean"
)

test:section("ENERGY STORAGE")

test:expectNonNegative(
    "Stored energy",
    state.energy
)

test:expectNonNegative(
    "Energy capacity",
    state.capacity
)

test:expectNonNegative(
    "Energy needed",
    state.needed
)

test:expectPercentage(
    "Energy percentage",
    state.percentage
)

test:expectTrue(
    "Stored energy not above capacity",
    state.energy <= state.capacity
)

test:section("ENERGY FLOW")

test:expectNonNegative(
    "Input rate",
    state.input
)

test:expectNonNegative(
    "Output rate",
    state.output
)

test:expectFinite(
    "Net flow",
    state.netFlow
)

test:expectNonNegative(
    "Transfer capacity",
    state.transferCapacity
)

test:expectPercentage(
    "Input utilization",
    state.inputUtilization
)

test:expectPercentage(
    "Output utilization",
    state.outputUtilization
)

test:expectEqual(
    "Net flow calculation",
    state.netFlow,
    state.input - state.output
)

test:section("MATRIX COMPONENTS")

test:expectNonNegative(
    "Installed cells",
    state.installedCells
)

test:expectNonNegative(
    "Installed providers",
    state.installedProviders
)

test:section("FLOW FLAGS")

test:expectType(
    "Charging flag",
    state.charging,
    "boolean"
)

test:expectType(
    "Discharging flag",
    state.discharging,
    "boolean"
)

test:expectType(
    "Stable flag",
    state.stable,
    "boolean"
)

local activeFlowFlags = 0

if state.charging then
    activeFlowFlags = activeFlowFlags + 1
end

if state.discharging then
    activeFlowFlags = activeFlowFlags + 1
end

if state.stable then
    activeFlowFlags = activeFlowFlags + 1
end

test:expectEqual(
    "Exactly one flow state active",
    activeFlowFlags,
    1
)

test:section("ERRORS AND SAFETY")

test:expectErrors(state)
test:expectSafety(state.safety)

test:section("ALIASES")

local readSuccess, readState = pcall(function()
    return matrix:read()
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
    return matrix:update()
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

test:summary("INDUCTION API: READY")