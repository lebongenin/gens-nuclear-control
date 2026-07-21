--================================================--
-- GEN'S Nuclear Control
-- Version : 0.0.4
-- Module  : Fusion Reactor API
--================================================--

local discovery = dofile("/core/discovery.lua")
local logger = dofile("/core/logger.lua")

local Fusion = {}
Fusion.__index = Fusion

local function safeCall(peripheralObject, methodName, ...)
    if not peripheralObject then
        return nil, "Peripheral unavailable"
    end

    local method = peripheralObject[methodName]

    if type(method) ~= "function" then
        return nil, "Unsupported method: " .. tostring(methodName)
    end

    local result = table.pack(pcall(method, ...))

    if not result[1] then
        return nil, tostring(result[2])
    end

    return table.unpack(result, 2, result.n)
end

function Fusion.new()
    local peripheralObject, name, deviceType =
        discovery.getFusionReactor()

    local self = setmetatable({}, Fusion)

    self.peripheral = peripheralObject
    self.name = name
    self.type = deviceType

    if self.peripheral then
        logger.info(
            "Fusion API connected to "
                .. tostring(self.name)
        )
    else
        logger.warning(
            "Fusion API could not find a reactor"
        )
    end

    return self
end

function Fusion:isOnline()
    return self.peripheral ~= nil
end

function Fusion:reconnect()
    local peripheralObject, name, deviceType =
        discovery.getFusionReactor()

    self.peripheral = peripheralObject
    self.name = name
    self.type = deviceType

    return self:isOnline()
end

function Fusion:getName()
    return self.name
end

function Fusion:getType()
    return self.type
end

function Fusion:isFormed()
    return safeCall(self.peripheral, "isFormed")
end

function Fusion:isIgnited()
    return safeCall(self.peripheral, "isIgnited")
end

function Fusion:getInjectionRate()
    return safeCall(self.peripheral, "getInjectionRate")
end

function Fusion:setInjectionRate(rate)
    if type(rate) ~= "number" then
        return false, "Injection rate must be a number"
    end

    local result, errorMessage =
        safeCall(self.peripheral, "setInjectionRate", rate)

    if result == nil and errorMessage then
        logger.error(
            "Unable to set injection rate: "
                .. tostring(errorMessage)
        )

        return false, errorMessage
    end

    logger.info(
        "Injection rate changed to "
            .. tostring(rate)
    )

    return true
end

function Fusion:getCaseTemperature()
    return safeCall(
        self.peripheral,
        "getCaseTemperature"
    )
end

function Fusion:getPlasmaTemperature()
    return safeCall(
        self.peripheral,
        "getPlasmaTemperature"
    )
end

function Fusion:getIgnitionTemperature()
    return safeCall(
        self.peripheral,
        "getIgnitionTemperature"
    )
end

function Fusion:getDTFuel()
    return safeCall(self.peripheral, "getDTFuel")
end

function Fusion:getDTFuelCapacity()
    return safeCall(
        self.peripheral,
        "getDTFuelCapacity"
    )
end

function Fusion:getDTFuelPercentage()
    return safeCall(
        self.peripheral,
        "getDTFuelFilledPercentage"
    )
end

function Fusion:getTritium()
    return safeCall(self.peripheral, "getTritium")
end

function Fusion:getTritiumCapacity()
    return safeCall(
        self.peripheral,
        "getTritiumCapacity"
    )
end

function Fusion:getTritiumPercentage()
    return safeCall(
        self.peripheral,
        "getTritiumFilledPercentage"
    )
end

function Fusion:getDeuterium()
    return safeCall(self.peripheral, "getDeuterium")
end

function Fusion:getDeuteriumCapacity()
    return safeCall(
        self.peripheral,
        "getDeuteriumCapacity"
    )
end

function Fusion:getDeuteriumPercentage()
    return safeCall(
        self.peripheral,
        "getDeuteriumFilledPercentage"
    )
end

function Fusion:getStatus()
    return {
        online = self:isOnline(),
        name = self:getName(),
        type = self:getType(),
        formed = self:isFormed(),
        ignited = self:isIgnited(),
        injectionRate = self:getInjectionRate(),
        caseTemperature = self:getCaseTemperature(),
        plasmaTemperature = self:getPlasmaTemperature(),
        ignitionTemperature = self:getIgnitionTemperature(),
        dtFuel = self:getDTFuel(),
        dtFuelCapacity = self:getDTFuelCapacity(),
        dtFuelPercentage = self:getDTFuelPercentage(),
        tritium = self:getTritium(),
        tritiumCapacity = self:getTritiumCapacity(),
        tritiumPercentage = self:getTritiumPercentage(),
        deuterium = self:getDeuterium(),
        deuteriumCapacity = self:getDeuteriumCapacity(),
        deuteriumPercentage = self:getDeuteriumPercentage()
    }
end

return Fusion