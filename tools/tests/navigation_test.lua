--================================================--
-- GEN'S Nuclear Control
-- Test : Navigation
-- Version : 0.1.0
--================================================--

local Navigation =
    dofile("/core/navigation.lua")

local Test =
    dofile("/tools/tests/testlib.lua")

local test =
    Test.new("Navigation Test v0.1.0")

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function expectPage(
    navigation,
    expected,
    label
)
    test:expectEqual(
        label or ("Current page is " .. expected),
        navigation:getCurrentPage(),
        expected
    )
end

local function countTableEntries(value)
    if type(value) ~= "table" then
        return 0
    end

    local count = 0

    for _ in pairs(value) do
        count = count + 1
    end

    return count
end

--------------------------------------------------
-- Static page validation
--------------------------------------------------

test:section("PAGE VALIDATION")

test:expectTrue(
    "Overview page is valid",
    Navigation.isValidPage("overview")
)

test:expectTrue(
    "Fusion page is valid",
    Navigation.isValidPage("fusion")
)

test:expectTrue(
    "Fission page is valid",
    Navigation.isValidPage("fission")
)

test:expectTrue(
    "Induction page is valid",
    Navigation.isValidPage("induction")
)

test:expectTrue(
    "SPS page is valid",
    Navigation.isValidPage("sps")
)

test:expectTrue(
    "AE2 overview page is valid",
    Navigation.isValidPage("ae2_overview")
)

test:expectTrue(
    "AE2 items page is valid",
    Navigation.isValidPage("ae2_items")
)

test:expectTrue(
    "AE2 cells page is valid",
    Navigation.isValidPage("ae2_cells")
)

test:expectTrue(
    "AE2 drives page is valid",
    Navigation.isValidPage("ae2_drives")
)

test:expectTrue(
    "AE2 crafting page is valid",
    Navigation.isValidPage("ae2_crafting")
)

test:expectFalse(
    "Unknown page is rejected",
    Navigation.isValidPage("unknown")
)

test:expectTrue(
    "AE2 items recognized as AE2 page",
    Navigation.isAE2Page("ae2_items")
)

test:expectFalse(
    "Fusion is not an AE2 page",
    Navigation.isAE2Page("fusion")
)

--------------------------------------------------
-- Constructor
--------------------------------------------------

test:section("CONSTRUCTOR")

local navigation = Navigation.new()

test:expectType(
    "Navigation object",
    navigation,
    "table"
)

expectPage(
    navigation,
    "overview",
    "Default page is overview"
)

test:expectEqual(
    "Previous page initially nil",
    navigation:getPreviousPage(),
    nil
)

test:expectEqual(
    "Default AE2 page",
    navigation:getLastAE2Page(),
    "ae2_overview"
)

local customNavigation = Navigation.new({
    defaultPage = "fusion",
    historyLimit = 5
})

expectPage(
    customNavigation,
    "fusion",
    "Custom default page accepted"
)

local invalidNavigation = Navigation.new({
    defaultPage = "invalid"
})

expectPage(
    invalidNavigation,
    "overview",
    "Invalid default page falls back"
)

--------------------------------------------------
-- Page transitions
--------------------------------------------------

test:section("PAGE TRANSITIONS")

local success, err =
    navigation:goTo("fusion")

test:expectTrue(
    "Navigate to Fusion",
    success
)

test:expectEqual(
    "Fusion navigation has no error",
    err,
    nil
)

expectPage(
    navigation,
    "fusion"
)

test:expectEqual(
    "Previous page after Fusion",
    navigation:getPreviousPage(),
    "overview"
)

success, err =
    navigation:goTo("invalid")

test:expectFalse(
    "Invalid navigation rejected",
    success
)

test:expectType(
    "Invalid navigation returns error",
    err,
    "string"
)

expectPage(
    navigation,
    "fusion",
    "Invalid navigation preserves page"
)

success, err =
    navigation:goTo("fusion")

test:expectTrue(
    "Navigating to current page succeeds",
    success
)

expectPage(
    navigation,
    "fusion",
    "Current page unchanged"
)

--------------------------------------------------
-- AE2 navigation memory
--------------------------------------------------

test:section("AE2 NAVIGATION MEMORY")

navigation:goTo("ae2_items")

expectPage(
    navigation,
    "ae2_items"
)

test:expectEqual(
    "Last AE2 page updated",
    navigation:getLastAE2Page(),
    "ae2_items"
)

navigation:goOverview()

expectPage(
    navigation,
    "overview"
)

