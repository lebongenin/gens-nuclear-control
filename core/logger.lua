-- GEN'S Nuclear Control
-- Logger
-- Version 0.0.3

local logger = {}

local LOG_DIRECTORY = "/logs"
local LOG_FILE = LOG_DIRECTORY .. "/latest.log"

local LEVELS = {
    INFO = "INFO",
    WARNING = "WARNING",
    ERROR = "ERROR",
    DEBUG = "DEBUG"
}

local function ensureLogDirectory()
    if not fs.exists(LOG_DIRECTORY) then
        fs.makeDir(LOG_DIRECTORY)
    end
end

local function getTime()
    local time = os.date("*t")

    if not time then
        return "00:00:00"
    end

    return string.format(
        "%02d:%02d:%02d",
        time.hour or 0,
        time.min or 0,
        time.sec or 0
    )
end

local function writeLog(level, message)
    ensureLogDirectory()

    local line = string.format(
        "%s [%s] %s",
        getTime(),
        tostring(level),
        tostring(message)
    )

    local file = fs.open(LOG_FILE, "a")

    if not file then
        return false, "Unable to open log file"
    end

    file.writeLine(line)
    file.close()

    return true
end

function logger.clear()
    ensureLogDirectory()

    if fs.exists(LOG_FILE) then
        fs.delete(LOG_FILE)
    end

    return true
end

function logger.log(level, message)
    return writeLog(level, message)
end

function logger.info(message)
    return writeLog(LEVELS.INFO, message)
end

function logger.warning(message)
    return writeLog(LEVELS.WARNING, message)
end

function logger.error(message)
    return writeLog(LEVELS.ERROR, message)
end

function logger.debug(message)
    return writeLog(LEVELS.DEBUG, message)
end

function logger.getFilePath()
    return LOG_FILE
end

return logger