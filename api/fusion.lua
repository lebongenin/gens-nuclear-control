--================================================--
-- GEN'S Nuclear Control
-- API Module : Fusion Reactor
-- Version : 0.3.0
--================================================--

local Energy = dofile("/core/energy.lua")

local SafeCall = dofile("/core/safe_call.lua")

local Fusion = {}
Fusion.__index = Fusion

local PERIPHERAL_TYPE = "fusionReactorLogicAdapter"

--------------------------------------------------
-- Reading helpers
--------------------------------------------------

local function readNumber(device, errors, method, fallback, ...)
    local value, err = SafeCall.getNumber(
        device,
        method,
        fallback,
        ...
    )

    SafeCall.addError(errors, method, err)

    return value
end

local function readBoolean(device, errors, method, fallback, ...)
    local value, err = SafeCall.getBoolean(
        device,
        method,
        fallback,
        ...
    )

    SafeCall.addError(errors, method, err)

    return value
end

local function readPercentage(device, errors, method, fallback, ...)
    local value, err = SafeCall.getPercentage(
        device,
        method,
        fallback,
        ...
    )

    SafeCall.addError(errors, method, err)

    return value
end

local function readResource(device, errors, method, ...)
    local value, err = SafeCall.getResource(
        device,
        method,
        ...
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

    local priorities = {
        safe = 1,
        warning = 2,
        critical = 3,
        emergency = 4
    }

    local function raise(newLevel, message)
        warnings[#warnings + 1] = message

        if priorities[newLevel] > priorities[level] then
            level = newLevel
        end
    end

    if not state.connected then
        raise("emergency", "Fusion reactor disconnected")

        return {
            level = level,
            safe = false,
            warnings = warnings
        }
    end

    if not state.formed then
        raise("critical", "Fusion reactor is not formed")
    end

    if state.formed and not state.ignited then
        raise("warning", "Fusion reactor is not ignited")
    end

    if state.ignited then
        if state.dtFuel.percentage <= 0.05 then
            raise("critical", "D-T fuel buffer nearly empty")
        elseif state.dtFuel.percentage <= 0.25 then
            raise("warning", "D-T fuel buffer is low")
        end

        if state.productionRate <= 0 then
            raise("critical", "Ignited reactor produces no energy")
        end
    end

    if state.activeCooled then
        if state.water.percentage ~= nil
            and state.water.percentage <= 0.10 then
            raise("critical", "Fusion coolant water is low")
        end

        if state.steam.percentage ~= nil
            and state.steam.percentage >= 0.95 then
            raise("critical", "Fusion steam tank nearly full")
        end
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

function Fusion.new(peripheralName)
    local self = setmetatable({}, Fusion)

    self.peripheralName = peripheralName
    self.device = nil

    self:refreshPeripheral()

    return self
end

--------------------------------------------------
-- Peripheral
--------------------------------------------------

function Fusion:refreshPeripheral()
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

function Fusion:isConnected()
    return self:refreshPeripheral()
end

function Fusion:getPeripheral()
    return self.device
end

--------------------------------------------------
-- State
--------------------------------------------------

function Fusion:getState()
    self:refreshPeripheral()

    local errors = {}

    if not self.device then
        local state = {
            connected = false,
            peripheralType = PERIPHERAL_TYPE,
            formed = false,
            ignited = false,
            activeCooled = false,
            errors = {
                {
                    method = "discovery",
                    message = "Fusion reactor unavailable"
                }
            },
            hasErrors = true
        }

        state.safety = evaluateSafety(state)

        return state
    end

    local device = self.device

    local dtFuel = buildTank(
        readResource(device, errors, "getDTFuel"),
        readNumber(device, errors, "getDTFuelCapacity", 0),
        readNumber(device, errors, "getDTFuelNeeded", 0),
        readPercentage(
            device,
            errors,
            "getDTFuelFilledPercentage",
            0
        )
    )

    local deuterium = buildTank(
        readResource(device, errors, "getDeuterium"),
        readNumber(device, errors, "getDeuteriumCapacity", 0),
        readNumber(device, errors, "getDeuteriumNeeded", 0),
        readPercentage(
            device,
            errors,
            "getDeuteriumFilledPercentage",
            0
        )
    )

    local tritium = buildTank(
        readResource(device, errors, "getTritium"),
        readNumber(device, errors, "getTritiumCapacity", 0),
        readNumber(device, errors, "getTritiumNeeded", 0),
        readPercentage(
            device,
            errors,
            "getTritiumFilledPercentage",
            0
        )
    )

    local water = buildTank(
        readResource(device, errors, "getWater"),
        readNumber(device, errors, "getWaterCapacity", 0),
        readNumber(device, errors, "getWaterNeeded", 0),
        readPercentage(
            device,
            errors,
            "getWaterFilledPercentage",
            nil
        )
    )

    local steam = buildTank(
        readResource(device, errors, "getSteam"),
        readNumber(device, errors, "getSteamCapacity", 0),
        readNumber(device, errors, "getSteamNeeded", 0),
        readPercentage(
            device,
            errors,
            "getSteamFilledPercentage",
            nil
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

        ignited = readBoolean(
            device,
            errors,
            "isIgnited",
            false
        ),

        activeCooled = readBoolean(
            device,
            errors,
            "isActiveCooledLogic",
            false
        ),

		productionRate = Energy.joulesToFE(
		readNumber(
        device,
        errors,
        "getProductionRate",
        0
    )
),

        injectionRate = readNumber(
            device,
            errors,
            "getInjectionRate",
            0
        ),

        plasmaTemperature = readNumber(
            device,
            errors,
            "getPlasmaTemperature",
            0
        ),

        caseTemperature = readNumber(
            device,
            errors,
            "getCaseTemperature",
            0
        ),

		environmentalLoss = Energy.joulesToFE(
			readNumber(
			device,
			errors,
			"getEnvironmentalLoss",
			0
    )
),

		transferLoss = Energy.joulesToFE(
			readNumber(
			device,
			errors,
			"getTransferLoss",
			0
    )
),

        dtFuel = dtFuel,
        deuterium = deuterium,
        tritium = tritium,
        water = water,
        steam = steam,

        errors = errors
    }

    state.netProduction =
        math.max(
            state.productionRate
            - state.environmentalLoss
            - state.transferLoss,
            0
        )

    state.hasErrors = #errors > 0
    state.safety = evaluateSafety(state)

    return state
end

function Fusion:read()
    return self:getState()
end

function Fusion:update()
    return self:getState()
end

--------------------------------------------------
-- Controls
--------------------------------------------------

function Fusion:setInjectionRate(rate)
    if not SafeCall.isFiniteNumber(rate) or rate < 0 then
        return {
            success = false,
            action = "setInjectionRate",
            error = "Invalid injection rate"
        }
    end

    self:refreshPeripheral()

    local success, value, err = SafeCall.raw(
        self.device,
        "setInjectionRate",
        rate
    )

    return {
        success = success,
        value = value,
        error = err,
        action = "setInjectionRate",
        requestedRate = rate
    }
end

function Fusion:setActiveCooled(enabled)
    if type(enabled) ~= "boolean" then
        return {
            success = false,
            action = "setActiveCooledLogic",
            error = "Expected a boolean"
        }
    end

    self:refreshPeripheral()

    local success, value, err = SafeCall.raw(
        self.device,
        "setActiveCooledLogic",
        enabled
    )

    return {
        success = success,
        value = value,
        error = err,
        action = "setActiveCooledLogic",
        enabled = enabled
    }
end

return Fusion