navigation:openAE2()

expectPage(
    navigation,
    "ae2_items",
    "openAE2 restores last AE2 page"
)

navigation:goTo("ae2_crafting")

test:expectEqual(
    "Last AE2 page becomes crafting",
    navigation:getLastAE2Page(),
    "ae2_crafting"
)

--------------------------------------------------
-- Reset
--------------------------------------------------

test:section("RESET")

navigation:reset()

expectPage(
    navigation,
    "overview",
    "Reset returns to overview"
)

test:expectEqual(
    "Previous page cleared",
    navigation:getPreviousPage(),
    nil
)

local debugState =
    navigation:getDebugState()

test:expectEqual(
    "Reset history contains one page",
    #debugState.history,
    1
)

navigation:reset("ae2_cells")

expectPage(
    navigation,
    "ae2_cells",
    "Reset accepts valid page"
)

test:expectEqual(
    "Reset updates last AE2 page",
    navigation:getLastAE2Page(),
    "ae2_cells"
)

navigation:reset("invalid")

expectPage(
    navigation,
    "overview",
    "Invalid reset page falls back"
)

--------------------------------------------------
-- Basic region registration
--------------------------------------------------

test:section("REGION REGISTRATION")

success, err =
    navigation:registerRegion(nil)

test:expectFalse(
    "Nil region rejected",
    success
)

test:expectType(
    "Nil region returns error",
    err,
    "string"
)

success, err =
    navigation:registerRegion({
        x = 1,
        y = 1,
        width = 5,
        height = 5
    })

test:expectFalse(
    "Region without id rejected",
    success
)

success, err =
    navigation:registerRegion({
        id = "invalid_size",
        x = 1,
        y = 1,
        width = 0,
        height = 5
    })

test:expectFalse(
    "Zero-width region rejected",
    success
)

success, err =
    navigation:registerRegion({
        id = "invalid_page",
        x = 1,
        y = 1,
        width = 5,
        height = 5,
        page = "invalid"
    })

test:expectFalse(
    "Invalid source page rejected",
    success
)

success, err =
    navigation:registerRegion({
        id = "invalid_target",
        x = 1,
        y = 1,
        width = 5,
        height = 5,
        targetPage = "invalid"
    })

test:expectFalse(
    "Invalid target page rejected",
    success
)

local region

success, region =
    navigation:registerRegion({
        id = "fusion_panel",
        x = 10,
        y = 5,
        width = 20,
        height = 10,
        page = "overview",
        targetPage = "fusion",
        monitorName = "back",
        data = {
            system = "fusion"
        }
    })

test:expectTrue(
    "Valid region registered",
    success
)

test:expectType(
    "Registered region returned",
    region,
    "table"
)

test:expectEqual(
    "Region id",
    region.id,
    "fusion_panel"
)

test:expectEqual(
    "Region target page",
    region.targetPage,
    "fusion"
)

test:expectEqual(
    "Region monitor name",
    region.monitorName,
    "back"
)

test:expectEqual(
    "Region data copied",
    region.data.system,
    "fusion"
)

test:expectType(
    "getRegion returns region",
    navigation:getRegion("fusion_panel"),
    "table"
)

--------------------------------------------------
-- Region coordinate lookup
--------------------------------------------------

test:section("REGION LOOKUP")

navigation:reset("overview")

local found =
    navigation:findRegion(
        "back",
        10,
        5
    )

test:expectType(
    "Top-left coordinate included",
    found,
    "table"
)

found =
    navigation:findRegion(
        "back",
        29,
        14
    )

test:expectType(
    "Bottom-right coordinate included",
    found,
    "table"
)

found =
    navigation:findRegion(
        "back",
        30,
        14
    )

test:expectEqual(
    "Coordinate after right edge rejected",
    found,
    nil
)

found =
    navigation:findRegion(
        "back",
        29,
        15
    )

test:expectEqual(
    "Coordinate below region rejected",
    found,
    nil
)

found =
    navigation:findRegion(
        "left",
        15,
        8
    )

test:expectEqual(
    "Wrong monitor rejected",
    found,
    nil
)

--------------------------------------------------
-- Page link touch
--------------------------------------------------

test:section("PAGE LINK TOUCH")

local touchResult =
    navigation:handleTouch(
        "back",
        15,
        8
    )

test:expectType(
    "Touch result structure",
    touchResult,
    "table"
)

test:expectTrue(
    "Touch handled",
    touchResult.handled
)

test:expectTrue(
    "Touch navigation succeeds",
    touchResult.success
)

