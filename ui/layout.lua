--================================================--
-- GEN'S Nuclear Control
-- UI Module : Layout
-- Version : 0.1.0
--================================================--

local Layout = {}

Layout.theme = {
    title = colors.cyan,
    safe = colors.lime,
    warning = colors.yellow,
    critical = colors.orange,
    emergency = colors.red,
    muted = colors.lightGray,
    border = colors.gray,
    panel = colors.black
}

--------------------------------------------------
-- Color palette
--------------------------------------------------

Layout.colors = {
    background = colors.black,
    panel = colors.gray,
    panelDark = colors.black,
    border = colors.lightGray,

    title = colors.cyan,
    text = colors.white,
    muted = colors.lightGray,

    safe = colors.lime,
    warning = colors.yellow,
    critical = colors.orange,
    emergency = colors.red,

    barEmpty = colors.gray,
    barFilled = colors.lime
}

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function clamp(
    value,
    minimum,
    maximum
)
    if type(value) ~= "number" then
        return minimum
    end

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function fill(
    x,
    y,
    width,
    character
)
    if width <= 0 then
        return
    end

    term.setCursorPos(x, y)
    term.write(
        string.rep(
            character or " ",
            width
        )
    )
end

local function crop(text, width)
    text = tostring(text or "")

    if width <= 0 then
        return ""
    end

    if #text <= width then
        return text
    end

    if width <= 3 then
        return string.sub(
            text,
            1,
            width
        )
    end

    return string.sub(
        text,
        1,
        width - 3
    ) .. "..."
end

local function safetyColor(level)
    if level == "safe" then
        return Layout.colors.safe
    elseif level == "warning" then
        return Layout.colors.warning
    elseif level == "critical" then
        return Layout.colors.critical
    elseif level == "emergency" then
        return Layout.colors.emergency
    end

    return Layout.colors.muted
end

--------------------------------------------------
-- Screen
--------------------------------------------------

function Layout.getSize()
    return term.getSize()
end

function Layout.clear(
    backgroundColor
)
    term.setBackgroundColor(
        backgroundColor
        or Layout.colors.background
    )

    term.setTextColor(
        Layout.colors.text
    )

    term.clear()
    term.setCursorPos(1, 1)
end

function Layout.writeAt(
    x,
    y,
    text,
    textColor,
    backgroundColor,
    maxWidth
)
    local width, height =
        term.getSize()

    if x < 1 or y < 1
        or x > width
        or y > height then
        return
    end

    if maxWidth then
        text = crop(
            text,
            math.min(
                maxWidth,
                width - x + 1
            )
        )
    else
        text = crop(
            text,
            width - x + 1
        )
    end

    term.setCursorPos(x, y)

    term.setTextColor(
        textColor
        or Layout.colors.text
    )

    term.setBackgroundColor(
        backgroundColor
        or Layout.colors.background
    )

    term.write(text)
end

