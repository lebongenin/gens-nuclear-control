--================================================--
-- GEN'S Nuclear Control
-- Version : 0.1.0
-- Module  : Fusion Reactor API
--================================================--

local discovery = dofile("/core/discovery.lua")
local logger = dofile("/core/logger.lua")

local Fusion = {}
Fusion.__index = Fusion

--------------------------------------------------
-- Safe peripheral call
--------------------------------------------------

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

--------------------------------------------------
-- Normalize Mekanism chemical tables
--------------------------------------------------

local function normalizeChemical(value)
    if type(value) ~= "table" then
        return {
            amount = 0,
            chemical = "mekanism:empty"
        }
    end

    return {
        amount = tonumber(value.amount) or 0,
        chemical = value.name or "mekanism:empty"
    }
end

--------------------------------------------------
-- Constructor
--------------------------------------------------

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

--------------------------------------------------
-- Connection
--------------------------------------------------

function Fusion:isConnected()
    return self.peripheral ~= nil
end

-- Kept for compatibility with older code.
function Fusion:isOnline()
    return self:isConnected()
end

function Fusion:reconnect()
    local peripheralObject, name, deviceType =
        discovery.getFusionReactor()

    self.peripheral = peripheralObject
    self.name = name
    self.type = deviceType

    return self:isConnected()
end

function Fusion:getName()
    return self.name
end

function Fusion:getType()
    return self.type
end

--------------------------------------------------
-- Reactor state
--------------------------------------------------

function Fusion:isFormed()
    return safeCall(self.peripheral, "isFormed")
end

function Fusion:isIgnited()
    return safeCall(self.peripheral, "isIgnited")
end

function Fusion:getInjectionRate()
    return safeCall(
        self.peripheral,
        "getInjectionRate"
    )
end

function Fusion:setInjectionRate(rate)
    if type(rate) ~= "number" then
        return false, "Injection rate must be a number"
    end

    local result, errorMessage =
        safeCall(
            self.peripheral,
            "setInjectionRate",
            rate
        )

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

--------------------------------------------------
-- Temperatures
--------------------------------------------------

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

--------------------------------------------------
-- Fuel
--------------------------------------------------

function Fusion:getDTFuel()
    local value, errorMessage =
        safeCall(self.peripheral, "getDTFuel")

    if value == nil then
        return nil, errorMessage
    end

    return normalizeChemical(value)
end

function Fusion:getTritium()
    local value, errorMessage =
        safeCall(self.peripheral, "getTritium")

    if value == nil then
        return nil, errorMessage
    end

    return normalizeChemical(value)
end

function Fusion:getDeuterium()
    local value, errorMessage =
        safeCall(self.peripheral, "getDeuterium")

    if value == nil then
        return nil, errorMessage
    end

    return normalizeChemical(value)
end

--------------------------------------------------
-- Logic and losses
--------------------------------------------------

function Fusion:getLogicMode()
    return safeCall(
        self.peripheral,
        "getLogicMode"
    )
end

function Fusion:getEnvironmentalLoss()
    return safeCall(
        self.peripheral,
        "getEnvironmentalLoss"
    )
end

function Fusion:getTransferLoss()
    return safeCall(
        self.peripheral,
        "getTransferLoss"
    )
end

--------------------------------------------------
-- Energy production
--------------------------------------------------

function Fusion:getProduction()
    return safeCall(
        self.peripheral,
        "getProduction"
    )
end

--------------------------------------------------
-- Complete dashboard status
--------------------------------------------------

function Fusion:getStatus()
    if not self:isConnected() then
        return {
            connected = false,
            online = false,
            formed = false,
            ignited = false,
            name = self.name,
            type = self.type,
            error = "Fusion Reactor unavailable"
        }
    end

    local formed = self:isFormed()
    local ignited = self:isIgnited()

    return {
        connected = true,

        -- For the dashboard, ONLINE means ignited.
        online = ignited == true,

        name = self:getName(),
        type = self:getType(),

        formed = formed == true,
        ignited = ignited == true,

        injectionRate = self:getInjectionRate(),
		
		production = self:getProduction(),

        caseTemperature =
            self:getCaseTemperature(),

        plasmaTemperature =
            self:getPlasmaTemperature(),

        logicMode =
            self:getLogicMode(),

        environmentalLoss =
            self:getEnvironmentalLoss(),

        transferLoss =
            self:getTransferLoss(),

        dtFuel =
            self:getDTFuel(),

        tritium =
            self:getTritium(),

        deuterium =
            self:getDeuterium()
    }
end

return Fusion