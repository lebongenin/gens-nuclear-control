--================================================--
-- GEN'S Nuclear Control
-- Version : 0.0.4
-- Application : Fusion API Test
--================================================--

local Fusion = dofile("/api/fusion.lua")

local reactor = Fusion.new()

term.clear()
term.setCursorPos(1, 1)

term.setTextColor(colors.cyan)
print("================================")
print("   GEN'S Nuclear Control")
print("================================")

term.setTextColor(colors.white)
print("Version 0.0.4")
print()

if not reactor:isOnline() then
    term.setTextColor(colors.red)
    print("Fusion Reactor: NOT FOUND")
    term.setTextColor(colors.white)
    return
end

local status = reactor:getStatus()

local function printBoolean(label, value)
    write(label .. ": ")

    if value == true then
        term.setTextColor(colors.lime)
        print("YES")
    elseif value == false then
        term.setTextColor(colors.red)
        print("NO")
    else
        term.setTextColor(colors.orange)
        print("UNKNOWN")
    end

    term.setTextColor(colors.white)
end

local function printValue(label, value, unit)
    write(label .. ": ")

    if value == nil then
        term.setTextColor(colors.red)
        print("UNAVAILABLE")
    else
        term.setTextColor(colors.lightGray)
        print(tostring(value) .. (unit or ""))
    end

    term.setTextColor(colors.white)
end

term.setTextColor(colors.lime)
print("Fusion Reactor: ONLINE")
term.setTextColor(colors.white)

print("Name: " .. tostring(status.name))
print("Type: " .. tostring(status.type))
print()

printBoolean("Formed", status.formed)
printBoolean("Ignited", status.ignited)

print()
printValue(
    "Injection Rate",
    status.injectionRate
)

printValue(
    "Case Temperature",
    status.caseTemperature,
    " K"
)

printValue(
    "Plasma Temperature",
    status.plasmaTemperature,
    " K"
)

printValue(
    "Ignition Temperature",
    status.ignitionTemperature,
    " K"
)

print()
printValue(
    "D-T Fuel",
    status.dtFuel
)

printValue(
    "D-T Fuel Capacity",
    status.dtFuelCapacity
)

printValue(
    "D-T Fuel Fill",
    status.dtFuelPercentage
)

print()
printValue(
    "Tritium",
    status.tritium
)

printValue(
    "Tritium Capacity",
    status.tritiumCapacity
)

printValue(
    "Tritium Fill",
    status.tritiumPercentage
)

print()
printValue(
    "Deuterium",
    status.deuterium
)

printValue(
    "Deuterium Capacity",
    status.deuteriumCapacity
)

printValue(
    "Deuterium Fill",
    status.deuteriumPercentage
)