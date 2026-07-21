local discovery = require("core.discovery")

term.clear()
term.setCursorPos(1, 1)

print("=== GEN'S Nuclear Control ===")
print("Discovery test")
print()

local devices = discovery.scan()

if #devices == 0 then
    print("No peripheral detected.")
    return
end

for _, device in ipairs(devices) do
    print(device.name .. " -> " .. device.type)
end
