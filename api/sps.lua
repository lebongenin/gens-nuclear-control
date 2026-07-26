--================================================--
-- GEN'S Nuclear Control
-- API Module : SPS
-- Version : 0.3.0
--================================================--

local SafeCall = dofile("/core/safe_call.lua")

local SPS = {}
SPS.__index = SPS

local PERIPHERAL_TYPE = "spsPort"

--------------------------------------------------
-- Reading helpers
--------------------------------------------------

local function readNumber(device, errors, method, fallback)
    local value, err = SafeCall.getNumber(
        device,
        method,
        fallback
    )

    SafeCall.addError(errors, method, err)

    return value
end

local function readBoolean(device, errors, method, fallback)
    local value, err = SafeCall.getBoolean(
        device,
        method,
        fallback
    )

    SafeCall.addError(errors, method, err)

    return value
end

local function readPercentage(device, errors, method, fallback)
    local value, err = SafeCall.getPercentage(
        device,
        method,
        fallback
    )

    SafeCall.addError(errors, method, err)

    return value
end

local function readResource(device, errors, method)
    local value, err = SafeCall.getResource(
        device,
        method
    )

    SafeCall.addError(errors, method, err)

    return value
end

local function buildTank(resource, capacity, needed, percentage)
    resource = SafeCall.normalizeResource(resource)

    capacity = SafeCall.number(capacity, 0)
    needed = SafeCall.number(
        needed,
        math.max(capacity - resource.amount, 0)
    )

    if percentage == nil then
        percentage = SafeCall.calculatePercentage(
            resource.amount,
            capacity,
            0
        )
    end

    return {
        name = resource.name,
        amount = resource.amount,
        capacity = capacity,
        needed = needed,
        percentage = percentage
    }
end

--------------------------------------------------
-- Safety
--------------------------------------------------

local function evaluateSafety(state)
    local level = "safe"
    local warnings = {}

    local function warning(newLevel, message)
        local priorities = {
            safe = 1,
            warning = 2,
            critical = 3,
            emergency = 4
        }

        warnings[#warnings + 1] = message

        if priorities[newLevel] > priorities[level] then
            level = newLevel
        end
    end

    if not state.connected then
        warning("emergency", "SPS disconnected")

        return {
            level = level,
            safe = false,
            warnings = warnings
        }
    end

    if not state.formed then
        warning("critical", "SPS is not formed")
    end

    if state.formed and state.coils <= 0 then
        warning("critical", "No SPS coil detected")
    end

    if state.input.percentage <= 0.05 then
        warning("warning", "Polonium input nearly empty")
    end

    if state.output.percentage >= 0.95 then
        warning("critical", "Antimatter output nearly full")
    elseif state.output.percentage >= 0.80 then
        warning("warning", "Antimatter output is filling")
    end

    if state.input.amount > 0
        and state.processRate <= 0 then
        warning("warning", "SPS contains polonium but is idle")
    end

    return {
        level = level,
        safe = level == "safe",
        warnings = warnings
    }
end

--------------------------------------------------
-- Constructor
--------------------------------------------------

function SPS.new(peripheralName)
    local self = setmetatable({}, SPS)

    self.peripheralName = peripheralName
    self.device = nil

    self:refreshPeripheral()

    return self
end

--------------------------------------------------
-- Peripheral
--------------------------------------------------

function SPS:refreshPeripheral()
    if self.peripheralName then
        if peripheral.isPresent(self.peripheralName) then
            self.device = peripheral.wrap(self.peripheralName)
        else
            self.device = nil
        end
    else
        self.device = peripheral.find(PERIPHERAL_TYPE)
    end

    return self.device ~= nil
end

function SPS:isConnected()
    return self:refreshPeripheral()
end

function SPS:getPeripheral()
    return self.device
end

--------------------------------------------------
-- State
--------------------------------------------------

function SPS:getState()
    self:refreshPeripheral()

    local errors = {}

    if not self.device then
        local state = {
            connected = false,
            peripheralType = PERIPHERAL_TYPE,
            formed = false,
            errors = {
                {
                    method = "discovery",
                    message = "SPS unavailable"
                }
            },
            hasErrors = true
        }

        state.safety = evaluateSafety(state)

        return state
    end

    local device = self.device

    local input = buildTank(
        readResource(device, errors, "getInput"),
        readNumber(device, errors, "getInputCapacity", 0),
        readNumber(device, errors, "getInputNeeded", 0),
        readPercentage(
            device,
            errors,
            "getInputFilledPercentage",
            0
        )
    )

    local output = buildTank(
        readResource(device, errors, "getOutput"),
        readNumber(device, errors, "getOutputCapacity", 0),
        readNumber(device, errors, "getOutputNeeded", 0),
        readPercentage(
            device,
            errors,
            "getOutputFilledPercentage",
            0
        )
    )

    local energy = readNumber(
        device,
        errors,
        "getEnergy",
        0
    )

    local capacity = readNumber(
        device,
        errors,
        "getMaxEnergy",
        0
    )

    local energyPercentage = readPercentage(
        device,
        errors,
        "getEnergyFilledPercentage",
        nil
    )

    if energyPercentage == nil then
        energyPercentage =
            SafeCall.calculatePercentage(
                energy,
                capacity,
                0
            )
    end

    local state = {
        connected = true,
        peripheralType = PERIPHERAL_TYPE,

        formed = readBoolean(
            device,
            errors,
            "isFormed",
            false
        ),

        energy = energy,
        energyCapacity = capacity,

        energyNeeded = readNumber(
            device,
            errors,
            "getEnergyNeeded",
            math.max(capacity - energy, 0)
        ),

        energyPercentage = energyPercentage,

        input = input,
        output = output,

        processRate = readNumber(
            device,
            errors,
            "getProcessRate",
            0
        ),

        coils = readNumber(
            device,
            errors,
            "getCoils",
            0
        ),

        errors = errors
    }

    state.processing =
        state.processRate > 0
        and state.input.amount > 0

    state.hasErrors = #errors > 0
    state.safety = evaluateSafety(state)

    return state
end

function SPS:read()
    return self:getState()
end

function SPS:update()
    return self:getState()
end

return SPS