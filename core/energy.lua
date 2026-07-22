--================================================--
-- GEN'S Nuclear Control
-- Version : 0.2.0
-- Module  : Energy and Units
--================================================--

local Energy = {}

--------------------------------------------------
-- Configuration
--------------------------------------------------

-- Mekanism uses 2.5 joules for 1 FE.
local JOULES_PER_FE = 2.5

--------------------------------------------------
-- Internal helpers
--------------------------------------------------

local function toNumber(value)
    value = tonumber(value)

    if not value then
        return nil
    end

    return value
end

local function formatScaled(value, units, decimals)
    value = toNumber(value)

    if not value then
        return "N/A"
    end

    decimals = decimals or 2

    local absoluteValue = math.abs(value)
    local selectedDivisor = 1
    local selectedUnit = units[1].suffix

    for _, unit in ipairs(units) do
        if absoluteValue >= unit.divisor then
            selectedDivisor = unit.divisor
            selectedUnit = unit.suffix
        end
    end

    local scaledValue = value / selectedDivisor

    return string.format(
        "%." .. tostring(decimals) .. "f %s",
        scaledValue,
        selectedUnit
    )
end

--------------------------------------------------
-- Energy conversion
--------------------------------------------------

function Energy.joulesToFE(value)
    value = toNumber(value)

    if not value then
        return nil
    end

    return value / JOULES_PER_FE
end

function Energy.feToJoules(value)
    value = toNumber(value)

    if not value then
        return nil
    end

    return value * JOULES_PER_FE
end

--------------------------------------------------
-- Energy formatting
--------------------------------------------------

function Energy.formatFE(value, decimals)
    return formatScaled(
        value,
        {
            { divisor = 1,             suffix = "FE" },
            { divisor = 1000,          suffix = "kFE" },
            { divisor = 1000000,       suffix = "MFE" },
            { divisor = 1000000000,    suffix = "GFE" },
            { divisor = 1000000000000, suffix = "TFE" }
        },
        decimals
    )
end

function Energy.formatFEPerTick(value, decimals)
    local formatted = Energy.formatFE(value, decimals)

    if formatted == "N/A" then
        return formatted
    end

    return formatted .. "/t"
end

--------------------------------------------------
-- Temperature formatting
--------------------------------------------------

function Energy.formatKelvin(value, decimals)
    return formatScaled(
        value,
        {
            { divisor = 1,             suffix = "K" },
            { divisor = 1000,          suffix = "kK" },
            { divisor = 1000000,       suffix = "MK" },
            { divisor = 1000000000,    suffix = "GK" },
            { divisor = 1000000000000, suffix = "TK" }
        },
        decimals
    )
end

--------------------------------------------------
-- Percentage formatting
--------------------------------------------------

function Energy.formatPercentage(value, decimals)
    value = tonumber(value)

    if not value then
        return "N/A"
    end

    decimals = decimals or 2

    return string.format(
        "%." .. tostring(decimals) .. "f %%",
        value * 100
    )
end

return Energy