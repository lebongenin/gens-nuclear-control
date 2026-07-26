--================================================--
-- GEN'S Nuclear Control
-- Test : AE2 API
-- Version : 0.1.0
--================================================--

local AE2 = dofile("/api/ae2.lua")
local Test = dofile("/tools/tests/testlib.lua")
local SafeCall = dofile("/core/safe_call.lua")

local test = Test.new("AE2 API Test v0.1.0")

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function formatNumber(value, decimals)
    if not SafeCall.isFiniteNumber(value) then
        return "N/A"
    end

    return string.format(
        "%." .. tostring(decimals or 2) .. "f",
        value
    )
end

local function formatPercent(value)
    if not SafeCall.isFiniteNumber(value) then
        return "N/A"
    end

    return string.format("%.2f%%", value * 100)
end

local function validateStorage(name, storage)
    test:section(name)

    test:expectType(
        name .. " structure",
        storage,
        "table"
    )

    if type(storage) ~= "table" then
        return
    end

    test:expectNonNegative(
        name .. " used",
        storage.used
    )

    test:expectNonNegative(
        name .. " total",
        storage.total
    )

    test:expectNonNegative(
        name .. " available",
        storage.available
    )

    test:expectPercentage(
        name .. " percentage",
        storage.percentage
    )

    test:expectTrue(
        name .. " used not above total",
        storage.used <= storage.total
    )

    test:expectTrue(
        name .. " available not above total",
        storage.available <= storage.total
    )

    test:expectEqual(
        name .. " storage balance",
        storage.used + storage.available,
        storage.total
    )
end

local function validateItem(item, prefix)
    prefix = prefix or "Item"

    test:expectType(
        prefix .. " structure",
        item,
        "table"
    )

    if type(item) ~= "table" then
        return
    end

    if item.name ~= nil then
        test:expectType(
            prefix .. " name",
            item.name,
            "string"
        )
    else
        test:result(
            prefix .. " name may be nil",
            true
        )
    end

    test:expectType(
        prefix .. " display name",
        item.displayName,
        "string"
    )

    test:expectNonNegative(
        prefix .. " count",
        item.count
    )

    test:expectNonNegative(
        prefix .. " max stack size",
        item.maxStackSize
    )

    test:expectType(
        prefix .. " craftable flag",
        item.isCraftable,
        "boolean"
    )

    test:expectType(
        prefix .. " tags",
        item.tags,
        "table"
    )

    test:expectType(
        prefix .. " components",
        item.components,
        "table"
    )
end

local function validateCell(cell, prefix)
    prefix = prefix or "Cell"

    test:expectType(
        prefix .. " structure",
        cell,
        "table"
    )

    if type(cell) ~= "table" then
        return
    end

    test:expectType(
        prefix .. " type",
        cell.type,
        "string"
    )

    if cell.itemName ~= nil then
        test:expectType(
            prefix .. " item name",
            cell.itemName,
            "string"
        )
    end

    test:expectNonNegative(
        prefix .. " bytes",
        cell.bytes
    )

    test:expectNonNegative(
        prefix .. " used bytes",
        cell.usedBytes
    )

    test:expectNonNegative(
        prefix .. " available bytes",
        cell.availableBytes
    )

    test:expectPercentage(
        prefix .. " percentage",
        cell.percentage
    )

    test:expectNonNegative(
        prefix .. " total types",
        cell.totalTypes
    )

    test:expectNonNegative(
        prefix .. " bytes per type",
        cell.bytesPerType
    )

    test:expectType(
        prefix .. " fuzzy mode",
        cell.fuzzyMode,
        "string"
    )

    test:expectTrue(
        prefix .. " used bytes not above capacity",
        cell.usedBytes <= cell.bytes
    )

    test:expectEqual(
        prefix .. " byte balance",
        cell.usedBytes + cell.availableBytes,
        cell.bytes
    )
end

