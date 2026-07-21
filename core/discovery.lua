local discovery = {}

function discovery.scan()
    local devices = {}

    for _, name in ipairs(peripheral.getNames()) do
        local deviceType = peripheral.getType(name)

        devices[#devices + 1] = {
            name = name,
            type = deviceType
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

return discovery
