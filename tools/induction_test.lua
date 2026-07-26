local Induction =
    dofile("/api/induction.lua")

local Energy =
    dofile("/core/energy.lua")

local matrix = Induction.new()
local status = matrix:getStatus()

print("Connected : "
    .. tostring(status.connected))

print(
    "Stored    : "
    .. Energy.formatFE(status.energy)
)

print(
    "Capacity  : "
    .. Energy.formatFE(status.capacity)
)

print(
    "Input     : "
    .. Energy.formatFEPerTick(status.input)
)

print(
    "Output    : "
    .. Energy.formatFEPerTick(status.output)
)

print(
    "Net flow  : "
    .. Energy.formatFEPerTick(status.netFlow)
)

if status.percentage then
    print(
        "Filled    : "
        .. string.format(
            "%.2f %%",
            status.percentage * 100
        )
    )
	
	local p = peripheral.find("inductionPort") -- ou le type réel de ta Matrix

print(p.getEnergy())
print(p.getMaxEnergy())
print(p.getLastInput())
print(p.getLastOutput())

end