local function validateDrive(drive, prefix)
    prefix = prefix or "Drive"

    test:expectType(
        prefix .. " structure",
        drive,
        "table"
    )

    if type(drive) ~= "table" then
        return
    end

    test:expectType(
        prefix .. " name",
        drive.name,
        "string"
    )

    test:expectFinite(
        prefix .. " priority",
        drive.priority
    )

    test:expectType(
        prefix .. " position",
        drive.position,
        "table"
    )

    if type(drive.position) == "table" then
        test:expectFinite(
            prefix .. " position X",
            drive.position.x
        )

        test:expectFinite(
            prefix .. " position Y",
            drive.position.y
        )

        test:expectFinite(
            prefix .. " position Z",
            drive.position.z
        )
    end

    test:expectNonNegative(
        prefix .. " total bytes",
        drive.totalBytes
    )

    test:expectNonNegative(
        prefix .. " used bytes",
        drive.usedBytes
    )

    test:expectPercentage(
        prefix .. " percentage",
        drive.percentage
    )

    test:expectType(
        prefix .. " cells",
        drive.cells,
        "table"
    )

    test:expectNonNegative(
        prefix .. " cell count",
        drive.cellCount
    )

    if type(drive.cells) == "table" then
        test:expectEqual(
            prefix .. " cell count matches",
            drive.cellCount,
            #drive.cells
        )
    end
end

local function validateCPU(cpu, prefix)
    prefix = prefix or "Crafting CPU"

    test:expectType(
        prefix .. " structure",
        cpu,
        "table"
    )

    if type(cpu) ~= "table" then
        return
    end

    test:expectType(
        prefix .. " name",
        cpu.name,
        "string"
    )

    test:expectNonNegative(
        prefix .. " storage",
        cpu.storage
    )

    test:expectNonNegative(
        prefix .. " co-processors",
        cpu.coProcessors
    )

    test:expectType(
        prefix .. " busy flag",
        cpu.isBusy,
        "boolean"
    )

    test:expectType(
        prefix .. " selection mode",
        cpu.selectionMode,
        "string"
    )
end

--------------------------------------------------
-- Constructor
--------------------------------------------------

test:section("CONSTRUCTOR")

local bridge = AE2.new()

test:expectType(
    "AE2 object",
    bridge,
    "table"
)

test:expectType(
    "getState available",
    bridge.getState,
    "function"
)

test:expectType(
    "getItems available",
    bridge.getItems,
    "function"
)

test:expectType(
    "getCells available",
    bridge.getCells,
    "function"
)

test:expectType(
    "getDrives available",
    bridge.getDrives,
    "function"
)

test:expectType(
    "getCraftingCPUs available",
    bridge.getCraftingCPUs,
    "function"
)

test:expectType(
    "getCraftingTasks available",
    bridge.getCraftingTasks,
    "function"
)

test:expectType(
    "findItem available",
    bridge.findItem,
    "function"
)

test:expectType(
    "searchItems available",
    bridge.searchItems,
    "function"
)

test:expectType(
    "getTopItems available",
    bridge.getTopItems,
    "function"
)

test:expectType(
    "craftItem available",
    bridge.craftItem,
    "function"
)

--------------------------------------------------
-- Discovery
--------------------------------------------------

test:section("PERIPHERAL DISCOVERY")

test:expectTrue(
    "ME Bridge connected",
    bridge:isConnected()
)

test:expectType(
    "Wrapped peripheral",
    bridge:getPeripheral(),
    "table"
)

--------------------------------------------------
-- Lightweight state
--------------------------------------------------

test:section("LIGHTWEIGHT STATE")

local stateSuccess, state = pcall(function()
    return bridge:getState()
end)

test:expectTrue(
    "getState does not crash",
    stateSuccess
)

if not stateSuccess then
    term.setTextColor(colors.red)
    print(tostring(state))
    term.setTextColor(colors.white)

    test:summary("AE2 API: READY")
    return
end

test:expectType(
    "State structure",
    state,
    "table"
)

test:expectTrue(
    "State connected",
    state.connected
)

test:expectEqual(
    "Peripheral type",
    state.peripheralType,
    "me_bridge"
)

test:expectType(
    "Bridge name",
    state.name,
    "string"
)

test:expectType(
    "Network connected flag",
    state.networkConnected,
    "boolean"
)

test:expectType(
    "Online flag",
    state.online,
    "boolean"
)

--------------------------------------------------
-- Storage
--------------------------------------------------

validateStorage(
    "ITEM STORAGE",
    state.itemStorage
)

validateStorage(
    "FLUID STORAGE",
    state.fluidStorage
)

--------------------------------------------------
-- Energy
--------------------------------------------------

test:section("ENERGY")

test:expectType(
    "Energy structure",
    state.energy,
    "table"
)

