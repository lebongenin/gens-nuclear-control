--================================================--
-- GEN'S Nuclear Control
-- Version : 0.1.0
-- Module  : UI Widgets
--================================================--

local C = dofile("/ui/colors.lua")

local ui = {}

--------------------------------------------------
-- Terminal
--------------------------------------------------

function ui.clear()

    term.setBackgroundColor(C.background)
    term.setTextColor(C.text)

    term.clear()
    term.setCursorPos(1,1)

end

--------------------------------------------------
-- Centered text
--------------------------------------------------

function ui.center(y,text,color)

    local w,h = term.getSize()

    term.setCursorPos(
        math.floor((w-#text)/2)+1,
        y
    )

    if color then
        term.setTextColor(color)
    else
        term.setTextColor(C.text)
    end

    write(text)

end

--------------------------------------------------
-- Separator
--------------------------------------------------

function ui.separator(y)

    local w,h = term.getSize()

    term.setCursorPos(1,y)

    term.setTextColor(C.border)

    write(string.rep("=",w))

end

--------------------------------------------------
-- Title
--------------------------------------------------

function ui.title(text)

    ui.separator(1)

    ui.center(
        2,
        text,
        C.header
    )

    ui.separator(3)

end

--------------------------------------------------
-- Footer
--------------------------------------------------

function ui.footer(leftText)

    local w, h = term.getSize()

    ui.separator(h - 1)

    term.setCursorPos(1, h)
    term.setTextColor(C.subtitle)
    write(leftText)

    local version = "GNC v0.1.0"

    term.setCursorPos(w - #version + 1, h)
    write(version)

end

--------------------------------------------------
-- Label
--------------------------------------------------

function ui.label(x,y,text)

    term.setCursorPos(x,y)
    term.setTextColor(C.subtitle)

    write(text)

end

--------------------------------------------------
-- Value
--------------------------------------------------

function ui.value(x,y,text,color)

    term.setCursorPos(x,y)

    if color then
        term.setTextColor(color)
    else
        term.setTextColor(C.text)
    end

    write(tostring(text))

end

--------------------------------------------------
-- Field
--------------------------------------------------

function ui.field(x, y, label, value, color)

    local valueColumn = 30

    ui.label(x, y, label)
    ui.value(valueColumn, y, value, color)

end

--------------------------------------------------
-- Status
--------------------------------------------------

function ui.status(x, y, label, online)

    ui.label(x, y, label)

    local valueColumn = 30

    term.setCursorPos(valueColumn, y)

    if online then

        term.setTextColor(C.online)
        write("● ")

        term.setTextColor(C.text)
        write("ONLINE")

    else

        term.setTextColor(C.offline)
        write("● ")

        term.setTextColor(C.text)
        write("OFFLINE")

    end

end

return ui