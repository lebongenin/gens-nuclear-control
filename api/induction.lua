--================================================--
-- GEN'S Nuclear Control
-- API Module : Induction Matrix
-- Version : 0.3.0
--================================================--

local Energy = dofile("/core/energy.lua")

local SafeCall = dofile("/core/safe_call.lua")

local Induction = {}
Induction.__index = Induction

local PERIPHERAL_TYPE = "inductionPort"

--------------------------------------------------
-- Helpers
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

local function evaluateSafety(state)
    local level = "safe"
    local warnings = {}

    if not state.connected then
        level = "emergency"
        warnings[#warnings + 1] =
            "Induction Matrix disconnected"
    elseif not state.formed then
        level = "critical"
        warnings[#warnings + 1] =
            "Induction Matrix is not formed"
    elseif state.percentage <= 0.05 then
        level = "critical"
        warnings[#warnings + 1] =
            "Energy storage nearly empty"
    elseif state.percentage <= 0.20 then
        level = "warning"
        warnings[#warnings + 1] =
            "Energy storage is low"
    elseif state.percentage >= 0.98
        and state.netFlow > 0 then
        level = "warning"
        warnings[#warnings + 1] =
            "Energy storage almost full"
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

function Induction.new(peripheralName)
    local self = setmetatable({}, Induction)

    self.peripheralName = peripheralName
    self.device = nil

    self:refreshPeripheral()

    return self
end

--------------------------------------------------
-- Peripheral
--------------------------------------------------

function Induction:refreshPeripheral()
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

function Induction:isConnected()
    return self:refreshPeripheral()
end

function Induction:getPeripheral()
    return self.device
end

--------------------------------------------------
-- State
--------------------------------------------------

function Induction:getState()
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
                    message = "Induction Matrix unavailable"
                }
            },
            hasErrors = true,
            percentage = 0,
            netFlow = 0
        }

        state.safety = evaluateSafety(state)

        return state
    end

    local device = self.device

    local energy = Energy.joulesToFE(
	readNumber(
        device,
        errors,
        "getEnergy",
        0
    )
)

    local capacity = Energy.joulesToFE(
    readNumber(
        device,
        errors,
        "getMaxEnergy",
        0
    )
)

    local percentage, percentageError =
        SafeCall.getPercentage(
            device,
            "getEnergyFilledPercentage",
            nil
        )

    SafeCall.addError(
        errors,
        "getEnergyFilledPercentage",
        percentageError
    )

    if percentage == nil then
        percentage = SafeCall.calculatePercentage(
            energy,
            capacity,
            0
        )
    end

    local input = Energy.joulesToFE(
    readNumber(
        device,
        errors,
        "getLastInput",
        0
    )
)

    local output = Energy.joulesToFE(
    readNumber(
        device,
        errors,
        "getLastOutput",
        0
    )
)

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
        capacity = capacity,

        needed = Energy.joulesToFE(
    readNumber(
        device,
        errors,
        "getEnergyNeeded",
        0
    )
),

        percentage = percentage,

        input = input,
        output = output,
        netFlow = input - output,

        transferCapacity = Energy.joulesToFE(
    readNumber(
        device,
        errors,
        "getTransferCap",
        0
    )
),

        installedCells = readNumber(
            device,
            errors,
            "getInstalledCells",
            0
        ),

        installedProviders = readNumber(
            device,
            errors,
            "getInstalledProviders",
            0
        ),

        errors = errors
    }

    state.inputUtilization =
        SafeCall.calculatePercentage(
            state.input,
            state.transferCapacity,
            0
        )

    state.outputUtilization =
        SafeCall.calculatePercentage(
            state.output,
            state.transferCapacity,
            0
        )

    state.charging = state.netFlow > 0
    state.discharging = state.netFlow < 0
    state.stable = state.netFlow == 0

    state.hasErrors = #errors > 0
    state.safety = evaluateSafety(state)

    return state
end

function Induction:read()
    return self:getState()
end

function Induction:update()
    return self:getState()
end

return Induction