--================================================--
-- GEN'S Nuclear Control
-- Test : Safe Call
-- Version : 0.1.0
--================================================--

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

local function expectEqual(name, actual, expected)
    local success = actual == expected

    printResult(
        name,
        success,
        success and nil or
            ("expected " .. tostring(expected) ..
            ", got " .. tostring(actual))
    )
end

local function expectTrue(name, value)
    printResult(
        name,
        value == true,
        value == true and nil or
            ("expected true, got " .. tostring(value))
    )
end

local function expectFalse(name, value)
    printResult(
        name,
        value == false,
        value == false and nil or
            ("expected false, got " .. tostring(value))
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

--------------------------------------------------
-- Fake peripheral
--------------------------------------------------

local fakeDevice = {}

function fakeDevice.getNumber()
    return 42
end

function fakeDevice.getBoolean()
    return true
end

function fakeDevice.getString()
    return "GNC"
end

function fakeDevice.getTable()
    return {
        name = "mekanism:polonium",
        amount = 2000
    }
end

function fakeDevice.getMultipleValues()
    return "alpha", 42, true
end

function fakeDevice.getNaN()
    return 0 / 0
end

function fakeDevice.getInfinity()
    return math.huge
end

function fakeDevice.getInvalidNumber()
    return "not a number"
end

function fakeDevice.getInvalidBoolean()
    return 1
end

function fakeDevice.getInvalidTable()
    return "not a table"
end

function fakeDevice.fail()
    error("Simulated peripheral failure")
end

function fakeDevice.add(a, b)
    return a + b
end

--------------------------------------------------
-- Start
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

term.setTextColor(colors.cyan)
print("GEN'S Nuclear Control")
print("Safe Call Test v0.1.0")
term.setTextColor(colors.white)

--------------------------------------------------
-- Validation helpers
--------------------------------------------------

section("VALIDATION HELPERS")

expectTrue(
    "Finite number accepted",
    SafeCall.isFiniteNumber(42)
)

expectFalse(
    "NaN rejected",
    SafeCall.isFiniteNumber(0 / 0)
)

expectFalse(
    "Positive infinity rejected",
    SafeCall.isFiniteNumber(math.huge)
)

expectFalse(
    "Negative infinity rejected",
    SafeCall.isFiniteNumber(-math.huge)
)

expectEqual(
    "Valid number preserved",
    SafeCall.number(25, 0),
    25
)

expectEqual(
    "Invalid number uses fallback",
    SafeCall.number("invalid", 0),
    0
)

expectEqual(
    "Valid boolean preserved",
    SafeCall.boolean(true, false),
    true
)

expectEqual(
    "Invalid boolean uses fallback",
    SafeCall.boolean(1, false),
    false
)

--------------------------------------------------
-- Method detection
--------------------------------------------------

section("METHOD DETECTION")

expectTrue(
    "Existing method detected",
    SafeCall.hasMethod(fakeDevice, "getNumber")
)

expectFalse(
    "Missing method rejected",
    SafeCall.hasMethod(fakeDevice, "missingMethod")
)

expectFalse(
    "Nil peripheral rejected",
    SafeCall.hasMethod(nil, "getNumber")
)

--------------------------------------------------
-- Raw calls
--------------------------------------------------

section("RAW CALLS")

local success, value, err =
    SafeCall.raw(fakeDevice, "getNumber")

expectTrue("Raw call succeeds", success)
expectEqual("Raw call value", value, 42)
expectEqual("Raw call has no error", err, nil)

success, value, err =
    SafeCall.raw(fakeDevice, "missingMethod")

expectFalse("Missing method fails safely", success)
expectEqual("Missing method returns nil", value, nil)
expectTrue(
    "Missing method returns an error",
    type(err) == "string"
)

success, value, err =
    SafeCall.raw(nil, "getNumber")

expectFalse("Nil device fails safely", success)
expectEqual("Nil device returns nil", value, nil)
expectEqual(
    "Nil device error",
    err,
    "Peripheral unavailable"
)

success, value, err =
    SafeCall.raw(fakeDevice, "fail")

expectFalse("Peripheral exception caught", success)
expectTrue(
    "Peripheral exception returns message",
    type(err) == "string"
)

--------------------------------------------------
-- Arguments and multiple results
--------------------------------------------------

section("ARGUMENTS AND RESULTS")

success, value, err =
    SafeCall.raw(fakeDevice, "add", 10, 5)

expectTrue("Arguments passed correctly", success)
expectEqual("Addition result", value, 15)

success, value, err =
    SafeCall.raw(fakeDevice, "getMultipleValues")

expectTrue("Multiple values call succeeds", success)
expectTrue(
    "Multiple values returned as table",
    type(value) == "table"
)

if type(value) == "table" then
    expectEqual("Multiple result 1", value[1], "alpha")
    expectEqual("Multiple result 2", value[2], 42)
    expectEqual("Multiple result 3", value[3], true)
end

--------------------------------------------------
-- Typed calls
--------------------------------------------------

section("TYPED CALLS")

value, err =
    SafeCall.getNumber(fakeDevice, "getNumber", 0)

expectEqual("Number getter", value, 42)
expectEqual("Number getter no error", err, nil)

value, err =
    SafeCall.getNumber(
        fakeDevice,
        "getInvalidNumber",
        -1
    )

expectEqual("Invalid number fallback", value, -1)
expectTrue(
    "Invalid number gives error",
    type(err) == "string"
)

value, err =
    SafeCall.getNumber(fakeDevice, "getNaN", -1)

expectEqual("NaN fallback", value, -1)
expectTrue(
    "NaN gives error",
    type(err) == "string"
)

value, err =
    SafeCall.getNumber(fakeDevice, "getInfinity", -1)

expectEqual("Infinity fallback", value, -1)

value, err =
    SafeCall.getBoolean(
        fakeDevice,
        "getBoolean",
        false
    )

expectEqual("Boolean getter", value, true)
expectEqual("Boolean getter no error", err, nil)

value, err =
    SafeCall.getBoolean(
        fakeDevice,
        "getInvalidBoolean",
        false
    )

expectEqual("Invalid boolean fallback", value, false)
expectTrue(
    "Invalid boolean gives error",
    type(err) == "string"
)

value, err =
    SafeCall.getString(
        fakeDevice,
        "getString",
        "fallback"
    )

expectEqual("String getter", value, "GNC")

value, err =
    SafeCall.getTable(fakeDevice, "getTable", nil)

expectTrue(
    "Table getter",
    type(value) == "table"
)

--------------------------------------------------
-- Percentages
--------------------------------------------------

section("PERCENTAGES")

expectEqual(
    "Normal percentage preserved",
    SafeCall.normalizePercentage(0.5, nil),
    0.5
)

expectEqual(
    "Negative percentage clamped",
    SafeCall.normalizePercentage(-0.5, nil),
    0
)

expectEqual(
    "Percentage above one clamped",
    SafeCall.normalizePercentage(1.5, nil),
    1
)

expectEqual(
    "NaN percentage uses fallback",
    SafeCall.normalizePercentage(0 / 0, nil),
    nil
)

expectEqual(
    "Calculated percentage",
    SafeCall.calculatePercentage(25, 100, nil),
    0.25
)

expectEqual(
    "Zero capacity uses fallback",
    SafeCall.calculatePercentage(25, 0, nil),
    nil
)

expectEqual(
    "Invalid capacity uses fallback",
    SafeCall.calculatePercentage(
        25,
        "invalid",
        nil
    ),
    nil
)

--------------------------------------------------
-- Resources
--------------------------------------------------

section("RESOURCES")

local resource

resource, err =
    SafeCall.getResource(fakeDevice, "getTable")

expectEqual(
    "Resource name",
    resource.name,
    "mekanism:polonium"
)

expectEqual(
    "Resource amount",
    resource.amount,
    2000
)

resource, err =
    SafeCall.getResource(
        fakeDevice,
        "getInvalidTable"
    )

expectEqual(
    "Invalid resource name",
    resource.name,
    nil
)

expectEqual(
    "Invalid resource amount",
    resource.amount,
    0
)

expectTrue(
    "Invalid resource gives error",
    type(err) == "string"
)

--------------------------------------------------
-- Structured call
--------------------------------------------------

section("STRUCTURED CALL")

local result = SafeCall.call(
    fakeDevice,
    "getNumber"
)

expectEqual(
    "Structured success",
    result.success,
    true
)

expectEqual(
    "Structured value",
    result.value,
    42
)

expectEqual(
    "Structured method name",
    result.method,
    "getNumber"
)

expectEqual(
    "Structured error",
    result.error,
    nil
)

--------------------------------------------------
-- Error collection
--------------------------------------------------

section("ERROR COLLECTION")

local errors = {}

SafeCall.addError(
    errors,
    "getTemperature",
    "Example error"
)

SafeCall.addError(
    errors,
    "getStatus",
    nil
)

expectEqual(
    "Only real errors are collected",
    #errors,
    1
)

if errors[1] then
    expectEqual(
        "Collected method name",
        errors[1].method,
        "getTemperature"
    )

    expectEqual(
        "Collected error message",
        errors[1].message,
        "Example error"
    )
end

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
    print("SAFE CALL MODULE: READY")
else
    term.setTextColor(colors.red)
    print("SAFE CALL MODULE: FAILED")
end

term.setTextColor(colors.white)