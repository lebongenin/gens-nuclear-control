local reactor = peripheral.find("fusionReactorLogicAdapter")

if not reactor then
    error("Fusion Reactor introuvable")
end

local name = peripheral.getName(reactor)
local methods = peripheral.getMethods(name)

table.sort(methods)

print("Recherche des methodes d'energie :")
print()

for _, method in ipairs(methods) do
    local lower = string.lower(method)

    if lower:find("prod")
        or lower:find("energy")
        or lower:find("gener")
        or lower:find("output") then

        print(method)
    end
end

print()
print("Test direct de getProduction :")

if type(reactor.getProduction) ~= "function" then
    printError("getProduction inexistante")
else
    local ok, result = pcall(reactor.getProduction)

    print("Succes : " .. tostring(ok))
    print("Type   : " .. type(result))
    print("Valeur : " .. textutils.serialize(result))
end