--================================================--
-- GEN'S Nuclear Control
-- Tool : System Probe
-- Version : 0.1.0
--================================================--

local OUTPUT_PATH = "/logs/system_probe.lua"

--------------------------------------------------
-- Filesystem
--------------------------------------------------

local function ensureDirectory(path)
    local directory = fs.getDir(path)

    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end
end

--------------------------------------------------
-- Safe peripheral calls
--------------------------------------------------

local function safeCall(device, method)
    if not device then
        return {
            success = false,
            error = "Peripheral unavailable"
        }
    end

    if type(device[method]) ~= "function" then
        return {
            success = false,
            error = "Method unavailable"
        }
    end

    local result = table.pack(pcall(device[method]))

    if not result[1] then
        return {
            success = false,
            error = tostring(result[2])
        }
    end

    if result.n == 2 then
        return {
            success = true,
            value = result[2]
        }
    end

    local values = {}

    for index = 2, result.n do
        values[#values + 1] = result[index]
    end

    return {
        success = true,
        value = values
    }
end

--------------------------------------------------
-- Device inspection
--------------------------------------------------

local function inspectDevice(peripheralType, methods)
    local device = peripheral.find(peripheralType)

    local report = {
        peripheralType = peripheralType,
        connected = device ~= nil,
        values = {}
    }

    if not device then
        return report
    end

    for _, method in ipairs(methods) do
        report.values[method] = safeCall(device, method)

        -- Évite le watchdog ComputerCraft pendant les gros rapports.
        os.queueEvent("gnc_probe_yield")
        os.pullEvent("gnc_probe_yield")
    end

    return report
end

--------------------------------------------------
-- Probe definition
--------------------------------------------------

local devices = {
    fission = {
        peripheralType = "fissionReactorLogicAdapter",
        methods = {
            "isFormed",
            "getStatus",
            "getTemperature",
            "getBurnRate",
            "getActualBurnRate",
            "getMaxBurnRate",
            "getDamagePercent",

            "getFuel",
            "getFuelCapacity",
            "getFuelFilledPercentage",
            "getFuelNeeded",

            "getCoolant",
            "getCoolantCapacity",
            "getCoolantFilledPercentage",
            "getCoolantNeeded",

            "getHeatedCoolant",
            "getHeatedCoolantCapacity",
            "getHeatedCoolantFilledPercentage",
            "getHeatedCoolantNeeded",

            "getWaste",
            "getWasteCapacity",
            "getWasteFilledPercentage",
            "getWasteNeeded",

            "getBoilEfficiency",
            "getEnvironmentalLoss",
            "getHeatingRate",
            "getFuelAssemblies",
            "getFuelSurfaceArea"
        }
    },

    fusion = {
        peripheralType = "fusionReactorLogicAdapter",
        methods = {
            "isFormed",
            "isIgnited",
            "isActiveCooledLogic",

            "getProductionRate",
            "getPassiveGeneration",
            "getInjectionRate",
            "getMinInjectionRate",

            "getPlasmaTemperature",
            "getCaseTemperature",
            "getIgnitionTemperature",
            "getMaxPlasmaTemperature",
            "getMaxCasingTemperature",

            "getDTFuel",
            "getDTFuelCapacity",
            "getDTFuelFilledPercentage",
            "getDTFuelNeeded",

            "getDeuterium",
            "getDeuteriumCapacity",
            "getDeuteriumFilledPercentage",
            "getDeuteriumNeeded",

            "getTritium",
            "getTritiumCapacity",
            "getTritiumFilledPercentage",
            "getTritiumNeeded",

            "getWater",
            "getWaterCapacity",
            "getWaterFilledPercentage",

            "getSteam",
            "getSteamCapacity",
            "getSteamFilledPercentage",

            "getEnvironmentalLoss",
            "getTransferLoss"
        }
    },

    induction = {
        peripheralType = "inductionPort",
        methods = {
            "isFormed",
            "getEnergy",
            "getMaxEnergy",
            "getEnergyNeeded",
            "getEnergyFilledPercentage",
            "getLastInput",
            "getLastOutput",
            "getTransferCap",
            "getInstalledCells",
            "getInstalledProviders",
            "getMode"
        }
    },

    sps = {
        peripheralType = "spsPort",
        methods = {
            "isFormed",
            "getEnergy",
            "getMaxEnergy",
            "getEnergyNeeded",
            "getEnergyFilledPercentage",

            "getInput",
            "getInputCapacity",
            "getInputFilledPercentage",
            "getInputNeeded",

            "getOutput",
            "getOutputCapacity",
            "getOutputFilledPercentage",
            "getOutputNeeded",

            "getProcessRate",
            "getCoils",
            "getMode"
        }
    },

    ae2 = {
        peripheralType = "me_bridge",
        methods = {
            "getName",
            "isConnected",
            "isOnline",

            "getEnergyCapacity",
            "getStoredEnergy",
            "getEnergyUsage",
            "getAverageEnergyInput",

            "getTotalItemStorage",
            "getUsedItemStorage",
            "getAvailableItemStorage",
            "getTotalExternalItemStorage",
            "getUsedExternalItemStorage",
            "getAvailableExternalItemStorage",

            "getTotalFluidStorage",
            "getUsedFluidStorage",
            "getAvailableFluidStorage",

            "getCells",
            "getDrives",
            "getItems",
            "getFluids",
            "getPatterns",
            "getCraftableItems",
            "getCraftingCPUs",
            "getCraftingTasks"
        }
    }
}

--------------------------------------------------
-- Generate report
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

term.setTextColor(colors.cyan)
print("GEN'S Nuclear Control")
print("System Probe")
print()

local report = {
    application = "GEN'S Nuclear Control System Probe",
    version = "0.1.0",
    generatedAt = os.epoch("utc"),
    devices = {}
}

for deviceName, definition in pairs(devices) do
    write(deviceName .. " ... ")

    local deviceReport = inspectDevice(
        definition.peripheralType,
        definition.methods
    )

    report.devices[deviceName] = deviceReport

    if deviceReport.connected then
        term.setTextColor(colors.lime)
        print("OK")
    else
        term.setTextColor(colors.red)
        print("OFFLINE")
    end

    term.setTextColor(colors.white)
end

--------------------------------------------------
-- Sanitize tables before serialization
--------------------------------------------------

local function sanitize(value, seen, depth)
    seen = seen or {}
    depth = depth or 0

    if depth > 8 then
        return "<max depth reached>"
    end

    local valueType = type(value)

    if valueType == "function" then
        return "<function>"
    end

    if valueType == "userdata" then
        return "<userdata>"
    end

    if valueType == "thread" then
        return "<thread>"
    end

    if valueType ~= "table" then
        return value
    end

    if seen[value] then
        return "<repeated table reference>"
    end

    seen[value] = true

    local clean = {}

    for key, child in pairs(value) do
        local cleanKey

        if type(key) == "string" or type(key) == "number" then
            cleanKey = key
        else
            cleanKey = tostring(key)
        end

        clean[cleanKey] = sanitize(child, seen, depth + 1)
    end

    return clean
end

--------------------------------------------------
-- Write report
--------------------------------------------------

ensureDirectory(OUTPUT_PATH)

local file = fs.open(OUTPUT_PATH, "w")

if not file then
    error("Unable to create " .. OUTPUT_PATH)
end

local cleanReport = sanitize(report)
file.write(textutils.serialize(cleanReport))

print()
term.setTextColor(colors.lime)
print("Report generated:")
term.setTextColor(colors.white)
print(OUTPUT_PATH)