if type(state.energy) == "table" then
    test:expectNonNegative(
        "Stored energy",
        state.energy.stored
    )

    test:expectNonNegative(
        "Energy capacity",
        state.energy.capacity
    )

    test:expectNonNegative(
        "Available energy",
        state.energy.available
    )

    test:expectPercentage(
        "Energy percentage",
        state.energy.percentage
    )

    test:expectNonNegative(
        "Energy usage",
        state.energy.usage
    )

    test:expectNonNegative(
        "Average energy input",
        state.energy.averageInput
    )

    test:expectFinite(
        "Energy net flow",
        state.energy.netFlow
    )

    test:expectTrue(
        "Stored energy not above capacity",
        state.energy.stored <= state.energy.capacity
    )

    test:expectEqual(
        "Energy available calculation",
        state.energy.available,
        math.max(
            state.energy.capacity
            - state.energy.stored,
            0
        )
    )

    test:expectEqual(
        "Energy net flow calculation",
        state.energy.netFlow,
        state.energy.averageInput
        - state.energy.usage
    )
end

--------------------------------------------------
-- Crafting summary
--------------------------------------------------

test:section("CRAFTING SUMMARY")

test:expectType(
    "Crafting structure",
    state.crafting,
    "table"
)

if type(state.crafting) == "table" then
    test:expectNonNegative(
        "CPU count",
        state.crafting.cpuCount
    )

    test:expectNonNegative(
        "Busy CPU count",
        state.crafting.busyCPUCount
    )

    test:expectNonNegative(
        "Free CPU count",
        state.crafting.freeCPUCount
    )

    test:expectNonNegative(
        "Active task count",
        state.crafting.activeTaskCount
    )

    test:expectType(
        "CPU list",
        state.crafting.cpus,
        "table"
    )

    test:expectType(
        "Task list",
        state.crafting.tasks,
        "table"
    )

    test:expectEqual(
        "CPU total calculation",
        state.crafting.busyCPUCount
        + state.crafting.freeCPUCount,
        state.crafting.cpuCount
    )

    test:expectEqual(
        "CPU list count",
        #state.crafting.cpus,
        state.crafting.cpuCount
    )

    test:expectEqual(
        "Task list count",
        #state.crafting.tasks,
        state.crafting.activeTaskCount
    )

    if #state.crafting.cpus > 0 then
        validateCPU(
            state.crafting.cpus[1],
            "First crafting CPU"
        )
    end
end

--------------------------------------------------
-- Errors and safety
--------------------------------------------------

test:section("ERRORS AND SAFETY")

test:expectErrors(state)
test:expectSafety(state.safety)

--------------------------------------------------
-- Detailed getters
--------------------------------------------------

test:section("DETAILED GETTERS")

local itemsSuccess, items = pcall(function()
    return bridge:getItems()
end)

test:expectTrue(
    "getItems does not crash",
    itemsSuccess
)

if itemsSuccess then
    test:expectType(
        "getItems returns table",
        items,
        "table"
    )

    if #items > 0 then
        validateItem(
            items[1],
            "First stored item"
        )
    end
end

local cellsSuccess, cells = pcall(function()
    return bridge:getCells()
end)

test:expectTrue(
    "getCells does not crash",
    cellsSuccess
)

if cellsSuccess then
    test:expectType(
        "getCells returns table",
        cells,
        "table"
    )

    if #cells > 0 then
        validateCell(
            cells[1],
            "First storage cell"
        )
    end
end

local drivesSuccess, drives = pcall(function()
    return bridge:getDrives()
end)

test:expectTrue(
    "getDrives does not crash",
    drivesSuccess
)

if drivesSuccess then
    test:expectType(
        "getDrives returns table",
        drives,
        "table"
    )

    if #drives > 0 then
        validateDrive(
            drives[1],
            "First ME Drive"
        )
    end
end

local cpuSuccess, cpus = pcall(function()
    return bridge:getCraftingCPUs()
end)

test:expectTrue(
    "getCraftingCPUs does not crash",
    cpuSuccess
)

if cpuSuccess then
    test:expectType(
        "getCraftingCPUs returns table",
        cpus,
        "table"
    )

    if #cpus > 0 then
        validateCPU(
            cpus[1],
            "Detailed crafting CPU"
        )
    end
end

local tasksSuccess, tasks = pcall(function()
    return bridge:getCraftingTasks()
end)

test:expectTrue(
    "getCraftingTasks does not crash",
    tasksSuccess
)

if tasksSuccess then
    test:expectType(
        "getCraftingTasks returns table",
        tasks,
        "table"
    )
end

