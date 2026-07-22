local reactor = peripheral.find("fusionReactorLogicAdapter")

if not reactor then
    error("Fusion Reactor non trouvé")
end

local methods = peripheral.getMethods(peripheral.getName(reactor))

table.sort(methods)

for _, method in ipairs(methods) do
    print(method)
end