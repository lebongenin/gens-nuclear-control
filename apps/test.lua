-- GEN'S Nuclear Control
-- Discovery test
-- Version 0.0.2

local discovery = dofile("/core/discovery.lua")

local function statusText(connected)
    if connected then
        return "ONLINE"
    end

    return "NOT FOUND"
end

local function printDevice(label, device)
    write(label .. ": ")

    if device.connected then
        term.setTextColor(colors.lime)
        print(statusText(true))

        term.setTextColor(colors.lightGray)
        print("  Name: " .. tostring(device.name))
        print("  Type: " .. tostring(device.type))
    else
        term.setTextColor(colors.red)
        print(statusText(false))
    end

    term.setTextColor(colors.white)
    print()
end

term.clear()
term.setCursorPos(1, 1)

term.setTextColor(colors.cyan)
print("================================")
print("   GEN'S Nuclear Control")
print("================================")

term.setTextColor(colors.white)
print("Version 0.0.2")
print()

local status = discovery.getSystemStatus()

printDevice("Fusion Reactor", status.fusionReactor)
printDevice("Monitor", status.monitor)
printDevice("Modem", status.modem)

term.setTextColor(colors.lightBlue)
print("All peripherals:")
term.setTextColor(colors.white)

local devices = discovery.scan()

if #devices == 0 then
    print("  None")
else
    for _, device in ipairs(devices) do
        print("  " .. device.name .. " -> " .. device.type)
    end
end