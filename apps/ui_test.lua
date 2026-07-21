local ui = dofile("/ui/widgets.lua")
local C  = dofile("/ui/colors.lua")

ui.clear()

ui.title("GEN'S Nuclear Control")

ui.status(3, 6, "Fusion Reactor", true)

ui.field(3, 8, "Injection Rate", 2)

ui.field(3,10, "Logic Mode", "DISABLED", C.warning)

ui.footer("v0.1.0")