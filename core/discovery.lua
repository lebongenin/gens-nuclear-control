-- GEN'S Nuclear Control
-- Core peripheral discovery
-- Version 0.0.2

local discovery = {}

local ROLE_TYPES = {
    monitor = {
        "monitor"
    },

    modem = {
        "modem"
    },

    fusionReactor = {
        "fusionReactorLogicAdapter",
        "fusion_reactor_logic_adapter"
    }
}

local function matchesType(deviceType, acceptedTypes)
    for _, acceptedType in ipairs(acceptedTypes) do
        if deviceType == acceptedType then
            return true
        end
    end

    return false
end

function discovery.scan()
    local devices = {}

    for _, name in ipairs(peripheral.getNames()) do
        local deviceType = peripheral.getType(name)

        devices[#devices + 1] = {
            name = name,
            type = deviceType,
            peripheral = peripheral.wrap(name)
        }
    end

    return devices
end

function discovery.findByType(targetType)
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == targetType then
            return peripheral.wrap(name), name
        end
    end

    return nil, nil
end

function discovery.findByRole(role)
    local acceptedTypes = ROLE_TYPES[role]

    if not acceptedTypes then
        return nil, nil, "Unknown role: " .. tostring(role)
    end

    for _, name in ipairs(peripheral.getNames()) do
        local deviceType = peripheral.getType(name)

        if matchesType(deviceType, acceptedTypes) then
            return peripheral.wrap(name), name, deviceType
        end
    end

    return nil, nil, nil
end

function discovery.getMonitor()
    return discovery.findByRole("monitor")
end

function discovery.getModem()
    return discovery.findByRole("modem")
end

function discovery.getFusionReactor()
    return discovery.findByRole("fusionReactor")
end

function discovery.getSystemStatus()
    local monitor, monitorName, monitorType = discovery.getMonitor()
    local modem, modemName, modemType = discovery.getModem()
    local reactor, reactorName, reactorType = discovery.getFusionReactor()

    return {
        monitor = {
            connected = monitor ~= nil,
            peripheral = monitor,
            name = monitorName,
            type = monitorType
        },

        modem = {
            connected = modem ~= nil,
            peripheral = modem,
            name = modemName,
            type = modemType
        },

        fusionReactor = {
            connected = reactor ~= nil,
            peripheral = reactor,
            name = reactorName,
            type = reactorType
        }
    }
end

return discovery