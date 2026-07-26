--================================================--
-- GEN'S Nuclear Control
-- API Module : Applied Energistics 2
-- Version : 0.1.0
--================================================--

local SafeCall = dofile("/core/safe_call.lua")

local AE2 = {}
AE2.__index = AE2

local PERIPHERAL_TYPE = "me_bridge"

--------------------------------------------------
-- Internal helpers
--------------------------------------------------

local function readNumber(
    device,
    errors,
    methodName,
    fallback,
    ...
)
    local value, err = SafeCall.getNumber(
        device,
        methodName,
        fallback,
        ...
    )

    SafeCall.addError(errors, methodName, err)

    return value
end

local function readBoolean(
    device,
    errors,
    methodName,
    fallback,
    ...
)
    local value, err = SafeCall.getBoolean(
        device,
        methodName,
        fallback,
        ...
    )

    SafeCall.addError(errors, methodName, err)

    return value
end

local function readString(
    device,
    errors,
    methodName,
    fallback,
    ...
)
    local value, err = SafeCall.getString(
        device,
        methodName,
        fallback,
        ...
    )

    SafeCall.addError(errors, methodName, err)

    return value
end

local function readTable(
    device,
    errors,
    methodName,
    fallback,
    ...
)
    local value, err = SafeCall.getTable(
        device,
        methodName,
        fallback,
        ...
    )

    SafeCall.addError(errors, methodName, err)

    return value
end

local function safeCount(value)
    if type(value) ~= "table" then
        return 0
    end

    return #value
end

local function normalizeText(value, fallback)
    if type(value) == "string" and value ~= "" then
        return value
    end

    return fallback
end

local function normalizeCount(value)
    if not SafeCall.isFiniteNumber(value) then
        return 0
    end

    return math.max(value, 0)
end

local function yieldExecution()
    os.queueEvent("gnc_ae2_yield")
    os.pullEvent("gnc_ae2_yield")
end

--------------------------------------------------
-- Item normalization
--------------------------------------------------

local function normalizeItem(item)
    if type(item) ~= "table" then
        return {
            name = nil,
            displayName = "Unknown item",
            count = 0,
            maxStackSize = 0,
            isCraftable = false,
            fingerprint = nil
        }
    end

    return {
        name = normalizeText(item.name, nil),

        displayName = normalizeText(
            item.displayName,
            item.name or "Unknown item"
        ),

        count = normalizeCount(item.count),

        maxStackSize = normalizeCount(
            item.maxStackSize
        ),

        isCraftable =
            type(item.isCraftable) == "boolean"
            and item.isCraftable
            or false,

        fingerprint = item.fingerprint,

        tags =
            type(item.tags) == "table"
            and item.tags
            or {},

        components =
            type(item.components) == "table"
            and item.components
            or {}
    }
end

local function normalizeItems(items)
    local result = {}

    if type(items) ~= "table" then
        return result
    end

    for index, item in ipairs(items) do
        result[index] = normalizeItem(item)

        if index % 100 == 0 then
            yieldExecution()
        end
    end

    return result
end

--------------------------------------------------
-- Cell normalization
--------------------------------------------------

local function normalizeCell(cell)
    if type(cell) ~= "table" then
        return nil
    end

    local bytes = normalizeCount(cell.bytes)
    local usedBytes = normalizeCount(cell.usedBytes)

    return {
        type = normalizeText(cell.type, "unknown"),

        itemName =
            type(cell.item) == "table"
            and normalizeText(cell.item.name, nil)
            or nil,

        bytes = bytes,
        usedBytes = usedBytes,

        availableBytes = math.max(
            bytes - usedBytes,
            0
        ),

        percentage = SafeCall.calculatePercentage(
            usedBytes,
            bytes,
            0
        ),

        totalTypes = normalizeCount(
            cell.totalTypes
        ),

        bytesPerType = normalizeCount(
            cell.bytesPerType
        ),

        fuzzyMode = normalizeText(
            cell.fuzzyMode,
            "UNKNOWN"
        )
    }
end

