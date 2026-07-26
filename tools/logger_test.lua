-- GEN'S Nuclear Control
-- Logger test
-- Version 0.0.3

local logger = dofile("/core/logger.lua")
local discovery = dofile("/core/discovery.lua")

term.clear()
term.setCursorPos(1, 1)

term.setTextColor(colors.cyan)
print("================================")
print("   GEN'S Nuclear Control")
print("================================")

term.setTextColor(colors.white)
print("Version 0.0.3")
print()

logger.clear()
logger.info("GNC logger test started")

local status = discovery.getSystemStatus()

local function logDevice(label, device)
    if device.connected then
        logger.info(
            label
                .. " detected: "
                .. tostring(device.name)
                .. " ("
                .. tostring(device.type)
                .. ")"
        )

        term.setTextColor(colors.lime)
        print(label .. ": ONLINE")
    else
        logger.warning(label .. " not detected")

        term.setTextColor(colors.red)
        print(label .. ": NOT FOUND")
    end

    term.setTextColor(colors.white)
end

logDevice("Fusion Reactor", status.fusionReactor)
logDevice("Monitor", status.monitor)
logDevice("Modem", status.modem)

logger.info("Logger test completed")

print()
term.setTextColor(colors.lightBlue)
print("Log file:")
term.setTextColor(colors.white)
print(logger.getFilePath())

print()
print("Use:")
term.setTextColor(colors.yellow)
print("edit logs/latest.log")
term.setTextColor(colors.white)