--================================================--
-- GEN'S Nuclear Control
-- Version : 0.1.0
-- Module  : Induction Matrix API
--================================================--

local discovery = dofile("/core/discovery.lua")
local logger = dofile("/core/logger.lua")
local energy = dofile("/core/energy.lua")

local Induction = {}
Induction.__index = Induction

--------------------------------------------------
-- Safe peripheral call
--------------------------------------------------

local function safeCall(peripheralObject, methodName, ...)
    if not peripheralObject then
        return nil, "Peripheral unavailable"
    end

    local method = peripheralObject[methodName]

    if type(method) ~= "function" then
        return nil,
            "Unsupported method: "
            .. tostring(methodName)
    end

    local result = table.pack(
        pcall(method, ...)
    )

    if not result[1] then
        return nil, tostring(result[2])
    end

    return table.unpack(
        result,
        2,
        result.n
    )
end

--------------------------------------------------
-- Constructor
--------------------------------------------------

function Induction.new()
    local peripheralObject, name, deviceType =
        discovery.getInductionMatrix()

    local self = setmetatable({}, Induction)

    self.peripheral = peripheralObject
    self.name = name
    self.type = deviceType

    if self.peripheral then
        logger.info(
            "Induction API connected to "
                .. tostring(self.name)
        )
    else
        logger.warning(
            "Induction API could not find a matrix"
        )
    end

    return self
end

--------------------------------------------------
-- Connection
--------------------------------------------------

function Induction:isConnected()
    return self.peripheral ~= nil
end

function Induction:isOnline()
    return self:isConnected()
end

function Induction:reconnect()
    local peripheralObject, name, deviceType =
        discovery.getInductionMatrix()

    self.peripheral = peripheralObject
    self.name = name
    self.type = deviceType

    return self:isConnected()
end

function Induction:getName()
    return self.name
end

function Induction:getType()
    return self.type
end

--------------------------------------------------
-- Energy storage
--------------------------------------------------

function Induction:getEnergy()
    local value, errorMessage = safeCall(
        self.peripheral,
        "getEnergy"
    )

    if value == nil then
        return nil, errorMessage
    end

    return energy.joulesToFE(value)
end

function Induction:getMaxEnergy()
    local value, errorMessage = safeCall(
        self.peripheral,
        "getMaxEnergy"
    )

    if value == nil then
        return nil, errorMessage
    end

    return energy.joulesToFE(value)
end

function Induction:getEnergyNeeded()
    local value, errorMessage = safeCall(
        self.peripheral,
        "getEnergyNeeded"
    )

    if value == nil then
        return nil, errorMessage
    end

    return energy.joulesToFE(value)
end

function Induction:getFilledPercentage()
    return safeCall(
        self.peripheral,
        "getEnergyFilledPercentage"
    )
end

function Induction:getInput()
    local value, errorMessage = safeCall(
        self.peripheral,
        "getLastInput"
    )

    if value == nil then
        return nil, errorMessage
    end

    return energy.joulesToFE(value)
end

function Induction:getOutput()
    local value, errorMessage = safeCall(
        self.peripheral,
        "getLastOutput"
    )

    if value == nil then
        return nil, errorMessage
    end

    return energy.joulesToFE(value)
end

function Induction:getTransferCapacity()
    local value, errorMessage = safeCall(
        self.peripheral,
        "getTransferCap"
    )

    if value == nil then
        return nil, errorMessage
    end

    return energy.joulesToFE(value)
end

--------------------------------------------------
-- Energy transfer
--------------------------------------------------

function Induction:getInput()
    return safeCall(
        self.peripheral,
        "getLastInput"
    )
	
	   if value == nil then
        return nil, errorMessage
    end

    return energy.joulesToFE(value)
	
end

function Induction:getOutput()
    return safeCall(
        self.peripheral,
        "getLastOutput"
    )
	
	    if value == nil then
        return nil, errorMessage
    end
	
end

function Induction:getTransferCapacity()
    return safeCall(
        self.peripheral,
        "getTransferCap"
    )
end

--------------------------------------------------
-- Components
--------------------------------------------------

function Induction:getInstalledCells()
    return safeCall(
        self.peripheral,
        "getInstalledCells"
    )
end

function Induction:getInstalledProviders()
    return safeCall(
        self.peripheral,
        "getInstalledProviders"
    )
end

--------------------------------------------------
-- Complete matrix status
--------------------------------------------------

function Induction:getStatus()
    if not self:isConnected() then
        return {
            connected = false,
            online = false,

            name = self.name,
            type = self.type,

            energy = nil,
            capacity = nil,
            needed = nil,
            percentage = nil,

            input = nil,
            output = nil,
            netFlow = nil,

            error = "Induction Matrix unavailable"
        }
    end

    local energy = self:getEnergy()
    local capacity = self:getMaxEnergy()

    local input = self:getInput()
    local output = self:getOutput()

    local percentage =
        self:getFilledPercentage()

    -- Fallback if the percentage method fails.
    if percentage == nil
        and type(energy) == "number"
        and type(capacity) == "number"
        and capacity > 0 then

        percentage = energy / capacity
    end

    local netFlow = nil

    if type(input) == "number"
        and type(output) == "number" then

        netFlow = input - output
    end

    return {
        connected = true,
        online = true,

        name = self:getName(),
        type = self:getType(),

        energy = energy,
        capacity = capacity,

        needed =
            self:getEnergyNeeded(),

        percentage = percentage,

        -- Already returned in FE/t.
        input = input,
        output = output,

        -- Positive means charging.
        -- Negative means discharging.
        netFlow = netFlow,

        transferCapacity =
            self:getTransferCapacity(),

        installedCells =
            self:getInstalledCells(),

        installedProviders =
            self:getInstalledProviders()
    }
end

return Induction