local patternsSuccess, patterns = pcall(function()
    return bridge:getPatterns()
end)

test:expectTrue(
    "getPatterns does not crash",
    patternsSuccess
)

if patternsSuccess then
    test:expectType(
        "getPatterns returns table",
        patterns,
        "table"
    )
end

local fluidsSuccess, fluids = pcall(function()
    return bridge:getFluids()
end)

test:expectTrue(
    "getFluids does not crash",
    fluidsSuccess
)

if fluidsSuccess then
    test:expectType(
        "getFluids returns table",
        fluids,
        "table"
    )
end

--------------------------------------------------
-- Detailed state
--------------------------------------------------

test:section("DETAILED STATE")

local detailedSuccess, detailedState = pcall(function()
    return bridge:getState({
        includeItems = true,
        includeCells = true,
        includeDrives = true,
        includeCraftableItems = true,
        includePatterns = true,
        includeFluids = true
    })
end)

test:expectTrue(
    "Detailed state does not crash",
    detailedSuccess
)

if detailedSuccess then
    test:expectType(
        "Detailed items",
        detailedState.items,
        "table"
    )

    test:expectType(
        "Detailed cells",
        detailedState.cells,
        "table"
    )

    test:expectType(
        "Detailed drives",
        detailedState.drives,
        "table"
    )

    test:expectType(
        "Detailed craftable items",
        detailedState.craftableItems,
        "table"
    )

    test:expectType(
        "Detailed patterns",
        detailedState.patterns,
        "table"
    )

    test:expectType(
        "Detailed fluids",
        detailedState.fluids,
        "table"
    )

    test:expectEqual(
        "Item type count",
        detailedState.itemTypeCount,
        #detailedState.items
    )

    test:expectEqual(
        "Cell count",
        detailedState.cellCount,
        #detailedState.cells
    )

    test:expectEqual(
        "Drive count",
        detailedState.driveCount,
        #detailedState.drives
    )

    test:expectEqual(
        "Craftable item count",
        detailedState.craftableItemCount,
        #detailedState.craftableItems
    )

    test:expectEqual(
        "Pattern count",
        detailedState.patternCount,
        #detailedState.patterns
    )

    test:expectEqual(
        "Fluid type count",
        detailedState.fluidTypeCount,
        #detailedState.fluids
    )

    test:expectNonNegative(
        "Total item count",
        detailedState.totalItemCount
    )
end

--------------------------------------------------
-- Item search
--------------------------------------------------

test:section("ITEM SEARCH")

test:expectEqual(
    "Empty find query returns nil",
    bridge:findItem(""),
    nil
)

test:expectEqual(
    "Invalid find query returns nil",
    bridge:findItem(nil),
    nil
)

local emptySearch = bridge:searchItems(
    "",
    10
)

test:expectType(
    "Empty search returns table",
    emptySearch,
    "table"
)

local invalidSearch = bridge:searchItems(
    nil,
    10
)

test:expectType(
    "Invalid search returns table",
    invalidSearch,
    "table"
)

test:expectEqual(
    "Invalid search returns empty list",
    #invalidSearch,
    0
)

if itemsSuccess and #items > 0 then
    local firstItem = items[1]

    if firstItem.name then
        local foundByName =
            bridge:findItem(firstItem.name)

        test:expectType(
            "Find item by registry name",
            foundByName,
            "table"
        )

        if type(foundByName) == "table" then
            test:expectEqual(
                "Found item registry name",
                foundByName.name,
                firstItem.name
            )
        end
    end

    local searchTerm =
        firstItem.displayName
        or firstItem.name

    if type(searchTerm) == "string" then
        local searchResults =
            bridge:searchItems(
                searchTerm,
                10
            )

        test:expectType(
            "Search result structure",
            searchResults,
            "table"
        )

        test:expectTrue(
            "Known item search finds a result",
            #searchResults >= 1
        )
    end
end

--------------------------------------------------
-- Top items
--------------------------------------------------

test:section("TOP ITEMS")

local topSuccess, topItems = pcall(function()
    return bridge:getTopItems(10)
end)

test:expectTrue(
    "getTopItems does not crash",
    topSuccess
)

if topSuccess then
    test:expectType(
        "Top items returns table",
        topItems,
        "table"
    )

    test:expectTrue(
        "Top items respects limit",
        #topItems <= 10
    )

    for index = 2, #topItems do
        test:expectTrue(
            "Top item order "
            .. tostring(index - 1)
            .. " -> "
            .. tostring(index),
            topItems[index - 1].count
            >= topItems[index].count
        )
    end
