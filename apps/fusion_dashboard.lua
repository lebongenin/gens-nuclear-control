local ui = dofile("/ui/widgets.lua")
local C  = dofile("/ui/colors.lua")

local monitor = peripheral.find("monitor")

if not monitor then
    error("No monitor found")
end

term.redirect(monitor)

monitor.setTextScale(0.5)

while true do

    ui.clear()

    ui.title("GEN'S Nuclear Control")

    ui.status(3, 6, "Fusion Reactor", true)

    ui.field(3, 8, "Injection Rate", 2)

    ui.field(3,10, "Generation", "19.8 MFE/t")

    ui.field(3,12, "Case Temp", "14.98 GK")

    ui.field(3,14, "Plasma Temp", "39.97 GK")

    ui.field(3,16, "Logic Mode", "DISABLED", C.warning)

    ui.footer(os.date("%H:%M:%S"))

    sleep(1)

end