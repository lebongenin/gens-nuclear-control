-- GEN'S Nuclear Control
-- Installer and updater

local VERSION = "0.1.0"
local BASE_URL =
    "https://raw.githubusercontent.com/lebongenin/gens-nuclear-control/main/"

local files = {

    -- Core
    "core/discovery.lua",
    "core/logger.lua",
    "core/inspector.lua",

    -- API
    "api/fusion.lua",

    -- UI
    "ui/colors.lua",
    "ui/widgets.lua",

    -- Apps
    "apps/test.lua",
    "apps/logger_test.lua",
    "apps/fusion_test.lua",
    "apps/inspector.lua",
    "apps/fusion_dashboard.lua",

    -- Main
    "gnc.lua"
}

local function printHeader()
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.cyan)

    print("================================")
    print("   GEN'S Nuclear Control")
    print("================================")

    term.setTextColor(colors.white)
    print("Version " .. VERSION)
    print()
end

local function ensureParentDirectory(path)
    local directory = fs.getDir(path)

    if directory ~= "" and not fs.exists(directory) then
        fs.makeDir(directory)
    end
end

local function downloadFile(remotePath, destination)
    local cacheBuster = tostring(os.epoch("utc"))
    local url = BASE_URL .. remotePath .. "?v=" .. cacheBuster
    local temporaryPath = destination .. ".tmp"

    ensureParentDirectory(destination)

    if fs.exists(temporaryPath) then
        fs.delete(temporaryPath)
    end

    local response, errorMessage = http.get(url)

    if not response then
        return false, errorMessage or "HTTP connection failed"
    end

    local contents = response.readAll()
    response.close()

    if not contents or contents == "" then
        return false, "Downloaded file is empty"
    end

    local file = fs.open(temporaryPath, "w")

    if not file then
        return false, "Cannot create temporary file"
    end

    file.write(contents)
    file.close()

    if fs.exists(destination) then
        fs.delete(destination)
    end

    fs.move(temporaryPath, destination)

    return true
end

local function update()
    printHeader()
    print("Updating GNC...")
    print()

    local successful = 0
    local failed = 0

    for _, entry in ipairs(files) do
        write("Downloading " .. entry.remote .. "... ")

        local ok, errorMessage =
            downloadFile(entry.remote, entry.destination)

        if ok then
            term.setTextColor(colors.lime)
            print("OK")
            successful = successful + 1
        else
            term.setTextColor(colors.red)
            print("FAILED")
            term.setTextColor(colors.lightGray)
            print("  " .. tostring(errorMessage))
            failed = failed + 1
        end

        term.setTextColor(colors.white)
    end

    print()
    print("Updated: " .. successful)
    print("Failed:  " .. failed)

    if failed == 0 then
        term.setTextColor(colors.lime)
        print()
        print("GNC is up to date!")
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.orange)
        print()
        print("Update completed with errors.")
        term.setTextColor(colors.white)
    end
end

local arguments = {...}
local command = arguments[1]

if command == "update" or command == "install" then
    update()
elseif command == "version" then
    print("GEN'S Nuclear Control " .. VERSION)
else
    printHeader()
    print("Usage:")
    print("  gnc update")
    print("  gnc install")
    print("  gnc version")
end