local function normalizeCells(cells)
    local result = {}

    if type(cells) ~= "table" then
        return result
    end

    for _, cell in ipairs(cells) do
        local normalized = normalizeCell(cell)

        if normalized then
            result[#result + 1] = normalized
        end
    end

    return result
end

--------------------------------------------------
-- Drive normalization
--------------------------------------------------

local function normalizeDrive(drive)
    if type(drive) ~= "table" then
        return nil
    end

    local position = drive.position

    if type(position) ~= "table" then
        position = {}
    end

    local totalBytes = normalizeCount(
        drive.totalBytes
    )

    local usedBytes = normalizeCount(
        drive.usedBytes
    )

    return {
        name = normalizeText(
            drive.name,
            "ME Drive"
        ),

        priority = SafeCall.number(
            drive.priority,
            0
        ),

        position = {
            x = SafeCall.number(position.x, 0),
            y = SafeCall.number(position.y, 0),
            z = SafeCall.number(position.z, 0)
        },

        totalBytes = totalBytes,
        usedBytes = usedBytes,

        percentage = SafeCall.calculatePercentage(
            usedBytes,
            totalBytes,
            0
        ),

        cells = normalizeCells(drive.cells),

        cellCount = safeCount(drive.cells)
    }
end

local function normalizeDrives(drives)
    local result = {}

    if type(drives) ~= "table" then
        return result
    end

    for _, drive in ipairs(drives) do
        local normalized = normalizeDrive(drive)

        if normalized then
            result[#result + 1] = normalized
        end
    end

    return result
end

--------------------------------------------------
-- Crafting CPU normalization
--------------------------------------------------

local function normalizeCraftingCPU(cpu)
    if type(cpu) ~= "table" then
        return nil
    end

    return {
        name = normalizeText(
            cpu.name,
            "Unnamed"
        ),

        storage = normalizeCount(
            cpu.storage
        ),

        coProcessors = normalizeCount(
            cpu.coProcessors
        ),

        isBusy =
            type(cpu.isBusy) == "boolean"
            and cpu.isBusy
            or false,

        selectionMode = normalizeText(
            cpu.selectionMode,
            "ANY"
        )
    }
end

local function normalizeCraftingCPUs(cpus)
    local result = {}

    if type(cpus) ~= "table" then
        return result
    end

    for _, cpu in ipairs(cpus) do
        local normalized =
            normalizeCraftingCPU(cpu)

        if normalized then
            result[#result + 1] = normalized
        end
    end

    return result
end

--------------------------------------------------
-- Crafting task normalization
--------------------------------------------------

local function normalizeCraftingTask(task)
    if type(task) ~= "table" then
        return nil
    end

    local output = task.output

    if type(output) ~= "table" then
        output = task.item
    end

    return {
        id =
            task.id
            or task.taskId
            or task.craftingId,

        cpu = normalizeText(
            task.cpuName or task.cpu,
            nil
        ),

        output = normalizeItem(output),

        progress = SafeCall.number(
            task.progress,
            nil
        ),

        remaining = SafeCall.number(
            task.remaining,
            nil
        ),

        raw = task
    }
end

local function normalizeCraftingTasks(tasks)
    local result = {}

    if type(tasks) ~= "table" then
        return result
    end

    for _, task in ipairs(tasks) do
        local normalized =
            normalizeCraftingTask(task)

        if normalized then
            result[#result + 1] = normalized
        end
    end

    return result
end

--------------------------------------------------
-- Storage structure
--------------------------------------------------

local function buildStorage(
    used,
    total,
    available
)
    used = normalizeCount(used)
    total = normalizeCount(total)

    if not SafeCall.isFiniteNumber(available) then
        available = math.max(
            total - used,
            0
        )
    else
        available = math.max(available, 0)
    end

    return {
        used = used,
        total = total,
        available = available,

        percentage = SafeCall.calculatePercentage(
            used,
            total,
            0
        )
    }
end

--------------------------------------------------
-- Safety evaluation
--------------------------------------------------

local function evaluateSafety(state)
    local level = "safe"
    local warnings = {}

    local priorities = {
        safe = 1,
        warning = 2,
        critical = 3,
        emergency = 4
    }

    local function raise(newLevel, message)
        warnings[#warnings + 1] = message

        if priorities[newLevel] > priorities[level] then
            level = newLevel
        end
    end

    if not state.connected then
        raise("emergency", "ME Bridge disconnected")

        return {
            level = level,
            safe = false,
            warnings = warnings
        }
    end

    if not state.online then
        raise("critical", "AE2 network is offline")
    end

    if not state.networkConnected then
        raise(
            "critical",
            "ME Bridge is not connected to the network"
        )
    end

    if state.itemStorage.percentage >= 0.98 then
        raise(
            "critical",
            "AE2 item storage almost full"
        )
    elseif state.itemStorage.percentage >= 0.90 then
        raise(
            "warning",
            "AE2 item storage is filling"
        )
    end

    if state.energy.percentage <= 0.05 then
        raise(
            "critical",
            "AE2 energy buffer nearly empty"
        )
    elseif state.energy.percentage <= 0.20 then
        raise(
            "warning",
            "AE2 energy buffer is low"
        )
    end

    if state.energy.averageInput
        < state.energy.usage then
        raise(
            "warning",
            "AE2 network consumes more energy than it receives"
        )
    end

    return {
        level = level,
        safe = level == "safe",
        warnings = warnings
    }
end

--------------------------------------------------
-- Constructor
--------------------------------------------------

function AE2.new(peripheralName)
    local self = setmetatable({}, AE2)

    self.peripheralName = peripheralName
    self.device = nil

    self:refreshPeripheral()

    return self
end

--------------------------------------------------
-- Peripheral discovery
--------------------------------------------------

function AE2:refreshPeripheral()
    if self.peripheralName then
        if peripheral.isPresent(
            self.peripheralName
        ) then
            self.device = peripheral.wrap(
                self.peripheralName
            )
        else
            self.device = nil
        end
    else
        self.device = peripheral.find(
            PERIPHERAL_TYPE
        )
    end

    return self.device ~= nil
end

function AE2:isConnected()
    return self:refreshPeripheral()
end

function AE2:getPeripheral()
    return self.device
end

--------------------------------------------------
-- Lightweight state
--------------------------------------------------

function AE2:getState(options)
    self:refreshPeripheral()

    options = options or {}

    local errors = {}

    if not self.device then
        local state = {
            connected = false,
            networkConnected = false,
            online = false,

            peripheralType = PERIPHERAL_TYPE,

            errors = {
                {
                    method = "discovery",
                    message = "ME Bridge unavailable"
                }
            },

            hasErrors = true,

            itemStorage = buildStorage(
                0,
                0,
                0
            ),

            fluidStorage = buildStorage(
                0,
                0,
                0
            ),

            energy = {
                stored = 0,
                capacity = 0,
                available = 0,
                percentage = 0,
                usage = 0,
                averageInput = 0,
                netFlow = 0
            },

            crafting = {
                cpuCount = 0,
                busyCPUCount = 0,
                freeCPUCount = 0,
                activeTaskCount = 0
            }
        }

        state.safety = evaluateSafety(state)

        return state
    end

    local device = self.device

    --------------------------------------------------
    -- Item storage
    --------------------------------------------------

    local itemStorage = buildStorage(
        readNumber(
            device,
            errors,
            "getUsedItemStorage",
            0
        ),

        readNumber(
            device,
            errors,
            "getTotalItemStorage",
            0
        ),

        readNumber(
            device,
            errors,
            "getAvailableItemStorage",
            0
        )
    )

    --------------------------------------------------
    -- Fluid storage
    --------------------------------------------------

    local fluidStorage = buildStorage(
        readNumber(
            device,
            errors,
            "getUsedFluidStorage",
            0
        ),

        readNumber(
            device,
            errors,
            "getTotalFluidStorage",
            0
        ),

        readNumber(
            device,
            errors,
            "getAvailableFluidStorage",
            0
        )
    )

    --------------------------------------------------
    -- Energy
    --------------------------------------------------

    local storedEnergy = readNumber(
        device,
        errors,
        "getStoredEnergy",
        0
    )

    local energyCapacity = readNumber(
        device,
        errors,
        "getEnergyCapacity",
        0
    )

    local energyUsage = readNumber(
        device,
        errors,
        "getEnergyUsage",
        0
    )

    local averageEnergyInput = readNumber(
        device,
        errors,
        "getAverageEnergyInput",
        0
    )

    local energy = {
        stored = storedEnergy,
        capacity = energyCapacity,

        available = math.max(
            energyCapacity - storedEnergy,
            0
        ),

        percentage = SafeCall.calculatePercentage(
            storedEnergy,
            energyCapacity,
            0
        ),

        usage = energyUsage,
        averageInput = averageEnergyInput,

        netFlow =
            averageEnergyInput
            - energyUsage
    }

    --------------------------------------------------
    -- Crafting summary
    --------------------------------------------------

    local rawCPUs = readTable(
        device,
        errors,
        "getCraftingCPUs",
        {}
    )

    local craftingCPUs =
        normalizeCraftingCPUs(rawCPUs)

    local busyCPUCount = 0

    for _, cpu in ipairs(craftingCPUs) do
        if cpu.isBusy then
            busyCPUCount =
                busyCPUCount + 1
        end
    end

    local rawTasks = readTable(
        device,
        errors,
        "getCraftingTasks",
        {}
    )

    local craftingTasks =
        normalizeCraftingTasks(rawTasks)

    --------------------------------------------------
    -- State
    --------------------------------------------------

    local state = {
        connected = true,

        peripheralType = PERIPHERAL_TYPE,

        name = readString(
            device,
            errors,
            "getName",
            "ME Bridge"
        ),

        networkConnected = readBoolean(
            device,
            errors,
            "isConnected",
            false
        ),

        online = readBoolean(
            device,
            errors,
            "isOnline",
            false
        ),

        itemStorage = itemStorage,
        fluidStorage = fluidStorage,
        energy = energy,

        crafting = {
            cpuCount = #craftingCPUs,
            busyCPUCount = busyCPUCount,

            freeCPUCount = math.max(
                #craftingCPUs - busyCPUCount,
                0
            ),

            activeTaskCount = #craftingTasks,

            cpus = craftingCPUs,
            tasks = craftingTasks
        },

        errors = errors
    }

    --------------------------------------------------
    -- Optional detailed information
    --------------------------------------------------

    if options.includeCells then
        state.cells = self:getCells()
        state.cellCount = #state.cells
    end

    if options.includeDrives then
        state.drives = self:getDrives()
        state.driveCount = #state.drives
    end

    if options.includeItems then
        state.items = self:getItems()
        state.itemTypeCount = #state.items

        local totalItemCount = 0

        for _, item in ipairs(state.items) do
            totalItemCount =
                totalItemCount + item.count
        end

        state.totalItemCount = totalItemCount
    end

    if options.includeCraftableItems then
        state.craftableItems =
            self:getCraftableItems()

        state.craftableItemCount =
            #state.craftableItems
    end

    if options.includePatterns then
        state.patterns = self:getPatterns()
        state.patternCount = #state.patterns
    end

    if options.includeFluids then
        state.fluids = self:getFluids()
        state.fluidTypeCount = #state.fluids
    end

    state.hasErrors = #errors > 0
    state.safety = evaluateSafety(state)

    return state
end

--------------------------------------------------
-- Detailed getters
--------------------------------------------------

function AE2:getItems()
    self:refreshPeripheral()

    if not self.device then
        return {}
    end

    local items = SafeCall.getTable(
        self.device,
        "getItems",
        {}
    )

    return normalizeItems(items)
end

function AE2:getCraftableItems()
    self:refreshPeripheral()

    if not self.device then
        return {}
    end

    local items = SafeCall.getTable(
        self.device,
        "getCraftableItems",
        {}
    )

    return normalizeItems(items)
end

function AE2:getCells()
    self:refreshPeripheral()

    if not self.device then
        return {}
    end

    local cells = SafeCall.getTable(
        self.device,
        "getCells",
        {}
    )

    return normalizeCells(cells)
end

function AE2:getDrives()
    self:refreshPeripheral()

    if not self.device then
        return {}
    end

    local drives = SafeCall.getTable(
        self.device,
        "getDrives",
        {}
    )

    return normalizeDrives(drives)
end

function AE2:getCraftingCPUs()
    self:refreshPeripheral()

    if not self.device then
        return {}
    end

    local cpus = SafeCall.getTable(
        self.device,
        "getCraftingCPUs",
        {}
    )

    return normalizeCraftingCPUs(cpus)
end

function AE2:getCraftingTasks()
    self:refreshPeripheral()

    if not self.device then
        return {}
    end

    local tasks = SafeCall.getTable(
        self.device,
        "getCraftingTasks",
        {}
    )

    return normalizeCraftingTasks(tasks)
end

function AE2:getPatterns()
    self:refreshPeripheral()

    if not self.device then
        return {}
    end

    local patterns = SafeCall.getTable(
        self.device,
        "getPatterns",
        {}
    )

    return patterns
end

function AE2:getFluids()
    self:refreshPeripheral()

    if not self.device then
        return {}
    end

    local fluids = SafeCall.getTable(
        self.device,
        "getFluids",
        {}
    )

    return fluids
end

--------------------------------------------------
-- Item search
--------------------------------------------------

function AE2:findItem(query)
    if type(query) ~= "string" or query == "" then
        return nil
    end

    local lowerQuery = string.lower(query)
    local items = self:getItems()

    for _, item in ipairs(items) do
        local name = string.lower(
            tostring(item.name or "")
        )

        local displayName = string.lower(
            tostring(item.displayName or "")
        )

        if name == lowerQuery
            or displayName == lowerQuery then
            return item
        end
    end

    for _, item in ipairs(items) do
        local name = string.lower(
            tostring(item.name or "")
        )

        local displayName = string.lower(
            tostring(item.displayName or "")
        )

        if string.find(
            name,
            lowerQuery,
            1,
            true
        ) or string.find(
            displayName,
            lowerQuery,
            1,
            true
        ) then
            return item
        end
    end

    return nil
end

function AE2:searchItems(query, limit)
    if type(query) ~= "string" then
        return {}
    end

    limit = SafeCall.number(limit, 20)
    limit = math.max(math.floor(limit), 1)

    local lowerQuery = string.lower(query)
    local matches = {}

    for _, item in ipairs(self:getItems()) do
        local name = string.lower(
            tostring(item.name or "")
        )

        local displayName = string.lower(
            tostring(item.displayName or "")
        )

        if string.find(
            name,
            lowerQuery,
            1,
            true
        ) or string.find(
            displayName,
            lowerQuery,
            1,
            true
        ) then
            matches[#matches + 1] = item

            if #matches >= limit then
                break
            end
        end
    end

    return matches
end

--------------------------------------------------
-- Item sorting
--------------------------------------------------

function AE2:getTopItems(limit)
    limit = SafeCall.number(limit, 10)
    limit = math.max(math.floor(limit), 1)

    local items = self:getItems()

    table.sort(
        items,
        function(a, b)
            return a.count > b.count
        end
    )

    local result = {}

    for index = 1, math.min(limit, #items) do
        result[index] = items[index]
    end

    return result
end

--------------------------------------------------
-- Crafting commands
--------------------------------------------------

function AE2:craftItem(item, amount)
    if type(item) ~= "table"
        and type(item) ~= "string" then
        return {
            success = false,
            action = "craftItem",
            error = "Invalid item"
        }
    end

    amount = SafeCall.number(amount, 1)

    if amount <= 0 then
        return {
            success = false,
            action = "craftItem",
            error = "Invalid amount"
        }
    end

    self:refreshPeripheral()

    if not self.device then
        return {
            success = false,
            action = "craftItem",
            error = "ME Bridge unavailable"
        }
    end

    local request

    if type(item) == "string" then
        request = {
            name = item,
            count = math.floor(amount)
        }
    else
        request = {}

        for key, value in pairs(item) do
            request[key] = value
        end

        request.count = math.floor(amount)
    end

    local success, value, err = SafeCall.raw(
        self.device,
        "craftItem",
        request
    )

    return {
        success = success,
        value = value,
        error = err,
        action = "craftItem",
        request = request
    }
end

function AE2:cancelCraftingTasks()
    self:refreshPeripheral()

    local success, value, err = SafeCall.raw(
        self.device,
        "cancelCraftingTasks"
    )

    return {
        success = success,
        value = value,
        error = err,
        action = "cancelCraftingTasks"
    }
end

--------------------------------------------------
-- Aliases
--------------------------------------------------

function AE2:read(options)
    return self:getState(options)
end

function AE2:update(options)
    return self:getState(options)
end

return AE2