test:expectEqual(
    "Touched region id",
    touchResult.regionId,
    "fusion_panel"
)

test:expectEqual(
    "Touch previous page",
    touchResult.previousPage,
    "overview"
)

test:expectEqual(
    "Touch target page",
    touchResult.page,
    "fusion"
)

expectPage(
    navigation,
    "fusion"
)

touchResult =
    navigation:handleTouch(
        "back",
        100,
        100
    )

test:expectFalse(
    "Unregistered touch not handled",
    touchResult.handled
)

expectPage(
    navigation,
    "fusion",
    "Unregistered touch preserves page"
)

--------------------------------------------------
-- Regions are cleared on navigation
--------------------------------------------------

test:section("REGION CLEARING")

test:expectEqual(
    "Regions cleared after page transition",
    navigation:getRegion("fusion_panel"),
    nil
)

local regions =
    navigation:getRegions("overview")

test:expectEqual(
    "Overview region list cleared",
    #regions,
    0
)

--------------------------------------------------
-- Action regions
--------------------------------------------------

test:section("ACTION REGIONS")

navigation:reset("fusion")

local actionCalled = false
local actionArguments = {}

success, region =
    navigation:registerAction(
        "test_action",
        2,
        2,
        8,
        3,
        function(
            touchedRegion,
            monitorName,
            x,
            y
        )
            actionCalled = true

            actionArguments = {
                id = touchedRegion.id,
                monitorName = monitorName,
                x = x,
                y = y
            }

            return "ACTION_OK"
        end,
        {
            page = "fusion",
            monitorName = "back"
        }
    )

test:expectTrue(
    "Action region registered",
    success
)

touchResult =
    navigation:handleTouch(
        "back",
        4,
        3
    )

test:expectTrue(
    "Action touch handled",
    touchResult.handled
)

test:expectTrue(
    "Action callback succeeds",
    touchResult.success
)

test:expectEqual(
    "Action return value",
    touchResult.value,
    "ACTION_OK"
)

test:expectTrue(
    "Action callback executed",
    actionCalled
)

test:expectEqual(
    "Action receives region id",
    actionArguments.id,
    "test_action"
)

test:expectEqual(
    "Action receives monitor",
    actionArguments.monitorName,
    "back"
)

test:expectEqual(
    "Action receives X",
    actionArguments.x,
    4
)

test:expectEqual(
    "Action receives Y",
    actionArguments.y,
    3
)

--------------------------------------------------
-- Failed action protection
--------------------------------------------------

success =
    navigation:registerAction(
        "failing_action",
        12,
        2,
        8,
        3,
        function()
            error("Simulated navigation failure")
        end,
        {
            page = "fusion",
            monitorName = "back"
        }
    )

test:expectTrue(
    "Failing action region registered",
    success
)

touchResult =
    navigation:handleTouch(
        "back",
        14,
        3
    )

test:expectTrue(
    "Failing action touch handled",
    touchResult.handled
)

test:expectFalse(
    "Failing action caught safely",
    touchResult.success
)

test:expectType(
    "Failing action returns error",
    touchResult.error,
    "string"
)

--------------------------------------------------
-- Enabled and disabled regions
--------------------------------------------------

test:section("REGION ENABLE STATE")

success =
    navigation:registerPageLink(
        "disabled_link",
        2,
        8,
        10,
        3,
        "fission",
        {
            page = "fusion",
            monitorName = "back",
            enabled = false
        }
    )

test:expectTrue(
    "Disabled region registered",
    success
)

touchResult =
    navigation:handleTouch(
        "back",
        4,
        9
    )

test:expectFalse(
    "Disabled region ignores touch",
    touchResult.handled
)

test:expectTrue(
    "Region enabled",
    navigation:setRegionEnabled(
        "disabled_link",
        true
    )
)

touchResult =
    navigation:handleTouch(
        "back",
        4,
        9
    )

test:expectTrue(
    "Enabled region handles touch",
    touchResult.handled
)

expectPage(
    navigation,
    "fission",
    "Enabled link changes page"
)

test:expectFalse(
    "Unknown region cannot be enabled",
    navigation:setRegionEnabled(
        "missing_region",
        true
    )
)

--------------------------------------------------
-- Region priority
--------------------------------------------------

test:section("REGION PRIORITY")

navigation:reset("overview")

navigation:registerPageLink(
    "low_priority",
    1,
    1,
    10,
    10,
    "fusion",
    {
        page = "overview",
        priority = 1
    }
)

