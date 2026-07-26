--================================================--
-- GEN'S Nuclear Control
-- Version : 0.0.6
-- Application : Universal Peripheral Inspector
--================================================--

local inspector = dofile("/core/inspector.lua")
local logger = dofile("/core/logger.lua")

local OUTPUT_FILE = "/logs/inspector.txt"

--------------------------------------------------
-- Formatting
--------------------------------------------------

local function getPeripheralTypes(name)
    local types = { peripheral.getType(name) }

    local result = {}

    for _, peripheralType in ipairs(types) do
        if peripheralType ~= nil then
            result[#result + 1] = tostring(peripheralType)
        end
    end

    return result
end

local function getPeripheralMethods(name)
    local success, methods = pcall(
        peripheral.getMethods,
        name
    )

    if not success or type(methods) ~= "table" then
        return {}
    end

    table.sort(methods)

    return methods
end

--------------------------------------------------
-- Detection
--------------------------------------------------

local function detectPeripherals()
    local names = peripheral.getNames()
    local devices = {}

    table.sort(names)

    for _, name in ipairs(names) do
        local types = getPeripheralTypes(name)
        local methods = getPeripheralMethods(name)

        devices[#devices + 1] = {
            name = name,
            primaryType = types[1] or "unknown",
            types = types,
            methodCount = #methods,
            methods = methods
        }
    end

    return devices
end

--------------------------------------------------
-- Report
--------------------------------------------------

local function buildReport(devices)
    return {
        application = "GEN'S Nuclear Control Universal Inspector",
        version = "0.0.6",
        peripheralCount = #devices,
        peripherals = devices
    }
end

--------------------------------------------------
-- Display
--------------------------------------------------

local function printHeader()
    term.clear()
    term.setCursorPos(1, 1)

    term.setTextColor(colors.cyan)
    print("================================")
    print(" GNC Universal Inspector")
    print("================================")

    term.setTextColor(colors.white)
    print("Version 0.0.6")
    print()
end

local function printDevices(devices)
    if #devices == 0 then
        term.setTextColor(colors.red)
        print("No peripherals detected.")

        term.setTextColor(colors.white)
        return
    end

    term.setTextColor(colors.lime)
    print(tostring(#devices) .. " peripheral(s) detected")
    print()

    for index, device in ipairs(devices) do
        term.setTextColor(colors.yellow)
        print(
            tostring(index)
            .. ". "
            .. tostring(device.name)
        )

        term.setTextColor(colors.lightGray)
        print(
            "   Type: "
            .. tostring(device.primaryType)
        )

        print(
            "   Methods: "
            .. tostring(device.methodCount)
        )
    end

    term.setTextColor(colors.white)
end

--------------------------------------------------
-- Main
--------------------------------------------------

printHeader()

term.setTextColor(colors.white)
print("Scanning wired network...")
print()

local devices = detectPeripherals()

printDevices(devices)

local report = buildReport(devices)

local success, errorMessage = inspector.writeToFile(
    OUTPUT_FILE,
    report,
    10
)

print()

if not success then
    term.setTextColor(colors.red)
    print("Report creation failed.")
    print(tostring(errorMessage))

    term.setTextColor(colors.white)

    logger.error(
        "Universal Inspector failed: "
        .. tostring(errorMessage)
    )

    return
end

logger.info(
    "Universal Inspector detected "
    .. tostring(#devices)
    .. " peripherals"
)

logger.info(
    "Inspector report created at "
    .. OUTPUT_FILE
)

term.setTextColor(colors.lime)
print("Inspection complete!")

term.setTextColor(colors.white)
print()
print("Full report saved to:")

term.setTextColor(colors.lightBlue)
print(OUTPUT_FILE)

term.setTextColor(colors.white)
print()
print("Open it with:")

term.setTextColor(colors.yellow)
print("edit logs/inspector.txt")

term.setTextColor(colors.white)