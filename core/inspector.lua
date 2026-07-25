--================================================--
-- GEN'S Nuclear Control
-- Version : 0.0.5
-- Module  : Inspector
--================================================--

local inspector = {}

local DEFAULT_MAX_DEPTH = 5

local function sortKeys(tbl)
    local keys = {}

    for key in pairs(tbl) do
        keys[#keys + 1] = key
    end

    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)

    return keys
end

local function formatPrimitive(value)
    local valueType = type(value)

    if valueType == "string" then
        return '"' .. value .. '"'
    end

    return tostring(value)
end

local function inspectValue(
    value,
    depth,
    maxDepth,
    visited,
    output,
    name
)
    local valueType = type(value)
    local indent = string.rep("  ", depth)
    local prefix = indent

    if name ~= nil then
        prefix = prefix .. tostring(name) .. " = "
    end

    if valueType ~= "table" then
        output[#output + 1] =
            prefix .. formatPrimitive(value)
        return
    end

    if visited[value] then
        output[#output + 1] =
            prefix .. "<circular reference>"
        return
    end

    if depth >= maxDepth then
        output[#output + 1] =
            prefix .. "<maximum depth reached>"
        return
    end

    visited[value] = true
    output[#output + 1] = prefix .. "{"

    local keys = sortKeys(value)

    if #keys == 0 then
        output[#output + 1] =
            string.rep("  ", depth + 1) .. "<empty>"
    else
        for _, key in ipairs(keys) do
            inspectValue(
                value[key],
                depth + 1,
                maxDepth,
                visited,
                output,
                "[" .. tostring(key) .. "]"
            )
        end
    end

    output[#output + 1] = indent .. "}"
    visited[value] = nil
end

function inspector.toLines(value, maxDepth)
    local output = {}

    inspectValue(
        value,
        0,
        maxDepth or DEFAULT_MAX_DEPTH,
        {},
        output,
        nil
    )

    return output
end

function inspector.toString(value, maxDepth)
    return table.concat(
        inspector.toLines(value, maxDepth),
        "\n"
    )
end

function inspector.print(value, maxDepth)
    local lines = inspector.toLines(value, maxDepth)

    for _, line in ipairs(lines) do
        print(line)
    end
end

function inspector.writeToFile(path, value, maxDepth)
    local parent = fs.getDir(path)

    if parent ~= "" and not fs.exists(parent) then
        fs.makeDir(parent)
    end

    local file = fs.open(path, "w")

    if not file then
        return false, "Unable to open " .. tostring(path)
    end

    file.write(
        inspector.toString(value, maxDepth)
    )

    file.close()

    return true
end

return inspector