navigation:registerPageLink(
    "high_priority",
    1,
    1,
    10,
    10,
    "sps",
    {
        page = "overview",
        priority = 10
    }
)

found =
    navigation:findRegion(
        nil,
        5,
        5
    )

test:expectEqual(
    "Highest priority region selected",
    found.id,
    "high_priority"
)

touchResult =
    navigation:handleTouch(
        nil,
        5,
        5
    )

test:expectEqual(
    "Highest priority target opened",
    touchResult.page,
    "sps"
)

--------------------------------------------------
-- Remove and clear regions
--------------------------------------------------

test:section("REMOVE AND CLEAR")

navigation:reset("overview")

navigation:registerPageLink(
    "removable",
    1,
    1,
    5,
    5,
    "fusion"
)

test:expectTrue(
    "Region removed",
    navigation:removeRegion("removable")
)

test:expectEqual(
    "Removed region unavailable",
    navigation:getRegion("removable"),
    nil
)

test:expectFalse(
    "Removing missing region returns false",
    navigation:removeRegion("removable")
)

navigation:registerPageLink(
    "overview_one",
    1,
    1,
    5,
    5,
    "fusion",
    {
        page = "overview"
    }
)

navigation:registerPageLink(
    "overview_two",
    7,
    1,
    5,
    5,
    "fission",
    {
        page = "overview"
    }
)

test:expectEqual(
    "Two overview regions registered",
    #navigation:getRegions("overview"),
    2
)

navigation:clearRegions("overview")

test:expectEqual(
    "Specific page regions cleared",
    #navigation:getRegions("overview"),
    0
)

--------------------------------------------------
-- Back navigation
--------------------------------------------------

test:section("BACK NAVIGATION")

navigation:reset("overview")
navigation:goTo("fusion")
navigation:goTo("fission")
navigation:goTo("sps")

expectPage(
    navigation,
    "sps"
)

navigation:goBack()

expectPage(
    navigation,
    "fission",
    "Back returns to Fission"
)

navigation:goBack()

expectPage(
    navigation,
    "fusion",
    "Back returns to Fusion"
)

navigation:goBack()

expectPage(
    navigation,
    "overview",
    "Back returns to Overview"
)

navigation:goBack()

expectPage(
    navigation,
    "overview",
    "Back at history root remains Overview"
)

--------------------------------------------------
-- Back button region
--------------------------------------------------

test:section("BACK BUTTON")

navigation:reset("overview")
navigation:goTo("fusion")

success =
    navigation:registerBackButton(
        40,
        1,
        10,
        2,
        {
            page = "fusion",
            monitorName = "back"
        }
    )

test:expectTrue(
    "Back button registered",
    success
)

touchResult =
    navigation:handleTouch(
        "back",
        45,
        1
    )

test:expectTrue(
    "Back button handles touch",
    touchResult.handled
)

test:expectTrue(
    "Back button action succeeds",
    touchResult.success
)

expectPage(
    navigation,
    "overview",
    "Back button returns to Overview"
)

--------------------------------------------------
-- Overview panels
--------------------------------------------------

test:section("OVERVIEW PANELS")

navigation:reset("overview")

success, err =
    navigation:registerOverviewPanels(
        nil,
        "back"
    )

test:expectFalse(
    "Nil panels rejected",
    success
)

test:expectType(
    "Nil panels return error",
    err,
    "string"
)

success, err =
    navigation:registerOverviewPanels(
        {
            fusion = {
                x = 1,
                y = 1,
                width = 20,
                height = 10
            },

            fission = {
                x = 22,
                y = 1,
                width = 20,
                height = 10
            },

            induction = {
                x = 43,
                y = 1,
                width = 20,
                height = 10
            },

            sps = {
                x = 1,
                y = 12,
                width = 20,
                height = 10
            },

            ae2 = {
                x = 22,
                y = 12,
                width = 41,
                height = 10
            }
        },
        "back"
    )

test:expectTrue(
    "Overview panels registered",
    success
)

test:expectEqual(
    "Five overview regions created",
    #navigation:getRegions("overview"),
    5
)

touchResult =
    navigation:handleTouch(
        "back",
        5,
        5
    )

test:expectEqual(
    "Fusion panel opens Fusion",
    touchResult.page,
    "fusion"
)

navigation:reset("overview")

navigation:registerOverviewPanels(
    {
        ae2 = {
            x = 1,
            y = 1,
            width = 30,
            height = 10
        }
    },
    "back"
)

