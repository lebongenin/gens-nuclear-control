--================================================--
-- GEN'S Nuclear Control
-- Application : System Probe
-- Version : 0.0.1
--================================================--

local function printValue(label, value)
    term.setTextColor(colors.yellow)
    print(label .. ":")

    term.setTextColor(colors.white)

    if type(value) == "table" then
        textutils.pagedPrint(textutils.serialize(value))
    else
        print(tostring(value))
    end

    print()
end

local function safeCall(device, method)
    if not device or type(device[method]) ~= "function" then
        return nil, "method unavailable"
    end

    local success, result = pcall(device[method])

    if not success then
        return nil, result
    end

    return result
end

local function inspectDevice(title, peripheralType, methods)
    term.setTextColor(colors.cyan)
    print("================================")
    print(title)
    print("================================")
    term.setTextColor(colors.white)

    local device = peripheral.find(peripheralType)

    if not device then
        term.setTextColor(colors.red)
        print("OFFLINE")
        print()
        return
    end

    term.setTextColor(colors.lime)
    print("ONLINE")
    print()

    for _, method in ipairs(methods) do
        local result, err = safeCall(device, method)

        if err then
            printValue(method, "ERROR: " .. tostring(err))
        else
            printValue(method, result)
        end
    end
end

term.clear()
term.setCursorPos(1, 1)

inspectDevice(
    "FISSION REACTOR",
    "fissionReactorLogicAdapter",
    {
        "getStatus",
        "getTemperature",
        "getActualBurnRate",
        "getBurnRate",
        "getDamagePercent",
        "getFuel",
        "getFuelCapacity",
        "getCoolantFilledPercentage",
        "getHeatedCoolantFilledPercentage",
        "getWasteFilledPercentage"
    }
)

inspectDevice(
    "FUSION REACTOR",
    "fusionReactorLogicAdapter",
    {
        "isFormed",
        "isIgnited",
        "getProductionRate",
        "getInjectionRate",
        "getPlasmaTemperature",
        "getCaseTemperature",
        "getDTFuelFilledPercentage",
        "getDeuteriumFilledPercentage",
        "getTritiumFilledPercentage"
    }
)

inspectDevice(
    "INDUCTION MATRIX",
    "inductionPort",
    {
        "isFormed",
        "getEnergy",
        "getMaxEnergy",
        "getEnergyFilledPercentage",
        "getLastInput",
        "getLastOutput",
        "getTransferCap",
        "getInstalledCells",
        "getInstalledProviders"
    }
)

inspectDevice(
    "SPS",
    "spsPort",
    {
        "isFormed",
        "getEnergy",
        "getMaxEnergy",
        "getEnergyFilledPercentage",
        "getInput",
        "getInputCapacity",
        "getInputFilledPercentage",
        "getOutput",
        "getOutputCapacity",
        "getOutputFilledPercentage",
        "getProcessRate",
        "getCoils"
    }
)

inspectDevice(
    "APPLIED ENERGISTICS 2",
    "me_bridge",
    {
        "isConnected",
        "isOnline",
        "getTotalItemStorage",
        "getUsedItemStorage",
        "getAvailableItemStorage",
        "getEnergyCapacity",
        "getStoredEnergy",
        "getEnergyUsage",
        "getAverageEnergyInput",
        "getCells",
        "getDrives",
        "getCraftingCPUs",
        "getCraftingTasks"
    }
)