end

--------------------------------------------------
-- Command validation
--------------------------------------------------

test:section("COMMAND VALIDATION")

local invalidItemResult =
    bridge:craftItem(nil, 1)

test:expectType(
    "Invalid craft result structure",
    invalidItemResult,
    "table"
)

test:expectFalse(
    "Nil item rejected",
    invalidItemResult.success
)

test:expectEqual(
    "Nil item action",
    invalidItemResult.action,
    "craftItem"
)

test:expectType(
    "Nil item gives error",
    invalidItemResult.error,
    "string"
)

local invalidTypeResult =
    bridge:craftItem(42, 1)

test:expectFalse(
    "Numeric item rejected",
    invalidTypeResult.success
)

local invalidAmountResult =
    bridge:craftItem(
        "minecraft:oak_planks",
        -1
    )

test:expectFalse(
    "Negative amount rejected",
    invalidAmountResult.success
)

test:expectEqual(
    "Invalid amount action",
    invalidAmountResult.action,
    "craftItem"
)

test:expectType(
    "Invalid amount gives error",
    invalidAmountResult.error,
    "string"
)

term.setTextColor(colors.yellow)
print()
print("No crafting task was started.")
print("cancelCraftingTasks() was not called.")
term.setTextColor(colors.white)

--------------------------------------------------
-- Aliases
--------------------------------------------------

test:section("ALIASES")

local readSuccess, readState = pcall(function()
    return bridge:read()
end)

test:expectTrue(
    "read does not crash",
    readSuccess
)

if readSuccess then
    test:expectType(
        "read returns table",
        readState,
        "table"
    )
end

local updateSuccess, updateState = pcall(function()
    return bridge:update()
end)

test:expectTrue(
    "update does not crash",
    updateSuccess
)

if updateSuccess then
    test:expectType(
        "update returns table",
        updateState,
        "table"
    )
end

--------------------------------------------------
-- Network summary
--------------------------------------------------

test:section("AE2 NETWORK SUMMARY")

term.setTextColor(colors.lightGray)

print(
    "Bridge          : "
    .. tostring(state.name)
)

print(
    "Online          : "
    .. tostring(state.online)
)

print(
    "Network link    : "
    .. tostring(state.networkConnected)
)

print()

print(
    "Item storage    : "
    .. formatNumber(
        state.itemStorage.used,
        0
    )
    .. " / "
    .. formatNumber(
        state.itemStorage.total,
        0
    )
    .. " bytes"
)

print(
    "Item usage      : "
    .. formatPercent(
        state.itemStorage.percentage
    )
)

if detailedSuccess then
    print(
        "Item types      : "
        .. tostring(
            detailedState.itemTypeCount
        )
    )

    print(
        "Total items     : "
        .. formatNumber(
            detailedState.totalItemCount,
            0
        )
    )

    print(
        "Cells           : "
        .. tostring(
            detailedState.cellCount
        )
    )

    print(
        "Drives          : "
        .. tostring(
            detailedState.driveCount
        )
    )
end

print()

print(
    "Energy          : "
    .. formatNumber(
        state.energy.stored,
        2
    )
    .. " / "
    .. formatNumber(
        state.energy.capacity,
        2
    )
)

print(
    "Energy buffer   : "
    .. formatPercent(
        state.energy.percentage
    )
)

print(
    "Energy usage    : "
    .. formatNumber(
        state.energy.usage,
        2
    )
)

print(
    "Average input   : "
    .. formatNumber(
        state.energy.averageInput,
        2
    )
)

print(
    "Energy net flow : "
    .. formatNumber(
        state.energy.netFlow,
        2
    )
)

print()

print(
    "Crafting CPUs   : "
    .. tostring(
        state.crafting.cpuCount
    )
)

print(
    "Busy CPUs       : "
    .. tostring(
        state.crafting.busyCPUCount
    )
)

print(
    "Active tasks    : "
    .. tostring(
        state.crafting.activeTaskCount
    )
)

print()

print(
    "Safety          : "
    .. string.upper(
        tostring(state.safety.level)
    )
)

print(
    "Warnings        : "
    .. tostring(
        #state.safety.warnings
    )
)

term.setTextColor(colors.white)

--------------------------------------------------
-- Summary
--------------------------------------------------

test:summary("AE2 API: READY")