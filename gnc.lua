--================================================--
-- GEN'S Nuclear Control
-- Installer / Updater
-- Version : 0.1.0
--================================================--

local VERSION = "0.1.0"

local BASE_URL =
"https://raw.githubusercontent.com/lebongenin/gens-nuclear-control/main/"

--------------------------------------------------
-- Files to download
--------------------------------------------------

local files = {
    "core/discovery.lua",
    "core/logger.lua",
    "core/inspector.lua",
	"core/energy.lua",

    "api/fusion.lua",

    "ui/colors.lua",
    "ui/widgets.lua",

    "apps/test.lua",
    "apps/logger_test.lua",
    "apps/fusion_test.lua",
    "apps/inspector.lua",
    "apps/fusion_dashboard.lua",
    "apps/test_methods.lua",
    "apps/ui_test.lua",

    "gnc.lua"
}

--------------------------------------------------
-- Header
--------------------------------------------------

local function header()

    term.clear()
    term.setCursorPos(1,1)

    term.setTextColor(colors.cyan)

    print("================================")
    print("   GEN'S Nuclear Control")
    print("================================")

    term.setTextColor(colors.white)

    print("Version "..VERSION)
    print()

end

--------------------------------------------------
-- Create directories
--------------------------------------------------

local function createDirectory(path)

    local dir = fs.getDir(path)

    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end

end

--------------------------------------------------
-- Download one file
--------------------------------------------------

local function download(remote, localPath)
    local url =
        BASE_URL
        .. remote
        .. "?v="
        .. tostring(os.epoch("utc"))

    createDirectory(localPath)

    local response, requestError = http.get(url)

    if not response then
        return false,
            "HTTP request failed: "
            .. tostring(requestError)
    end

    local responseCode = response.getResponseCode()
    local data = response.readAll()

    response.close()

    if responseCode ~= 200 then
        return false,
            "HTTP "
            .. tostring(responseCode)
            .. " - "
            .. remote
    end

    if not data or data == "" then
        return false, "Empty file"
    end

    local file = fs.open(localPath, "w")

    if not file then
        return false,
            "Cannot write file: "
            .. tostring(localPath)
    end

    file.write(data)
    file.close()

    if not fs.exists(localPath) then
        return false,
            "File missing after download"
    end

    return true
end

--------------------------------------------------
-- Update
--------------------------------------------------

local function update()

    header()

    print("Updating GNC...")
    print()

    local okCount = 0
    local failCount = 0

    for _,file in ipairs(files) do

        write("Downloading "..file.."... ")

        local ok,err = download(file,file)

        if ok then

            term.setTextColor(colors.lime)
            print("OK")

            okCount = okCount + 1

        else

            term.setTextColor(colors.red)
            print("FAILED")

            term.setTextColor(colors.lightGray)
            print("  "..err)

            failCount = failCount + 1

        end

        term.setTextColor(colors.white)

    end

    print()
    print("Updated : "..okCount)
    print("Failed  : "..failCount)

    print()

    if failCount == 0 then

        term.setTextColor(colors.lime)
        print("GNC is up to date!")

    else

        term.setTextColor(colors.orange)
        print("Update finished with errors.")

    end

    term.setTextColor(colors.white)

end

--------------------------------------------------
-- Commands
--------------------------------------------------

local args = {...}

if args[1] == "update" or args[1] == "install" then

    update()

elseif args[1] == "version" then

    print("GEN'S Nuclear Control "..VERSION)

else

    header()

    print("Usage :")
    print()

    print("gnc update")
    print("gnc install")
    print("gnc version")

end