--================================================--
-- GEN'S Nuclear Control
-- API Module : Fission Reactor
-- Version : 0.1.0
--================================================--

local SafeCall = dofile("/core/safe_call.lua")

local Fission = {}
Fission.__index = Fission

local PERIPHERAL_TYPE = "fissionReactorLogicAdapter"

--------------------------------------------------
-- Internal helpers
--------------------------------------------------

local function clamp(value, minimum, maximum)
    if type(value) ~= "number" then
        return minimum
    end

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function addError(errors, methodName, err)
    SafeCall.addError(errors, methodName, err)
end

local function readNumber(
    device,
    errors,
    methodName,
    fallback,
    ...
)
    local value, err = SafeCall.getNumber(
        device,
        methodName,
        fallback,
        ...
    )

    addError(errors, methodName, err)

    return value
end

local function readBoolean(
    device,
    errors,
    methodName,
    fallback,
    ...
)
    local value, err = SafeCall.getBoolean(
        device,
        methodName,
        fallback,
        ...
    )

    addError(errors, methodName, err)

    return value
end

local function readPercentage(
    device,
    errors,
    methodName,
    fallback,
    ...
)
    local value, err = SafeCall.getPercentage(
        device,
        methodName,
        fallback,
        ...
    )

    addError(errors, methodName, err)

    return value
end

local function readResource(
    device,
    errors,
    methodName,
    ...
)
    local value, err = SafeCall.getResource(
        device,
        methodName,
        ...
    )

    addError(errors, methodName, err)

    return value
end

local function buildTank(
    resource,
    capacity,
    needed,
    percentage
)
    resource = SafeCall.normalizeResource(resource)

    if not SafeCall.isFiniteNumber(capacity) then
        capacity = 0
    end

    if not SafeCall.isFiniteNumber(needed) then
        needed = math.max(capacity - resource.amount, 0)
    end

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
-- Safety evaluation
--------------------------------------------------