function Layout.centerText(
    y,
    text,
    textColor,
    backgroundColor
)
    local width =
        select(1, term.getSize())

    text = crop(text, width)

    local x = math.floor(
        (width - #text) / 2
    ) + 1

    Layout.writeAt(
        x,
        y,
        text,
        textColor,
        backgroundColor
    )
end

--------------------------------------------------
-- Boxes and panels
--------------------------------------------------

function Layout.box(
    x,
    y,
    width,
    height,
    options
)
    options = options or {}

    if width < 2 or height < 2 then
        return
    end

    local borderColor =
        options.borderColor
        or Layout.colors.border

    local backgroundColor =
        options.backgroundColor
        or Layout.colors.panelDark

    term.setBackgroundColor(
        backgroundColor
    )

    term.setTextColor(
        borderColor
    )

    fill(x, y, width, "-")
    fill(
        x,
        y + height - 1,
        width,
        "-"
    )

    for row = y + 1,
        y + height - 2 do
        Layout.writeAt(
            x,
            row,
            "|",
            borderColor,
            backgroundColor
        )

        Layout.writeAt(
            x + width - 1,
            row,
            "|",
            borderColor,
            backgroundColor
        )

        term.setBackgroundColor(
            backgroundColor
        )

        fill(
            x + 1,
            row,
            width - 2,
            " "
        )
    end

    Layout.writeAt(
        x,
        y,
        "+",
        borderColor,
        backgroundColor
    )

    Layout.writeAt(
        x + width - 1,
        y,
        "+",
        borderColor,
        backgroundColor
    )

    Layout.writeAt(
        x,
        y + height - 1,
        "+",
        borderColor,
        backgroundColor
    )

    Layout.writeAt(
        x + width - 1,
        y + height - 1,
        "+",
        borderColor,
        backgroundColor
    )

    if options.title then
        local title =
            " " .. tostring(
                options.title
            ) .. " "

        Layout.writeAt(
            x + 2,
            y,
            title,
            options.titleColor
                or Layout.colors.title,
            backgroundColor,
            width - 4
        )
    end
end

function Layout.panelContent(
    x,
    y,
    width,
    height
)
    return {
        x = x + 2,
        y = y + 1,
        width = math.max(
            width - 4,
            0
        ),
        height = math.max(
            height - 2,
            0
        )
    }
end

--------------------------------------------------
-- Header and footer
--------------------------------------------------

function Layout.header(
    title,
    subtitle
)
    local width =
        select(1, term.getSize())

    term.setBackgroundColor(
        Layout.colors.background
    )

    term.setTextColor(
        Layout.colors.title
    )

    fill(1, 1, width, "=")

    Layout.centerText(
        2,
        title,
        Layout.colors.title
    )

    if subtitle then
        Layout.centerText(
            3,
            subtitle,
            Layout.colors.muted
        )
    end

    fill(
        1,
        subtitle and 4 or 3,
        width,
        "="
    )

    return subtitle and 5 or 4
end

function Layout.footer(text)
    local width, height =
        term.getSize()

    term.setBackgroundColor(
        Layout.colors.background
    )

    term.setTextColor(
        Layout.colors.muted
    )

    fill(1, height, width, " ")

    Layout.writeAt(
        1,
        height,
        crop(text, width),
        Layout.colors.muted
    )
end

--------------------------------------------------
-- Labels and values
--------------------------------------------------

function Layout.labelValue(
    x,
    y,
    width,
    label,
    value,
    options
)
    options = options or {}

    if width <= 0 then
        return
    end

    local separator =
        options.separator or ": "

    local valueText =
        tostring(value or "N/A")

    local labelWidth =
        width
        - #separator
        - #valueText

    if labelWidth < 1 then
        Layout.writeAt(
            x,
            y,
            crop(valueText, width),
            options.valueColor
                or Layout.colors.text,
            options.backgroundColor,
            width
        )

        return
    end

    local labelText =
        crop(label, labelWidth)

    Layout.writeAt(
        x,
        y,
        labelText,
        options.labelColor
            or Layout.colors.muted,
        options.backgroundColor,
        labelWidth
    )

    Layout.writeAt(
        x + labelWidth,
        y,
        separator,
        options.separatorColor
            or Layout.colors.muted,
        options.backgroundColor
    )

    Layout.writeAt(
        x + labelWidth
            + #separator,
        y,
        valueText,
        options.valueColor
            or Layout.colors.text,
        options.backgroundColor,
        #valueText
    )
end

--------------------------------------------------
-- Progress bars
--------------------------------------------------

function Layout.progressBar(
    x,
    y,
    width,
    percentage,
    options
)
    options = options or {}

    percentage = clamp(
        percentage or 0,
        0,
        1
    )

    if width < 3 then
        return
    end

    local innerWidth = width - 2

    local filled = math.floor(
        innerWidth * percentage
        + 0.5
    )

    local filledColor =
        options.filledColor
        or Layout.colors.barFilled

    if options.dynamicColor then
        if percentage >= 0.95 then
            filledColor =
                Layout.colors.emergency
        elseif percentage >= 0.80 then
            filledColor =
                Layout.colors.warning
        else
            filledColor =
                Layout.colors.safe
        end
    end

    Layout.writeAt(
        x,
        y,
        "[",
        Layout.colors.border,
        options.backgroundColor
    )

    term.setCursorPos(x + 1, y)
    term.setBackgroundColor(
        options.backgroundColor
        or Layout.colors.background
    )

    term.setTextColor(filledColor)

    term.write(
        string.rep("#", filled)
    )

    term.setTextColor(
        options.emptyColor
        or Layout.colors.barEmpty
    )

    term.write(
        string.rep(
            "-",
            innerWidth - filled
        )
    )

    Layout.writeAt(
        x + width - 1,
        y,
        "]",
        Layout.colors.border,
        options.backgroundColor
    )
end

--------------------------------------------------
-- Status
--------------------------------------------------

function Layout.statusBadge(
    x,
    y,
    status,
    options
)
    options = options or {}

    local normalized =
        string.lower(
            tostring(status or "unknown")
        )

    local text =
        string.upper(normalized)

    local color =
        safetyColor(normalized)

    if normalized == "online"
        or normalized == "active"
        or normalized == "ready" then
        color = Layout.colors.safe
    elseif normalized == "offline"
        or normalized == "error" then
        color = Layout.colors.emergency
    elseif normalized == "idle" then
        color = Layout.colors.warning
    end

    Layout.writeAt(
        x,
        y,
        "[" .. text .. "]",
        color,
        options.backgroundColor
    )
end

function Layout.safetyColor(level)
    return safetyColor(level)
end

--------------------------------------------------
-- Responsive grid
--------------------------------------------------

function Layout.grid(
    x,
    y,
    width,
    height,
    columns,
    rows,
    gap
)
    columns = math.max(
        math.floor(columns or 1),
        1
    )

    rows = math.max(
        math.floor(rows or 1),
        1
    )

    gap = math.max(
        math.floor(gap or 1),
        0
    )

    local cellWidth =
        math.floor(
            (
                width
                - gap * (columns - 1)
            ) / columns
        )

    local cellHeight =
        math.floor(
            (
                height
                - gap * (rows - 1)
            ) / rows
        )

    local cells = {}

    for row = 1, rows do
        for column = 1, columns do
            cells[#cells + 1] = {
                x = x
                    + (column - 1)
                    * (cellWidth + gap),

                y = y
                    + (row - 1)
                    * (cellHeight + gap),

                width = cellWidth,
                height = cellHeight,

                row = row,
                column = column
            }
        end
    end

    return cells
end

function Layout.dashboardGrid(
    startY,
    panelCount
)
    local width, height =
        term.getSize()

    local footerHeight = 1
    local availableHeight =
        height
        - startY
        - footerHeight
        + 1

    local columns
    local rows

    if width >= 70 then
        columns = 3
    elseif width >= 42 then
        columns = 2
    else
        columns = 1
    end

    rows = math.ceil(
        panelCount / columns
    )

    return Layout.grid(
        1,
        startY,
        width,
        availableHeight,
        columns,
        rows,
        1
    )
end

--------------------------------------------------
-- Formatting
--------------------------------------------------

function Layout.formatNumber(
    value,
    decimals
)
    if type(value) ~= "number"
        or value ~= value
        or value == math.huge
        or value == -math.huge then
        return "N/A"
    end

    decimals = decimals or 1

    local absolute =
        math.abs(value)

    if absolute >= 1e15 then
        return string.format(
            "%."
            .. decimals
            .. "fP",
            value / 1e15
        )
    elseif absolute >= 1e12 then
        return string.format(
            "%."
            .. decimals
            .. "fT",
            value / 1e12
        )
    elseif absolute >= 1e9 then
        return string.format(
            "%."
            .. decimals
            .. "fG",
            value / 1e9
        )
    elseif absolute >= 1e6 then
        return string.format(
            "%."
            .. decimals
            .. "fM",
            value / 1e6
        )
    elseif absolute >= 1e3 then
        return string.format(
            "%."
            .. decimals
            .. "fk",
            value / 1e3
        )
    end

    return string.format(
        "%."
        .. decimals
        .. "f",
        value
    )
end

function Layout.formatPercent(
    value,
    decimals
)
    if type(value) ~= "number"
        or value ~= value then
        return "N/A"
    end

    return string.format(
        "%."
        .. tostring(decimals or 1)
        .. "f%%",
        value * 100
    )
end

function Layout.crop(text, width)
    return crop(text, width)
end

function Layout.truncate(text, width)
    return crop(text, width)
end

--------------------------------------------------
-- Panel
--------------------------------------------------

function Layout.panel(
    x,
    y,
    width,
    height,
    title,
    borderColor,
    backgroundColor
)
    x = tonumber(x)
    y = tonumber(y)
    width = tonumber(width)
    height = tonumber(height)

    if not x
        or not y
        or not width
        or not height then
        return false
    end

    width = math.floor(width)
    height = math.floor(height)

    if width < 2 or height < 2 then
        return false
    end

    borderColor =
        borderColor
        or colors.gray

    backgroundColor =
        backgroundColor
        or colors.black

    local previousBackground =
        term.getBackgroundColor()

    local previousText =
        term.getTextColor()

    -- Fill the complete panel background. The old call passed `height` as
    -- fill's character argument, which wrote strings such as "121212..."
    -- beyond the panel width and left stray digits at grid junctions.
    term.setBackgroundColor(backgroundColor)

    for row = y, y + height - 1 do
        fill(
            x,
            row,
            width,
            " "
        )
    end

    term.setBackgroundColor(borderColor)

    term.setCursorPos(x, y)
    term.write(string.rep(" ", width))

    term.setCursorPos(
        x,
        y + height - 1
    )
    term.write(string.rep(" ", width))

    for row = y + 1, y + height - 2 do
        term.setCursorPos(x, row)
        term.write(" ")

        term.setCursorPos(
            x + width - 1,
            row
        )
        term.write(" ")
    end

    if type(title) == "string"
        and title ~= "" then

        local titleText =
            " " .. title .. " "

        local maxTitleWidth =
            math.max(width - 4, 1)

        titleText =
            Layout.crop(
                titleText,
                maxTitleWidth
            )

        term.setBackgroundColor(borderColor)
        term.setTextColor(colors.white)

        term.setCursorPos(
            x + 2,
            y
        )

        term.write(titleText)
    end

    term.setBackgroundColor(
        previousBackground
    )

    term.setTextColor(
        previousText
    )

    return true
end

return Layout
