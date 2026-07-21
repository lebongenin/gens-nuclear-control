--================================================--
-- GEN'S Nuclear Control
-- Version : 0.0.5
-- Application : GNC Inspector
--================================================--

local discovery = dofile("/core/discovery.lua")
local inspector = dofile("/core/inspector.lua")
local logger = dofile("/core/logger.lua")

local reactor, reactorName, reactorType =
    discovery.getFusionReactor()

local OUTPUT_FILE = "/logs/inspector.txt"

local methodsToInspect = {
    "isFormed",
    "isIgnited",

    "getInjectionRate",

    "getCaseTemperature",
    "getPlasmaTemperature",
    "getIgnitionTemperature",

    "getDTFuel",
    "getDTFuelCapacity",
    "getDTFuelFilledPercentage",
    "getDTFuelNeeded",

    "getTritium",
    "getTritiumCapacity",
    "getTritiumFilledPercentage",
    "getTritiumNeeded",

    "getDeuterium",
    "getDeuteriumCapacity",
    "getDeuteriumFilledPercentage",
    "getDeuteriumNeeded",

    "getWater",
    "getWaterCapacity",
    "getWaterFilledPercentage",
    "getWaterNeeded",

    "getEnvironmentalLoss",
    "getTransferLoss",
    "getHohlraum",
    "getLogicMode",
    "isActiveCooledLogic"
}

local function callMethod(device, methodName)
    local method = device[methodName]

    if type(method) ~= "function" then
        return {
            success = false,
            error = "Unsupported method"
        }
    end

    local results = table.pack(pcall(method))

    if not results[1] then
        return {
            success = false,
            error = tostring(results[2])
        }
    end

    local values = {}

    for index = 2, results.n do
        values[#values + 1] = results[index]
    end

    return {
        success = true,
        resultCount = #values,
        values = values
    }
end

local function buildReport()
    local report = {
        application = "GEN'S Nuclear Control Inspector",
        version = "0.0.5",
        peripheral = {
            name = reactorName,
            type = reactorType
        },
        methods = {}
    }

    for _, methodName in ipairs(methodsToInspect) do
        report.methods[methodName] =
            callMethod(reactor, methodName)
    end

    return report
end

term.clear()
term.setCursorPos(1, 1)

term.setTextColor(colors.cyan)
print("================================")
print("      GNC Inspector")
print("================================")

term.setTextColor(colors.white)
print("Version 0.0.5")
print()

if not reactor then
    term.setTextColor(colors.red)
    print("Fusion Reactor: NOT FOUND")
    term.setTextColor(colors.white)

    logger.error(
        "Inspector could not find Fusion Reactor"
    )

    return
end

term.setTextColor(colors.lime)
print("Fusion Reactor: ONLINE")
term.setTextColor(colors.lightGray)
print("Name: " .. tostring(reactorName))
print("Type: " .. tostring(reactorType))
print()

term.setTextColor(colors.white)
print("Inspecting methods...")

local report = buildReport()

local success, errorMessage =
    inspector.writeToFile(
        OUTPUT_FILE,
        report,
        8
    )

if not success then
    term.setTextColor(colors.red)
    print("FAILED")
    print(tostring(errorMessage))
    term.setTextColor(colors.white)

    logger.error(
        "Inspector failed: "
            .. tostring(errorMessage)
    )

    return
end

logger.info(
    "Inspector report created at "
        .. OUTPUT_FILE
)

term.setTextColor(colors.lime)
print("Inspection complete!")
term.setTextColor(colors.white)
print()
print("Report saved to:")
term.setTextColor(colors.lightBlue)
print(OUTPUT_FILE)
term.setTextColor(colors.white)
print()
print("Open it with:")
term.setTextColor(colors.yellow)
print("edit logs/inspector.txt")
term.setTextColor(colors.white)