local function evaluateSafety(state)
    local warnings = {}
    local level = "safe"

    local function raise(newLevel, message)
        warnings[#warnings + 1] = message

        local priorities = {
            safe = 1,
            warning = 2,
            critical = 3,
            emergency = 4
        }

        if priorities[newLevel] > priorities[level] then
            level = newLevel
        end
    end

    if not state.connected then
        raise("emergency", "Fission reactor disconnected")

        return {
            level = level,
            safe = false,
            warnings = warnings,
            shouldScram = false
        }
    end

    if not state.formed then
        raise("critical", "Fission reactor is not formed")
    end

    if state.damagePercent >= 80 then
        raise("emergency", "Reactor damage above 80%")
    elseif state.damagePercent >= 25 then
        raise("critical", "Reactor damage above 25%")
    elseif state.damagePercent > 0 then
        raise("warning", "Reactor has structural damage")
    end

    if state.temperature >= 1200 then
        raise("emergency", "Reactor temperature is extreme")
    elseif state.temperature >= 1000 then
        raise("critical", "Reactor temperature is critical")
    elseif state.temperature >= 800 then
        raise("warning", "Reactor temperature is high")
    end

    if state.active then
        if state.coolant.percentage <= 0.05 then
            raise("emergency", "Coolant tank nearly empty")
        elseif state.coolant.percentage <= 0.25 then
            raise("critical", "Coolant level is low")
        end

        if state.waste.percentage >= 0.95 then
            raise("emergency", "Nuclear waste tank almost full")
        elseif state.waste.percentage >= 0.80 then
            raise("critical", "Nuclear waste tank is filling")
        end

        if state.heatedCoolant.percentage >= 0.95 then
            raise(
                "critical",
                "Heated coolant tank almost full"
            )
        end

        if state.fuel.percentage <= 0.05 then
            raise("warning", "Fissile fuel nearly empty")
        end
    end

    if state.actualBurnRate > state.maxBurnRate then
        raise(
            "critical",
            "Actual burn rate exceeds maximum burn rate"
        )
    end

    local shouldScram =
        level == "emergency" and state.active

    return {
        level = level,
        safe = level == "safe",
        warnings = warnings,
        shouldScram = shouldScram
    }
end

--------------------------------------------------
-- Constructor
--------------------------------------------------

function Fission.new(peripheralName)
    local self = setmetatable({}, Fission)

    self.peripheralName = peripheralName
    self.device = nil

    self:refreshPeripheral()

    return self
end

--------------------------------------------------
-- Peripheral discovery
--------------------------------------------------

function Fission:refreshPeripheral()
    if self.peripheralName then
        if peripheral.isPresent(self.peripheralName) then
            self.device = peripheral.wrap(
                self.peripheralName
            )
        else
            self.device = nil
        end
    else
        self.device = peripheral.find(
            PERIPHERAL_TYPE
        )
    end

    return self.device ~= nil
end

function Fission:isConnected()
    if self.device == nil then
        return self:refreshPeripheral()
    end

    return true
end

function Fission:getPeripheral()
    return self.device
end

--------------------------------------------------
-- Reactor state
--------------------------------------------------

function Fission:getState()
    self:refreshPeripheral()

    local errors = {}

    if not self.device then
        local disconnectedState = {
            connected = false,
            peripheralType = PERIPHERAL_TYPE,
            formed = false,
            active = false,
            errors = {
                {
                    method = "discovery",
                    message = "Fission reactor unavailable"
                }
            }
        }

        disconnectedState.safety =
            evaluateSafety(disconnectedState)

        return disconnectedState
    end

    local device = self.device

    local formed = readBoolean(
        device,
        errors,
        "isFormed",
        false
    )

    local active = readBoolean(
        device,
        errors,
        "getStatus",
        false
    )

    local temperature = readNumber(
        device,
        errors,
        "getTemperature",
        0
    )

    local burnRate = readNumber(
        device,
        errors,
        "getBurnRate",
        0
    )

    local actualBurnRate = readNumber(
        device,
        errors,
        "getActualBurnRate",
        0
    )

    local maxBurnRate = readNumber(
        device,
        errors,
        "getMaxBurnRate",
        0
    )

    local damagePercent = readNumber(
        device,
        errors,
        "getDamagePercent",
        0
    )

    damagePercent = clamp(
        damagePercent,
        0,
        100
    )

    --------------------------------------------------
    -- Fuel
    --------------------------------------------------

    local fuel = buildTank(
        readResource(
            device,
            errors,
            "getFuel"
        ),
        readNumber(
            device,
            errors,
            "getFuelCapacity",
            0
        ),
        readNumber(
            device,
            errors,
            "getFuelNeeded",
            0
        ),
        readPercentage(
            device,
            errors,
            "getFuelFilledPercentage",
            0
        )
    )

    --------------------------------------------------
    -- Coolant
    --------------------------------------------------

    local coolant = buildTank(
        readResource(
            device,
            errors,
            "getCoolant"
        ),
        readNumber(
            device,
            errors,
            "getCoolantCapacity",
            0
        ),
        readNumber(
            device,
            errors,
            "getCoolantNeeded",
            0
        ),
        readPercentage(
            device,
            errors,
            "getCoolantFilledPercentage",
            0
        )
    )

    --------------------------------------------------
    -- Heated coolant
    --------------------------------------------------

    local heatedCoolant = buildTank(
        readResource(
            device,
            errors,
            "getHeatedCoolant"
        ),
        readNumber(
            device,
            errors,
            "getHeatedCoolantCapacity",
            0
        ),
        readNumber(
            device,
            errors,
            "getHeatedCoolantNeeded",
            0
        ),
        readPercentage(
            device,
            errors,
            "getHeatedCoolantFilledPercentage",
            0
        )
    )

    --------------------------------------------------
    -- Nuclear waste
    --------------------------------------------------

    local waste = buildTank(
        readResource(
            device,
            errors,
            "getWaste"
        ),
        readNumber(
            device,
            errors,
            "getWasteCapacity",
            0
        ),
        readNumber(
            device,
            errors,
            "getWasteNeeded",
            0
        ),
        readPercentage(
            device,
            errors,
            "getWasteFilledPercentage",
            0
        )
    )

    --------------------------------------------------
    -- Reactor characteristics
    --------------------------------------------------

    local state = {
        connected = true,
        peripheralType = PERIPHERAL_TYPE,

        formed = formed,
        active = active,

        temperature = temperature,

        burnRate = burnRate,
        actualBurnRate = actualBurnRate,
        maxBurnRate = maxBurnRate,

        damagePercent = damagePercent,

        fuel = fuel,
        coolant = coolant,
        heatedCoolant = heatedCoolant,
        waste = waste,

        boilEfficiency = readNumber(
            device,
            errors,
            "getBoilEfficiency",
            0
        ),

        environmentalLoss = readNumber(
            device,
            errors,
            "getEnvironmentalLoss",
            0
        ),

        heatingRate = readNumber(
            device,
            errors,
            "getHeatingRate",
            0
        ),

        fuelAssemblies = readNumber(
            device,
            errors,
            "getFuelAssemblies",
            0
        ),

        fuelSurfaceArea = readNumber(
            device,
            errors,
            "getFuelSurfaceArea",
            0
        ),

        errors = errors
    }

    state.burnRatePercentage =
        SafeCall.calculatePercentage(
            state.actualBurnRate,
            state.maxBurnRate,
            0
        )

    state.hasErrors = #errors > 0
    state.safety = evaluateSafety(state)

    return state
end

--------------------------------------------------
-- Read aliases
--------------------------------------------------

function Fission:read()
    return self:getState()
end

function Fission:update()
    return self:getState()
end

--------------------------------------------------
-- Reactor control
--------------------------------------------------

function Fission:activate()
    self:refreshPeripheral()

    local success, value, err = SafeCall.raw(
        self.device,
        "activate"
    )

    return {
        success = success,
        value = value,
        error = err,
        action = "activate"
    }
end

function Fission:scram()
    self:refreshPeripheral()

    local success, value, err = SafeCall.raw(
        self.device,
        "scram"
    )

    return {
        success = success,
        value = value,
        error = err,
        action = "scram"
    }
end

function Fission:setBurnRate(rate)
    if not SafeCall.isFiniteNumber(rate) then
        return {
            success = false,
            error = "Invalid burn rate",
            action = "setBurnRate"
        }
    end

    self:refreshPeripheral()

    if not self.device then
        return {
            success = false,
            error = "Fission reactor unavailable",
            action = "setBurnRate"
        }
    end

    local maxBurnRate, maxErr =
        SafeCall.getNumber(
            self.device,
            "getMaxBurnRate",
            nil
        )

    if maxErr then
        return {
            success = false,
            error = maxErr,
            action = "setBurnRate"
        }
    end

    rate = clamp(rate, 0, maxBurnRate)

    local success, value, err = SafeCall.raw(
        self.device,
        "setBurnRate",
        rate
    )

    return {
        success = success,
        value = value,
        error = err,
        action = "setBurnRate",
        requestedRate = rate
    }
end

--------------------------------------------------
-- Emergency helper
--------------------------------------------------

function Fission:scramIfUnsafe()
    local state = self:getState()

    if not state.safety.shouldScram then
        return {
            success = true,
            action = "none",
            message = "SCRAM not required",
            state = state
        }
    end

    local result = self:scram()
    result.state = state

    return result
end

return Fission