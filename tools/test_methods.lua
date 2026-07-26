local reactor = peripheral.find("fusionReactorLogicAdapter")

if not reactor then
    error("Fusion Reactor introuvable")
end

print("Test de getProductionRate :")
print()

if type(reactor.getProductionRate) ~= "function" then
    printError("getProductionRate inexistante")
else
    local ok, result = pcall(reactor.getProductionRate)

    print("Succes : " .. tostring(ok))
    print("Type   : " .. type(result))
    print("Valeur : " .. textutils.serialize(result))
end

print()
print("Test de getPassiveGeneration :")
print()

if type(reactor.getPassiveGeneration) ~= "function" then
    printError("getPassiveGeneration inexistante")
else
    local ok, result = pcall(reactor.getPassiveGeneration)

    print("Succes : " .. tostring(ok))
    print("Type   : " .. type(result))
    print("Valeur : " .. textutils.serialize(result))
end