touchResult =
    navigation:handleTouch(
        "back",
        10,
        5
    )

test:expectEqual(
    "AE2 panel opens AE2 overview",
    touchResult.page,
    "ae2_overview"
)

--------------------------------------------------
-- AE2 tabs
--------------------------------------------------

test:section("AE2 TABS")

navigation:reset("ae2_overview")

local tabs =
    navigation:registerAE2Tabs(
        1,
        3,
        100,
        {
            page = "ae2_overview",
            monitorName = "back",
            height = 2,
            gap = 1
        }
    )

test:expectType(
    "AE2 tabs returned",
    tabs,
    "table"
)

test:expectEqual(
    "Five AE2 tabs registered",
    #tabs,
    5
)

test:expectEqual(
    "Five AE2 page regions exist",
    #navigation:getRegions(
        "ae2_overview"
    ),
    5
)

local selectedCount = 0

for _, tab in ipairs(tabs) do
    test:expectType(
        "AE2 tab data",
        tab.data,
        "table"
    )

    test:expectType(
        "AE2 tab label",
        tab.data.label,
        "string"
    )

    test:expectTrue(
        "AE2 tab target valid",
        Navigation.isAE2Page(
            tab.targetPage
        )
    )

    if tab.data.selected then
        selectedCount =
            selectedCount + 1
    end
end

test:expectEqual(
    "Exactly one AE2 tab selected",
    selectedCount,
    1
)

local itemTab =
    navigation:getRegion(
        "ae2_tab_items"
    )

test:expectType(
    "Items tab exists",
    itemTab,
    "table"
)

touchResult =
    navigation:handleTouch(
        "back",
        itemTab.x,
        itemTab.y
    )

test:expectTrue(
    "Items tab touch handled",
    touchResult.handled
)

expectPage(
    navigation,
    "ae2_items",
    "Items tab opens item page"
)

test:expectEqual(
    "Last AE2 page follows selected tab",
    navigation:getLastAE2Page(),
    "ae2_items"
)

--------------------------------------------------
-- AE2 tab width coverage
--------------------------------------------------

test:section("AE2 TAB GEOMETRY")

navigation:reset("ae2_drives")

tabs =
    navigation:registerAE2Tabs(
        5,
        4,
        53,
        {
            page = "ae2_drives",
            gap = 1,
            height = 1
        }
    )

local totalTabWidth = 0

for _, tab in ipairs(tabs) do
    totalTabWidth =
        totalTabWidth + tab.width
end

local totalWithGaps =
    totalTabWidth
    + (#tabs - 1)

test:expectEqual(
    "Tabs use complete requested width",
    totalWithGaps,
    53
)

test:expectEqual(
    "First tab starts at requested X",
    tabs[1].x,
    5
)

local lastTab = tabs[#tabs]

test:expectEqual(
    "Last tab ends at requested boundary",
    lastTab.x + lastTab.width - 1,
    5 + 53 - 1
)

--------------------------------------------------
-- History limit
--------------------------------------------------

test:section("HISTORY LIMIT")

local limitedNavigation =
    Navigation.new({
        historyLimit = 3
    })

limitedNavigation:goTo("fusion")
limitedNavigation:goTo("fission")
limitedNavigation:goTo("sps")
limitedNavigation:goTo("induction")

debugState =
    limitedNavigation:getDebugState()

test:expectTrue(
    "History respects configured limit",
    #debugState.history <= 3
)

test:expectEqual(
    "Latest page retained in history",
    debugState.history[
        #debugState.history
    ],
    "induction"
)

--------------------------------------------------
-- Debug state
--------------------------------------------------

test:section("DEBUG STATE")

navigation:reset("overview")

navigation:registerPageLink(
    "debug_one",
    1,
    1,
    5,
    5,
    "fusion"
)

navigation:registerPageLink(
    "debug_two",
    7,
    1,
    5,
    5,
    "fission"
)

debugState =
    navigation:getDebugState()

test:expectType(
    "Debug state structure",
    debugState,
    "table"
)

test:expectEqual(
    "Debug current page",
    debugState.currentPage,
    "overview"
)

test:expectEqual(
    "Debug region count",
    debugState.regionCount,
    2
)

test:expectType(
    "Debug history",
    debugState.history,
    "table"
)

test:expectEqual(
    "Raw region count helper",
    countTableEntries(
        navigation.regions
    ),
    debugState.regionCount
)

--------------------------------------------------
-- Summary
--------------------------------------------------

test:summary("NAVIGATION MODULE: READY")